# Manual setup walkthrough — everything left before shipping

Companion to [`APP_STORE_READINESS-2026-09-08.md`](APP_STORE_READINESS-2026-09-08.md). That doc
tracks *what's* outstanding; this one is the step-by-step for the items that need a human
clicking through Xcode/App Store Connect/Supabase — none of it is code Claude can do from the
repo.

## 1. Legal review (you or a lawyer — no tools needed)

Open `Breath - Relax & Stretch/Legal/PrivacyPolicy.html` and `TermsOfUse.html` and read them
end-to-end against what the app actually does today. Nothing more than that — the placeholder
text is already gone, this is just a correctness check before it's live.

## 2. Native-speaker review of es/fr/zh-Hans (you, or someone who speaks them)

Open `Breath - Relax & Stretch/Resources/Localizable.xcstrings` in Xcode (it has a dedicated
string-catalog editor — click the file, then filter by language in the left sidebar). Spot-check
especially: the medical disclaimer text, body-map copy, and anything with `%@`/`%lld`
placeholders (confirm the sentence still reads naturally with a number or name substituted in).

## 3. Supabase — run the schema + enable Apple provider

This one's fully self-documented in the repo:

1. Open `supabase_schema.sql` at the repo root and read the header comment — it explains the
   identity model (anonymous UUIDs, no emails) and what changed.
2. Supabase Dashboard → **SQL Editor** → New query → paste the whole file → **Run**.
3. Supabase Dashboard → **Authentication → Providers** → enable **Apple**, with the app's bundle
   ID (`com.jasonlu.Breath--Relax---Stretch`) as the client ID. Skipping this makes every
   Sign-in-with-Apple token exchange fail with a 4xx — the app just silently stays in
   local/guest mode, so you won't get a crash, just no cross-device sync for Apple sign-ins.
4. If this project ran an older version of the schema, the file's `drop policy if exists` lines
   handle migrating it — safe to re-run.

## 4. `breath://` URL scheme registration (Xcode)

The code that *handles* these links (`DeepLinkRouter.swift`) is already written — the OS just
doesn't know to route them to your app yet.

1. Xcode → select the **BreathRelaxStretch** target → **Info** tab.
2. Scroll to **URL Types** → click **+**.
3. **Identifier**: `com.jasonlu.Breath--Relax---Stretch` (or anything, it's just a label).
   **URL Schemes**: `breath`. **Role**: Editor.
4. Build and run once — Xcode registers it with the simulator/device automatically. Test by
   running `xcrun simctl openurl booted "breath://quick-session"` in Terminal while the app is
   running.

## 5. Widget Extension target + App Group

1. Xcode → **File → New → Target…** → **Widget Extension**. Name it `BreathWidget` (there's
   already a `BreathWidget/BreathWidget.swift` file in the repo waiting for this target to
   exist — when Xcode asks, point the target's source at that existing folder rather than
   letting it generate new files, or just add the existing file to the new target's membership
   afterward).
2. Pick an App Group ID — convention is `group.` + your bundle ID, e.g.
   `group.com.jasonlu.Breath--Relax---Stretch`.
3. On **both** targets — main app (`BreathRelaxStretch`) and the new widget extension — go to
   **Signing & Capabilities → + Capability → App Groups**, add that same group ID, check it on
   in both.
4. Replace the placeholder in all three places (once you've picked the real ID, ask Claude and
   it can do this part — it's a one-line find/replace):
   - `Breath - Relax & Stretch/Services/WidgetDataService.swift:15`
   - `BreathWidget/BreathWidget.swift`
   - `BreathWatchComplication/BreathWatchComplication.swift`

## 6. Apple Watch app target + complication

1. Xcode → **File → New → Target…** → **Watch App** (or **Watch Complication** if you only want
   the complication, not a full watch app — `BreathWatchComplication/BreathWatchComplication.swift`
   already exists for this).
2. Same App Group ID as step 5, added to this target's Signing & Capabilities too — the watch
   complication reads the same shared UserDefaults.
3. Point the target at the existing `BreathWatchComplication` folder the same way as the widget.

## Not needed

- ~~iCloud/CloudKit capability + container~~ — superseded by the 2026-07-10 decision to use
  Supabase for sync instead of CloudKit (see `TODO.md`). `ModelConfiguration` is already
  `cloudKitDatabase: .none`. No action here — this was a stale item in an earlier version of the
  readiness doc, corrected 2026-09-09.

## What's already done (code-side)

Everything on the readiness doc's blocker/quality list that was a code fix is done: legal-doc
placeholders, the tip jar removal, the gender/body-type picker removal, 100% es/fr/zh-Hans
string coverage, and the name-derived `Exercise.uuid` migration bug. The items above are what's
left, and all of it needs a human at a keyboard clicking through account/IDE settings rather
than a code change.
