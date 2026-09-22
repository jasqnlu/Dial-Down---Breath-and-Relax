# Next steps — as of 2026-09-21

Companion to [`APP_STORE_READINESS-2026-09-08.md`](APP_STORE_READINESS-2026-09-08.md) and
[`MANUAL_SETUP_WALKTHROUGH-2026-09-10.md`](MANUAL_SETUP_WALKTHROUGH-2026-09-10.md). Those are
mostly done now; this is what's left after today's session (repo went public, the data-loss bug
got fixed, branches got cleaned up).

## 🚨 Do first: confirm the data-loss fix actually worked for real users

Today's session found and fixed a bug where **no user's data had ever saved**, on any sign-in
method — the live database had RLS policies but no table grants, so every request 403'd before
any policy ran. The grants migration is applied and verified (confirmed via direct query: a
profile row appeared after a fresh sign-in). But:

- [ ] Have a friend or second device sign in and confirm their `profiles` row appears too — one
      successful sign-in (yours) isn't enough to call this solid.
- [ ] Know that **routines and sessions still don't sync at all** — that's a separate, larger
      piece of work (`TODO.md` §3, "Restore write paths" + "Sync engine"), not something today's
      fix touched. Local routines are still local-only.

## 📸 App Store Connect

- [ ] **Privacy Policy URL** — done, use this:
      `https://jasqnlu.github.io/Dial-Down---Breath-and-Relax/privacy.html`
- [ ] **Retake screenshots** — the ones in `AppStoreScreenshots/` are from June 30, before the
      Lumina restyle. Both simulators are already set up:
      - 6.9" → iPhone 17 Pro Max (1320×2868)
      - 6.3" → iPhone 17 (1206×2622)
      Shot list, in priority order (App Store shows the first 2–3 before anyone scrolls):
      1. Body map with a muscle region highlighted (not the plain skin view)
      2. Exercise detail with the demo animation mid-play — you don't have this one yet
      3. Exercise graph (node view)
      4. Session player mid-session
      5. Breathing screen, pattern mid-animation
      6. Today tab (daily session hero card)
      7. Profile/streak (seed some fake points/streak data first — don't ship a 0/0/0 screenshot)
      Light mode, full battery, no notification banners. Same 7-shot set on both device sizes.
- [ ] **Listing itself** — description, keywords, age rating, support URL. Not started.
- [ ] **App Privacy nutrition labels** — must match `PrivacyInfo.xcprivacy`: no tracking, only a
      display name + stats keyed to an anonymous UUID.
- [ ] **Archive + TestFlight** — a Release build, a real-device pass, before submitting.

## 🌍 Localization

- [ ] **Native-speaker review** of es/fr/zh-Hans — the text is complete (100% coverage, fixed
      this session) but still machine-translated. Especially check the medical disclaimer and
      body-map copy.

## 🧹 Repo housekeeping (minor, your call)

- [ ] **Two old local branches still undecided**: `feature/bodymap-3d-marking` and
      `worktree-bodymap-3d-anatomy` — abandoned prototypes of the pre-Lumina 3-layer body map,
      both closed (never merged) PRs from July. Delete them, or keep for reference — up to you.
- [ ] **Mismatched signing team ID** — `BreathRelaxStretch`'s main target signs with team
      `F4NF2ZRZS9`, but the Tests/UITests targets are on a different team (`7ZT4KUSC4W`). Not a
      security issue since you're the sole developer, but worth fixing in Signing & Capabilities
      if it ever causes a confusing prompt.

## ✅ Done this session (for reference, not action items)

- Repo is public: `https://github.com/jasqnlu/Dial-Down---Breath-and-Relax`
- Git history rewrite: stripped 13GB of regenerable Blender render scratch that was accidentally
  tracked; verified byte-identical `Resources/Animations` before/after
- All confirmed-merged/empty branches deleted, on GitHub and locally (34 total) — only `main`
  remains on GitHub
- Full secrets/PII sweep — clean
- `README.md` added, with a License section splitting MPL-2.0 (code) from CC BY-SA 4.0 (anatomy
  assets), plus 4 screenshots (still the old pre-restyle set — see screenshots section above)
- es/fr/zh-Hans string catalog completed (6 missing keys filled), streak-count pluralization bug
  fixed ("1 days" → "1 day")
- `feature/private-profiles-opt-in-leaderboard` merged into `main`: profiles are now private
  (owner-only), leaderboard is opt-in and pseudonymous (generated handles, never real names) —
  this merge is what carried the data-loss grants fix
- Privacy policy, terms, and credits hosted on GitHub Pages (`gh-pages` branch, isolated from the
  rest of the repo's docs)
