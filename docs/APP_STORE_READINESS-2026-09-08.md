# App Store readiness — verified against `main` (2026-09-08)

The repo had a checklist from July 6 (`docs/archive/TODO-2026-07-06.md`) marking a bunch of
compliance items "fixed." This doc re-checked each claim against the actual code as of today
rather than taking it at face value. Some items really are done; a few are worse than the old
doc says; a couple are new discoveries.

## 🚨 Blockers — must fix before submitting

1. ~~Legal documents are still marked as unreviewed placeholders~~ **Fixed 2026-09-08.**
   `Breath - Relax & Stretch/Legal/PrivacyPolicy.html` and `TermsOfUse.html` had the placeholder
   comment removed, the date set to September 8, 2026, and the contact address set to
   `dialdownn@gmail.com`. The privacy stance itself was already accurate before this pass:
   local-first by default (SwiftData, nothing leaves the device unless you sign in), and the
   optional Supabase sync only uploads a display name + points/streak/minutes keyed to an
   anonymous UUID — confirmed by the code comments in `SupabaseService.swift` and
   `PrivacyInfo.xcprivacy` ("no email; id is the anonymous per-install UUID... not used for
   tracking"). `NSPrivacyTracking` is `false` and no tracking domains are declared.
   **Still outstanding:** a human (ideally with legal review) should still read both documents
   end-to-end and confirm the text matches actual behavior at ship time — that hasn't happened,
   only the mechanical de-placeholdering has.

2. **Two placeholder App Group IDs still shipping**, confirmed still literally
   `"group.REPLACE_WITH_YOUR_BUNDLE_ID"` in:
   - `Breath - Relax & Stretch/Services/WidgetDataService.swift:15`
   - `BreathWidget/BreathWidget.swift`
   - `BreathWatchComplication/BreathWatchComplication.swift`

   Inert until the real Widget/Watch targets are created in Xcode with a shared App Group.
   Not a rejection risk if those targets don't ship yet, but non-functional until resolved.

3. **StoreKit Configuration scheme step** — `Configuration.storekit` has real prices
   ($1.99/$4.99/$9.99) but `StoreManager.loadProducts()` returns empty unless the scheme's
   Run → Options → StoreKit Configuration points at it locally, **and** the equivalent real
   in-app-purchase products must exist in App Store Connect for TestFlight/production (the
   local `.storekit` file is sandbox-only).

4. ~~Body-map anatomy assets carry a CC BY-SA 4.0 obligation that isn't visible to users yet.~~
   **Fixed 2026-09-08.** `ASSET_CREDITS.md` (already in the repo) correctly documents that the 3D
   body-map model — derived from Z-Anatomy / BodyParts3D — and every exercise animation rendered
   from it are derivative works requiring attribution, a link to the license, a statement of
   changes made, and share-alike licensing of those specific assets. Two things worth staying
   precise about:
   - **This does *not* mean the app's source code has to be relicensed under CC BY-SA.**
     `ASSET_CREDITS.md` §"On open-sourcing the application" already makes this distinction:
     ShareAlike binds *adaptations of the licensed work itself* (the meshes, JSON metadata, and
     `.mp4` renders) — it has no GPL-style "linking" clause that would reach code merely bundling
     those assets. This project happens to be open source anyway, which independently satisfies
     the license and the Z-Anatomy maintainers' stated wish, but that's a separate, voluntary
     choice from what the license actually requires.
   - **What the license does require was a user-visible attribution, which was missing.** Added
     a `Settings → About → Credits` entry (`ProfileSettingsTab.swift`) that presents a new
     `Breath - Relax & Stretch/Legal/Credits.html` via the existing `LegalDocumentView`/
     `LegalWebView` sheet infrastructure (the same one used for Terms/Privacy). It reproduces the
     Z-Anatomy / BodyParts3D credit, authors table, CC BY-SA 4.0 license link, and "changes made"
     statement from `ASSET_CREDITS.md` §1, plus the Manrope/SIL OFL credit.

## ⚠️ High-priority, ship-quality risk (not auto-rejected, but will hurt reviews/ratings)

5. **Localization is only ~28% complete** (109/390 strings translated for es/fr/zh-Hans,
   counted directly from `Localizable.xcstrings`) — worse than the 36% the old TODO cited.
   Users with those locales set will see a mixed-language UI. Either finish translation
   coverage + get a native-speaker review, or remove those languages from the declared
   regions until ready.

6. **Migration still matches exercises by name, just hashed.**
   `Exercise.stableSeedUUID(forName:)` (`Exercise.swift:211`) derives a UUID as
   `SHA256("breathapp.seed-exercise:\(name)")` — it *looks* like a stable UUID scheme but is
   still 100% name-keyed. Renaming a seed exercise in `SeedData.json` still silently breaks
   migration/progress-tracking for that exercise.

7. **Bundle size regression on the 3D model.** The old TODO said "~7 MB of OBJs, convert to
   `.scn`/`.usdz`." Today there's a single `BodySkinMuscle.obj` at **12 MB** (up from 7 MB,
   now merged into one file) with **no `.scn`/`.usdz` conversion done anywhere in the repo.
   Bigger bundle-size and cold-load-time problem than before, not smaller.

8. **"Female" body-type picker still says "coming soon"** in both `ProfileSettingsTab.swift`
   and `GenderPickerPage.swift` — confirmed intentionally deferred (needs a Blender export
   from Jason), not a bug, but still user-facing unfinished functionality worth a ship/hide
   decision before launch.

## ✅ Confirmed done since the old TODO (no action needed)

- `PrivacyInfo.xcprivacy` exists in the main app target with correct reason codes.
- Paywall StoreKit-price display, restore-purchase failure handling, and Terms/Privacy links
  are wired correctly.
- Google Sign-In client ID is real (not a placeholder) — `GoogleAuthService.swift:23` has an
  actual `apps.googleusercontent.com` ID.
- Demo videos are now largely wired: 355/372 exercises have `animationName` set (previous
  note had this at 14/207 — big progress).
- HealthKit, Calendar (EventKit), and Face ID usage-description strings are all present and
  specific (not boilerplate) in the build settings' `INFOPLIST_KEY_*` entries.

## Still-pending manual Xcode/account setup (Jason-only, unverifiable from the repo)

- iCloud/CloudKit capability + container
- Widget Extension target creation
- `breath://` URL scheme registration
- Apple Watch app target + complication target
- Running/re-running `supabase_schema.sql` for the Apple auth provider's tightened RLS
  policies

Capability/entitlement state lives in the Apple Developer account and Supabase dashboard, so
these need a manual pass through Signing & Capabilities before archiving a build.
