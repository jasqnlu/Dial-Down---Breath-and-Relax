# Design: Google + Email accounts become real Supabase Auth users

Date: 2026-09-16 · Owner: Sonnet 5 (interactive session with Jason)
Status: approved, ready for implementation plan

---

## Problem

Only Sign in with Apple creates a real Supabase Auth session today (see
`2026-07-06-supabase-auth-and-flexibility-checkins-design.md`, which explicitly
deferred Google/email as "a product decision Jason hasn't made" — that decision
is now made). Google and email/password sign-in currently only write to
`UserDefaults` via `AuthManager.persist(...)`:

- `handleGoogleSignIn(name:email:)` — no Supabase call at all.
- `signUp(name:email:password:)` / `signIn(email:password:)` — password is
  PBKDF2-hashed and stored in the Keychain locally; no Supabase call.

Because `AuthManager.backendID` falls back to the local anonymous UUID whenever
`kSupabaseUserID` isn't set, and `isBackendAuthenticated` is `false` for both
providers, every RLS-gated write (`uploadProfile`, `registerPushToken`, and any
future routine/session sync) silently no-ops for these users. They are
cosmetic accounts: a name/email in `UserDefaults` with no cloud identity, no
backup, no cross-device continuity.

## Goal

Google and email/password sign-in create real Supabase Auth users, exactly the
way Apple sign-in already does — `auth.uid()` gets populated, `backendID`
becomes the real Supabase user id, and every existing best-effort upload call
starts succeeding without any changes to those call sites. **Auth only**:
building explicit routine/session sync on top of the new identity is
out of scope for this project (existing best-effort profile/push-token upload
calls are the only things that start working automatically).

Explicitly out of scope (decided during brainstorming, revisit later if
needed):
- Full account deletion (removing the underlying `auth.users` row via an
  Edge Function + service role). Deletion stays exactly as shallow as it is
  today for Apple — wipes local data, revokes the session, does not delete
  the `auth.users` row. This means a deleted email account's address stays
  permanently unavailable for a fresh signup. Known and accepted for now.
- Email confirmation flow. "Confirm email" will be disabled in Supabase Auth
  settings so `signUpWithPassword` returns a usable session immediately,
  matching the current instant-signup UX. Revisit once transactional email
  is set up.
- Migrating any existing local email/Google accounts — there are none with
  real user data yet (matches the empty Supabase tables); this is a clean
  cut.
- Merging/linking accounts across providers (e.g. same email via Google and
  password). Not handled; each provider path is independent, same as today.

## Approach

Extend the existing Apple `id_token` grant pattern (`SupabaseService.
signInWithApple`) to Google, and add Supabase's native email/password grant
types for the email path. No new session storage, no new SDK — same
hand-rolled REST calls against Supabase's GoTrue endpoints that
`SupabaseService` already uses, consistent with this codebase's zero-SPM-deps
choice for auth (see `GoogleAuthService`'s hand-rolled PKCE).

Alternatives considered and rejected:
1. **Supabase's native Google provider (hosted OAuth redirect)** — would
   remove `GoogleAuthService`'s custom code, but requires a Web-type OAuth
   client + secret in the Supabase dashboard and changes the sign-in UX to a
   Supabase-hosted redirect. Rejected: more dashboard setup for no benefit,
   and changes a UX the user didn't ask to change.
2. **Keep local password check, layer a separate Supabase account on top**
   — two sources of truth for password correctness. Rejected: fully
   replacing local auth with Supabase is cleaner and lets Supabase's own
   password-strength settings actually apply.

## Components

### `GoogleAuthService.swift`

- Generate a raw nonce + SHA-256 hash, same shape as `AuthManager
  .randomNonce()` (this file already imports `CryptoKit` and has
  `randomURLSafeString`/`codeChallenge` helpers to model it on). Pass the
  hash as a `nonce` query param on the `/o/oauth2/v2/auth` request.
- `TokenResponse` gains an `id_token: String` field (Google returns it
  automatically once `openid` scope is present — already in the requested
  scope list, no Google Cloud config change needed).
- `signIn(presentationAnchor:)` returns a new struct carrying `idToken:
  String`, `rawNonce: String`, and the existing `GoogleUser` (email/name),
  instead of just `GoogleUser`.

### `SupabaseService.swift`

- Refactor `signInWithApple(identityToken:nonce:)` into a shared private
  `signInWithIdToken(provider: String, idToken: String, nonce: String?)
  async throws -> String`; `signInWithApple` and new `signInWithGoogle`
  become thin wrappers passing `provider: "apple"` / `"google"`.
- Add `signUpWithPassword(email: String, password: String, name: String)
  async throws -> String` — `POST /auth/v1/signup`, with `name` passed as
  `data: { "name": name }` in the body (lands in `raw_user_meta_data`, for
  display purposes only — per the security checklist, `user_metadata` is
  never used for authorization decisions anywhere in this app).
- Add `signInWithPassword(email: String, password: String) async throws ->
  String` — `POST /auth/v1/token?grant_type=password`.
- Both decode the same `TokenGrant` shape `tokenRequest` already produces,
  store the session via the existing `storeSession`, and return the
  Supabase user id.
- Add error mapping from Supabase's JSON error bodies (`error_code` field:
  `user_already_exists`, `invalid_credentials`, `weak_password`, etc.) to
  a `SupabaseAuthError` with readable `errorDescription`, so `AuthManager`
  can surface them through the existing `String?` error-message convention.
- **New seam for testability**: `SupabaseService` currently calls
  `URLSession.shared` directly in `tokenRequest`/`post`/`get`/`delete`/
  `signOut` — there is no injection point today. Add a `urlSession:
  URLSessionProtocol` (a minimal protocol wrapping `data(for:)`) as an
  `init` parameter, mirroring the `KeychainStore` seam already used for the
  keychain, so tests can stub HTTP responses instead of hitting the network.

