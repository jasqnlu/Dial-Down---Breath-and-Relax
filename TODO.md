# Breath: Relax & Stretch — TODO

Generated from BUILD_GUIDE.md · Updated 2026-06-08

---

## ✅ Completed (v0.1)

- [x] Core SwiftData models (Exercise, Routine, Session, UserProfile, BodyPart)
- [x] Body map with human silhouette + region tap → exercise filter
- [x] Drawing annotation overlay (pen / highlighter / eraser / sensation colours)
- [x] Exercise list with search + type filter
- [x] Routine builder (create, reorder, delete)
- [x] Borrow public routines (fork + own)
- [x] Session player (timer, progress, points)
- [x] Session summary screen
- [x] Gamification — points, streak, badges
- [x] Supabase REST backend (exercises, routines, sessions)
- [x] Sign in with Apple + email/password auth
- [x] Two-Factor Authentication toggle
- [x] Sign Out
- [x] Dark mode polish (no hardcoded colours)
- [x] VoiceOver accessibility labels
- [x] Haptic feedback (session transitions + auth)
- [x] Ambient sound + completion chime
- [x] Profile view with stats + badges

---

## ✅ Completed (v0.2)

- [x] **Onboarding flow** — 4-page (Welcome → Goal Picker → Body Map intro → Notification permission); shown once via @AppStorage gate
- [x] **Push notifications** — UNUserNotificationCenter daily reminder; wired to Settings toggle + time/days steppers in Profile
- [x] **Breathing exercises** — standalone Breathe tab; 4 patterns (Box, 4-7-8, Belly, Energising); animated circle, phase labels, saves stats
- [x] **Progress charts** — Swift Charts bar chart (weekly minutes), streak calendar, cumulative points line chart
- [x] **Custom exercise creation** — form with name/type/duration/difficulty/body parts/instructions; saves to SwiftData
- [x] **Notification delivery** — fully wired: requestPermission on first enable, reschedule on time/days change
- [x] **Data export** — Export My Data → generates CSV or JSON of all sessions → ShareLink to save/share
- [x] **Exercise video/GIF preview** — AVKit VideoPlayer shown in ExerciseDetailView when `mediaURL` is set
- [x] **Profile photo** — PhotosPicker → downscale to 512×512 → saved to Documents; shown in profile header avatar
- [x] **Seed data expansion** — 35 exercises total (was 10); covers all body regions

---

## 🔴 High Priority

- [ ] **Fix app icon** — placeholder needs a real design (export @1x/@2x/@3x)
- [ ] **App Store screenshots** — 6.9" + 6.1" sizes, at least 3 screens

---

## 🟡 Medium Priority

- [ ] **iCloud backup** — add `NSUbiquitousKeyValueStore` or CloudKit container so data survives device switches
- [ ] **Routine sharing** — deep-link URL or share sheet to send a routine to a friend

---

## 🟢 Nice to Have

- [ ] **Apple Watch app** — glanceable session timer, heart-rate context for intensity
- [ ] **Widget** — Today summary widget: streak, next scheduled session
- [ ] **Calendar integration** — EventKit: show completed sessions on Calendar; suggest session based on free slots
- [ ] **Body layer switching** — Skin → Muscle → Skeleton toggle on the body map (architecture is ready in BodyPart model, UI not built)
- [ ] **Skeleton/muscle overlay** — actual SVG paths per muscle group instead of the current polygon regions
- [ ] **Sleep tracking** — HealthKit: read last night's sleep score, suggest morning stretch if sleep < 7 h
- [ ] **Social / community** — leaderboard, challenge a friend, public profile
- [ ] **Subscription / IAP** — StoreKit 2: free tier (5 routines), Pro tier (unlimited + export + Watch app)
- [ ] **Localization** — at minimum: EN + ES + FR + ZH
- [ ] **Mac Catalyst / visionOS** — after iPhone is solid

---

## 🐛 Known Bugs / Tech Debt

- [x] Body map annotation eraser — fixed: `blendMode(.destinationOut)` inside isolated `drawLayer`
- [x] `SessionPlayerView` timer leak — fixed: `sessionActive` flag set in `.onDisappear`
- [ ] `BorrowRoutineView` uses placeholder Supabase URL — real fetch will fail until `.env` is configured
- [ ] `AuthManager.signUp` hashes password with SHA-256 (fast hash) — should use PBKDF2/Argon2 via `CryptoKit` for production
- [ ] No unit tests — add XCTest for `GamificationService`, `AuthManager`, `AnnotationStore`

---

## 🗓 Suggested Sprint Order

| Sprint | Focus |
|--------|-------|
| 1 | Onboarding + push notifications ✅ |
| 2 | Breathing exercise module ✅ |
| 3 | Progress charts (Swift Charts) ✅ |
| 4 | Custom exercise creation ✅ |
| 5 | Data export + profile photo ✅ |
| 6 | Apple Watch app |
| 7 | App Store prep (icon, screenshots, TestFlight) |
