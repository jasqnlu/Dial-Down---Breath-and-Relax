# Page Title Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** No page title truncates or sits inconsistently; verified with simulator screenshots at the narrowest supported width.

**Architecture:** Screenshot-driven audit, then per-page minimal fixes following one convention: top-level tab roots use `.large` titles; pushed/sheet pages use `.inline`; inline titles must fit beside their toolbar items at iPhone SE width, else the title text is shortened.

**Tech Stack:** SwiftUI navigation modifiers; simulator screenshot workflow from `memory/simulator_verification.md` (xcrun simctl + launch args).

## Global Constraints

- Branch: `fix/page-titles`, cut from the merge result of the other four branches (it audits their pages too — run LAST).
- Never change a title's meaning; shorten wording only ("Export My Data" → "Export Data").
- Every changed page gets a before/after screenshot pair at iPhone SE (3rd gen) width; store in `docs/superpowers/audits/2026-07-04-titles/`.
- Localization: `Localizable.xcstrings` — update changed title strings' keys accordingly (titles are string literals; verify each changed literal's presence in the catalog and rename the key if present).

---

### Task 1: Audit

**Files:**
- Create: `docs/superpowers/audits/2026-07-04-titles/AUDIT.md`

- [ ] **Step 1:** Enumerate every `navigationTitle` (23 known from grep — list in AUDIT.md with file:line).
- [ ] **Step 2:** Boot iPhone SE (3rd gen) simulator; drive to each page using the launch-arg patterns in `memory/simulator_verification.md`; screenshot each title bar. Pages not reachable by launch args get manual navigation notes in AUDIT.md.
- [ ] **Step 3:** Mark each page PASS/FAIL (FAIL = truncation `…`, collision with toolbar item, or convention violation: tab root not `.large` / pushed page not `.inline`). Known suspects to check first: `BreathingView` (.large — the only tab using it; the other four tab roots are .inline → convention decision: make ALL tab roots `.large` OR Breathing `.inline`; pick whichever the majority already is — the four inline roots win, so Breathing goes `.inline` unless screenshots show `.large` reads better across all five, in which case flip all five and note it), `DataExportView` ("Export My Data"), `BodyMapView` mark-mode title ("Mark Your Body"), `GuidedProgramDetailView` (dynamic `program.title` — needs `lineLimit(1)` + truncation check with the longest seeded program title).
- [ ] **Step 4:** Commit audit — `git commit -m "docs: page-title audit"`

### Task 2: Fixes

**Files:**
- Modify: every FAIL page from AUDIT.md (expected set: `BreathingView.swift`, `DataExportView.swift`, `BodyMapView.swift`, `GuidedProgramDetailView.swift`, possibly `ContentPacksView.swift`, `LeaderboardView.swift`); `Resources/Localizable.xcstrings` for renamed literals.

Fix menu (apply the FIRST that resolves each FAIL):
1. Convention: align `.navigationBarTitleDisplayMode` per the Task 1 decision.
2. Shorten literal: "Export My Data" → "Export Data"; "Mark Your Body" → "Mark Areas".
3. Dynamic titles: keep `.inline` and let the system truncate, but move the full title into page content as a header (`GuidedProgramDetailView` already shows program info in-body — verify, then rely on inline truncation).
4. Only if 1–3 all fail for a page: custom `ToolbarItem(placement: .principal)` with `Text(title).font(.headline).minimumScaleFactor(0.75).lineLimit(1)`.

- [ ] **Step 1:** Apply fixes per page.
- [ ] **Step 2:** Re-screenshot every changed page (after/ pairs into the audit folder); all PASS.
- [ ] **Step 3:** Full test suite + build — green.
- [ ] **Step 4:** Commit — `git commit -m "fix: page titles fit at SE width; consistent display modes"`