### `AuthManager.swift`

- `handleGoogleSignIn` becomes `async`, taking `idToken`, `nonce`, `name`,
  `email`. Calls `SupabaseService.shared.signInWithGoogle(idToken:nonce:)`,
  sets `kSupabaseUserID` + fires `objectWillChange.send()`, then `persist
  (name:email:providerVal: .google)` — mirroring `handleAppleCredential`.
- `signUp(name:email:password:)` and `signIn(email:password:)` become
  `async throws -> String?`, wrapping `SupabaseService.shared
  .signUpWithPassword` / `.signInWithPassword`. Client-side validation
  (name non-empty, email contains "@", password length) stays as an
  up-front fast fail before the network call, same as today.
- Delete: `hashPassword`, `generateSalt`, `PasswordHasher` typealias, the
  `hasher` parameter on `init`, and all local Keychain credential
  read/writes (`keychain.save(account: email, ...)` /
  `keychain.loadCredential(account: email)` for passwords). `AuthManager
  .pbkdf2` and its call sites go away.
- `deleteAccount()` — unchanged. The `provider == .email` branch that
  deletes the local Keychain credential becomes dead (nothing writes there
  anymore) and gets removed as part of the same cleanup.

### Call sites

- `Views/Auth/AuthView.swift:213-216` (`signInWithGoogle()`) — already
  `async`; update to destructure the new richer return from `GoogleAuthService
  .signIn` and call `await auth.handleGoogleSignIn(...)`.
- `Views/Auth/EmailAuthView.swift:142,150` — `auth.signUp(...)` / `auth
  .signIn(...)` calls move from synchronous `if let err = ...` to `if let
  err = await auth.signUp(...)` inside an async context (check whether the
  enclosing function is already async; make it so if not).

## Data flow (Google case, as the representative new path)

`AuthView.signInWithGoogle()` → `GoogleAuthService.signIn(presentationAnchor:)`
(PKCE flow against Google, now also carrying a nonce) → returns `(idToken,
rawNonce, GoogleUser)` → `AuthManager.handleGoogleSignIn(idToken:nonce:name:
email:)` → `SupabaseService.shared.signInWithGoogle(idToken:nonce:)` → GoTrue
verifies the id_token's signature, audience (against the Client IDs
configured in the Supabase dashboard), and nonce → returns a `TokenGrant` →
`AuthManager` stores `kSupabaseUserID`, persists display name/email to
`UserDefaults` exactly as it does today. From this point,
`AuthManager.isBackendAuthenticated` is `true` and the existing best-effort
`uploadProfile`/`registerPushToken` calls succeed against RLS without any
changes at those call sites.

Email/password follows the same shape, minus the OAuth round-trip: `EmailAuthView`
→ `AuthManager.signUp`/`signIn` → `SupabaseService.signUpWithPassword`/
`signInWithPassword` → `TokenGrant` → same `kSupabaseUserID`/`persist` steps.

## Error handling

- Both new `AuthManager` methods keep the existing `String?` error-message
  convention (`nil` = success) so `EmailAuthView`/`AuthView` don't need new
  error-shape plumbing, only `await` at the call site.
- Google's own OAuth failures continue through the existing `GoogleAuthError`
  enum (`cancelled`, `invalidResponse`, `notConfigured`) — unaffected by this
  change, still caught the same way in `AuthView.signInWithGoogle()`.
- New `SupabaseAuthError` (or reuse of a generic error path) maps GoTrue's
  JSON error bodies to readable strings: "An account with that email already
  exists." for `user_already_exists`, "Incorrect email or password." for
  `invalid_credentials`, and a generic "Something went wrong, please try
  again." fallback for anything unmapped, plus surfacing network failures as
  the existing pattern already does elsewhere in the app.

## Testing

- Add a minimal `URLSessionProtocol` seam to `SupabaseService` (see above)
  and a fake implementation returning canned `(Data, URLResponse)` pairs, so
  `signUpWithPassword`/`signInWithPassword`/`signInWithGoogle` can be tested
  without real network calls — same spirit as the existing `FakeKeychainStore`.
- Extend `AuthManagerTests.swift`'s `makeManager()` to inject the fake
  Supabase networking, and rewrite the existing `signUpSucceedsAndPersistsIdentity`-style
  tests (currently synchronous, asserting on local PBKDF2 storage) as `async`
  tests asserting on `backendID`/`isBackendAuthenticated` after a stubbed
  successful token grant, plus new tests for the failure-mapping paths
  (`user_already_exists`, `invalid_credentials`, network failure).
- Delete tests that exercise the removed PBKDF2/salt code directly.
- `GoogleAuthServiceTests` (if none exist yet, check during implementation)
  should cover nonce generation/hashing and the `TokenResponse` decode
  including the new `id_token` field.

## Dashboard / Google Cloud configuration (manual, done once)

Not part of the code change, but required for it to work — will be walked
through step-by-step during implementation:

1. Google Cloud Console → Credentials → create a second OAuth client,
   type **Web application** (existing iOS client stays as-is, unused by
   Supabase but still used by `GoogleAuthService` for the PKCE flow itself).
   Its secret is never used by this app; it exists purely so Supabase has a
   Web-flavored Client ID to allowlist.
2. Supabase Dashboard → Authentication → Providers → Google: enable the
   provider, enter both Client IDs comma-separated with the **Web** one
   first, per Supabase's documented requirement. Enable "Skip nonce check"
   is NOT used (we implement the nonce properly) — leave that off.
3. Supabase Dashboard → Authentication → Providers → Email: enable the
   provider, disable "Confirm email".
