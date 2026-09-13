// supabase/functions/send-streak-warnings/index.ts
//
// Cron-triggered only (see supabase_schema.sql's cron.schedule call) —
// never reachable from the client. Every 15 minutes: ask Postgres which
// (user, device) pairs are due a streak-about-to-break push right now in
// their own local time (get_streak_warning_candidates does the IANA-
// timezone math), sign one APNs JWT, and POST an alert to each.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const APNS_KEY_ID = "N7992N49CB";
const APNS_TEAM_ID = "F4NF2ZRZS9";

interface Candidate {
  user_id: string;
  device_token: string;
  timezone: string;
}

// ── APNs auth JWT (ES256) ────────────────────────────────────────────────
// Built with the Web Crypto API rather than a JWT library — Deno's
// crypto.subtle already speaks ECDSA/P-256, and WebCrypto's ECDSA signature
// output (raw r||s, 64 bytes for P-256) is exactly the format a JOSE ES256
// signature needs, so no DER-to-JOSE conversion step is required.
function base64url(bytes: ArrayBuffer | Uint8Array): string {
  const buf = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  let str = "";
  for (const b of buf) str += String.fromCharCode(b);
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function importAPNsPrivateKey(pem: string): Promise<CryptoKey> {
  const stripped = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(stripped), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
}

async function buildAPNsJWT(privateKey: CryptoKey): Promise<string> {
  const header = { alg: "ES256", kid: APNS_KEY_ID };
  const payload = { iss: APNS_TEAM_ID, iat: Math.floor(Date.now() / 1000) };
  const signingInput = `${base64url(new TextEncoder().encode(JSON.stringify(header)))}.` +
    `${base64url(new TextEncoder().encode(JSON.stringify(payload)))}`;
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    privateKey,
    new TextEncoder().encode(signingInput),
  );
  return `${signingInput}.${base64url(signature)}`;
}

// ── APNs delivery ────────────────────────────────────────────────────────

type SendResult = "sent" | "stale" | "failed";

async function sendOnePush(
  candidate: Candidate,
  jwt: string,
): Promise<SendResult> {
  const payload = JSON.stringify({
    aps: {
      alert: {
        title: "Don't lose your streak!",
        body: "You haven't practiced today — a quick session keeps your streak alive.",
      },
      sound: "default",
    },
  });

  const post = (host: string) =>
    fetch(`https://${host}/3/device/${candidate.device_token}`, {
      method: "POST",
      headers: {
        "authorization": `bearer ${jwt}`,
        "apns-topic": "com.jasonlu.Dial--Down--Breath--Stretch", // must match PRODUCT_BUNDLE_IDENTIFIER
        "apns-priority": "10",
        "apns-push-type": "alert",
      },
      body: payload,
    });

  // Production first — see the spec's "Environment note": this app has no
  // stored record yet of which APNs environment a given token belongs to.
  let response = await post("api.push.apple.com");
  if (response.status === 400) {
    const body = await response.json().catch(() => ({}));
    if (body.reason === "BadDeviceToken") {
      response = await post("api.sandbox.push.apple.com");
    }
  }

  if (response.status === 200) return "sent";
  if (response.status === 410) return "stale"; // Unregistered — delete, don't retry
  return "failed";
}

// ── Entry point ──────────────────────────────────────────────────────────

Deno.serve(async (_req) => {
  const apnsKeyPEM = Deno.env.get("APNS_AUTH_KEY_P8");
  if (!apnsKeyPEM) {
    return new Response("APNS_AUTH_KEY_P8 not configured", { status: 500 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: candidates, error } = await supabase.rpc(
    "get_streak_warning_candidates",
  );
  if (error) {
    console.error("get_streak_warning_candidates failed:", error);
    return new Response("query failed", { status: 500 });
  }
  if (!candidates || candidates.length === 0) {
    return new Response("no candidates", { status: 200 });
  }

  const privateKey = await importAPNsPrivateKey(apnsKeyPEM);
  const jwt = await buildAPNsJWT(privateKey);

  let sent = 0, stale = 0, failed = 0;
  for (const candidate of candidates as Candidate[]) {
    // One user's failure never blocks the batch — matches the spec's error
    // handling section.
    try {
      const result = await sendOnePush(candidate, jwt);
      if (result === "sent") {
        sent++;
        const localDate = new Date(
          new Date().toLocaleString("en-US", { timeZone: candidate.timezone }),
        ).toISOString().slice(0, 10);
        await supabase
          .from("push_tokens")
          .update({ last_warned_date: localDate })
          .eq("user_id", candidate.user_id);
      } else if (result === "stale") {
        stale++;
        await supabase.from("push_tokens").delete().eq("user_id", candidate.user_id);
      } else {
        failed++;
      }
    } catch (err) {
      failed++;
      console.error(`push failed for ${candidate.user_id}:`, err);
    }
  }

  return new Response(
    JSON.stringify({ candidates: candidates.length, sent, stale, failed }),
    { status: 200, headers: { "content-type": "application/json" } },
  );
});
