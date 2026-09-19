// supabase/functions/send-streak-warnings/index.ts
//
// Cron-triggered only (see supabase_schema.sql's cron.schedule call) — not
// reachable from the client, enforced two ways: deployed with
// verify_jwt = true (supabase/config.toml), and every request must carry the
// x-cron-secret shared secret checked below. Every 15 minutes: ask Postgres which
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

async function buildAPNsJWT(privateKey: CryptoKey, iat: number): Promise<string> {
  const header = { alg: "ES256", kid: APNS_KEY_ID };
  const payload = { iss: APNS_TEAM_ID, iat };
  const signingInput = `${base64url(new TextEncoder().encode(JSON.stringify(header)))}.` +
    `${base64url(new TextEncoder().encode(JSON.stringify(payload)))}`;
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    privateKey,
    new TextEncoder().encode(signingInput),
  );
  return `${signingInput}.${base64url(signature)}`;
}

// Apple requires a provider token to be at least 20 minutes old before it's
// refreshed and rejects tokens older than 1 hour (`ExpiredProviderToken`), and
// returns `TooManyProviderTokenUpdates` if you re-sign too often. This function
// runs every 15 minutes, so signing per invocation sits right in that penalty
// window. Edge Function isolates stay warm across invocations, so cache both
// the imported key and the signed token at module scope and re-sign only once
// the token is ~50 minutes old.
const JWT_MAX_AGE_SECONDS = 50 * 60;
let cachedKey: CryptoKey | null = null;
let cachedJWT: { token: string; iat: number } | null = null;

async function getAPNsJWT(pem: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedJWT && now - cachedJWT.iat < JWT_MAX_AGE_SECONDS) return cachedJWT.token;
  if (!cachedKey) cachedKey = await importAPNsPrivateKey(pem);
  const token = await buildAPNsJWT(cachedKey, now);
  cachedJWT = { token, iat: now };
  return token;
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

// Constant-time string compare, so a caller can't narrow the secret down one
// byte at a time from response timings.
function secretsMatch(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

Deno.serve(async (req) => {
  // Belt and braces. The function is also deployed with verify_jwt = true (see
  // supabase/config.toml), so a caller must already present a valid project
  // JWT — but any signed-in user of this app holds one of those, and this
  // endpoint is meant to be reachable by the pg_cron job and nothing else.
  // The cron job sends this header from a vault secret; see the
  // "streak-warning cron (revised ...)" block in supabase_schema.sql.
  const cronSecret = Deno.env.get("CRON_SHARED_SECRET");
  if (!cronSecret) {
    // Fail closed: an unset secret must never degrade into "allow everyone".
    console.error("CRON_SHARED_SECRET not configured — refusing all callers");
    return new Response("CRON_SHARED_SECRET not configured", { status: 500 });
  }
  if (!secretsMatch(req.headers.get("x-cron-secret") ?? "", cronSecret)) {
    return new Response("unauthorized", { status: 401 });
  }

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

  const jwt = await getAPNsJWT(apnsKeyPEM);

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
