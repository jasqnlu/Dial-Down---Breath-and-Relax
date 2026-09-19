# Apple Sign-in server-to-server notifications (deferred)

Status: **nice-to-have, not started.** Not required to ship Sign in with Apple.

## What it is

When registering the App ID's Sign in with Apple capability, Apple's portal offers a
**Server-to-Server Notification Endpoint** — a URL on your own backend that Apple calls
whenever a user:

- changes their mail-forwarding (Hide My Email) preference,
- deletes their account with *your* app specifically, or
- permanently deletes their Apple Account entirely.

The payload is a signed JWT (JWS) that identifies the affected user and the event type.

## Why it's deferred

This repo has no backend of its own to receive it — Supabase is spoken over raw
`URLSession` from the app, and there's no Edge Function or server endpoint anywhere in
the project. Left blank, Sign in with Apple still works completely normally; the app
just never proactively hears about these account-level events. Today, the only way the
app would notice a revoked/deleted Apple Account is indirectly, the next time that user
tries (and fails) to authenticate.

## What implementing it would take

1. **Write a Supabase Edge Function** (Deno) that:
   - Accepts Apple's POST payload.
   - Verifies the JWS signature against Apple's public keys
     (`https://appleid.apple.com/auth/keys`), matching `iss`, `aud` (your bundle ID /
     Services ID), and expiry — never trust the payload unverified.
   - Decodes the inner `events` JWT to get the event type
     (`email-disabled` / `email-enabled` / `consent-revoked` / `account-delete`) and the
     affected user's Apple `sub`.
2. **React to the event** — e.g. on `account-delete` or `consent-revoked`, look up the
   Supabase user by their Apple `sub` (stored at sign-in time) and delete/anonymize
   their rows per the schema's identity model (see `supabase_schema.sql` header comment).
3. **Register the Edge Function's public URL** back in the Apple Developer portal's
   Server-to-Server Notification Endpoint field (must be HTTPS, TLS 1.2+).
4. **Test it** — Apple does not provide a sandbox trigger for these; the practical way
   to verify is to delete a test Apple Account's consent for the app via
   [appleid.apple.com](https://appleid.apple.com) → Sign in with Apps, and confirm the
   webhook fires.

## Related

- [`MANUAL_SETUP_WALKTHROUGH-2026-09-10.md`](MANUAL_SETUP_WALKTHROUGH-2026-09-10.md) §3 —
  the Apple provider setup this was deferred out of.
- `TODO.md` §3 (Supabase full sync) — the write-path/sync-engine work this would slot
  alongside once a backend function exists for other reasons too.
