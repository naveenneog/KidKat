# Changelog & Decision Log

All notable changes, decisions, and approaches (including rejected ones) are
recorded here so the project's history is traceable.

## [0.6.0] — QA bug-fix pass (Senior QA review on Android emulator)

A Senior-QA pass on an `android-34` emulator (driven via `adb` tap/swipe +
screenshots + logcat) verified the core flows and surfaced a set of issues.
All flows passed except the items below, which are now fixed.

### Fixed
- **Invisible button labels (white-on-white) — High.** `BigButton(color: …)` kept
  the global ElevatedButton theme's white foreground, so light/white buttons
  showed a blank pill (confirmed on the Break screen "Back home" button, plus
  onboarding and Time-up). `BigButton` now derives a legible foreground from the
  background's brightness (dark ink on light buttons, white on dark).
- **Theme switch only partially applied — Medium.** Two parts:
  1. **Candy Bright was purple-forward** because its palette had `primary`/
     `secondary` swapped vs the requested spec. Fixed to **primary `#EC4899`
     (pink)**, secondary `#8B5CF6` (purple) — the theme now reads as candy/pink.
  2. Hardcoded `KidColors.*` chrome is now palette-driven: kid-home time chip +
     saved icon + lock, player **Next** button + progress dots, parent gate lock
     + PIN dots, saved screen, and parent-settings section icons all follow the
     active theme. (Topic tiles keep their per-category colors by design.)
- **Player transition glitches — Medium.** Between clips the YouTube IFrame
  briefly showed its **own chrome** — the *previous* video's title/avatar, the
  YouTube logo and a related-video card (a tap-out vector for kids). A branded
  loading overlay (KidKat logo + spinner) now covers the player while a new clip
  loads, and lifts the moment playback starts (with a 6s fail-safe). This hides
  the title mismatch and the YouTube logo/related card during transitions.
- **Demo clips weren't kid-appropriate — Low.** The debug/no-key demo playlist
  used pop-music placeholders (Rickroll, Gangnam Style, Despacito). Replaced with
  family-friendly, CC-licensed, embeddable **Blender open movies** (Big Buck
  Bunny, Caminandes ×2, Spring, Sintel) with real titles. IDs verified via
  YouTube oEmbed.
- **API key could silently diverge — Low.** Editing the key field after a
  successful verify reset the status chip but kept the old saved key. The field
  now clears the saved key on edit, so the visible text and the key in use can't
  disagree (treated as "not connected" until re-verified).
- **Verify button hidden by the keyboard — Low.** The API-key field now submits
  on the keyboard's **Go** action, so a manually-typed key can be verified
  without reaching the button behind the soft keyboard.

### Verified working (no change needed)
- Swipe up = next / swipe down = previous (the earlier "broken swipe" report was
  a test-harness artifact: a stray, ANR-ing app stole focus on the shared
  emulator and screencaps/uiautomator returned stale frames).
- Finite session → "Great job!" break screen; **daily time-limit lock**
  ("That's all for today!"); bookmark + Saved + Play-all; omit-watched and
  watch-time accrual; parent PIN gate + dashboard.

### Notes / not changed
- 16:9 clips letterbox in the player — this is intentional for vertical Shorts
  (9:16 fills); cropping would clip real Shorts.
- The YouTube logo can still appear when a child **manually pauses** — YouTube's
  ToS requires the branding/click-through, so it can't be fully removed; the
  transition overlay handles the common (between-clips) exposure.

### Tests
- Added `test/bugfix_regression_test.dart`: Candy palette is pink-forward, demo
  clips are the kid-safe Blender set, and `BigButton` stays legible on light/dark
  backgrounds. Full suite: **50 tests passing**; `flutter analyze` clean.

## [0.5.0] — Working swipe, saved videos, omit-watched (emulator-tested)

### Player gestures (swipe up/down) — fixed & verified on an Android emulator
- **Root cause:** the YouTube IFrame WebView swallows drag gestures on Android —
  Flutter `GestureDetector`/`Listener`/`gestureRecognizers`/`controlsBuilder` never
  receive drags, and `runJavaScriptReturningResult` hangs.
- **Fix:** inject a JS overlay catcher inside the WebView (and set the iframe's
  `pointer-events:none`) that detects swipe/tap and posts back via a
  `addJavaScriptChannel('KidKatGesture')` channel. **Swipe up = next, down =
  previous** now works; tap = play/pause. Verified end-to-end on an `android-34`
  emulator via `adb input swipe` + logcat + screenshots.
- Controls moved to slim top/bottom bars (always visible & tappable): close,
  "🎓 x / y", **bookmark**, title, progress, **Back / Next**.

### Bookmark + Saved videos
- Bookmark button in the player saves a video; new **Saved** screen (bookmark icon
  on the kid home) lists them and can replay all. Persisted on-device.

### Omit already-watched
- Played video ids are remembered and excluded from future sessions so kids keep
  getting fresh content.

### Testing aids
- Debug-only **demo playlist** + `--dart-define=KIDKAT_DEMO=true` boot-straight-to-
  player flag, used to validate playback + gestures without an API key.

### Quality
- 45 passing tests (added watched-exclude + saved/watched persistence),
  `flutter analyze` clean.

## [0.4.0] — New 3D logo + theme switcher

### Branding
- Adopted the user-provided **3D graduate-cat** artwork. `KidKat Image 2` →
  full-bleed app icon; `KidKat 3` → background flood-filled to a **transparent
  cat** (interior whites like eyes/whiskers preserved) used for the Android
  adaptive foreground and native splash. Source art kept in `assets/branding/source`.

### Theme switcher 🎨
- Five colorful themes: **Purple Pop, Candy Bright, Ocean, Sunset, Forest**
  (`AppPalette` + `ThemeId`), persisted on `ParentConfig`.
- App theme, brand gradients (welcome/break/time-up) and a new **colorful kid
  home backdrop** (soft floating shapes) all react to the selected palette.
- Theme picker with live gradient swatches in Parent settings.

### Quality
- 42 passing tests (added `themeId` persistence), `flutter analyze` clean.

## [0.3.0] — Swipe navigation, age-appropriate channels, bigger logo

### Player: swipe + previous/next + back
- Added **vertical swipe** in the full-screen player: swipe **up = next**,
  **down = previous** (kids' Shorts muscle memory). Plus explicit **Back/Next**
  buttons (Back disabled on the first video) and a top **✕** to exit.
- Android system back is handled via `PopScope` (exits to home, restoring system
  bars). A brief auto-hiding swipe hint guides first-time users.

### Age-appropriate content
- New **AgeBand** (Preschool 3–5 / Early 6–8 / Tween 9–12) on `ParentConfig`.
- Onboarding now asks the child's age and **pre-fills age-appropriate trusted
  channels** (e.g. Khan Academy Kids/StoryBots/Numberblocks for preschool;
  SciShow Kids/Nat Geo Kids for early; TED-Ed/Crash Course for tweens).
- Curation biases search queries by age (`ageQuery`) and the dashboard's
  quick-add channels + a new **Child age** section reflect the band. Capped
  allowlist channel searches per session to bound API quota.

### Branding
- Enlarged the cat further (icon 1.28→1.42×, adaptive foreground 0.82→0.92) so it
  fills the icon/launcher. Regenerated icons + splash.

### Quality
- 42 passing tests (added `ageQuery` + `ageBand` cases), `flutter analyze` clean.

## [0.2.0] — Full-screen shorts + guided API setup + bigger logo

### Full-screen Shorts player
- Rewrote the session player to be **immersive full-screen**: the video fills the
  screen (system bars hidden via `SystemUiMode.immersiveSticky`), with overlay
  top/bottom controls (close, "Video x of N", title, channel, progress, Next/Done).
- Tap anywhere to pause/play; `autoFullScreen`/`enableFullScreenOnVerticalDrag`
  disabled so vertical shorts stay upright and edge-to-edge.

### Guided, self-verifying API key setup
- New `ApiKeySetup` widget: deep-links straight to the right Google Cloud Console
  pages (`flows/enableapi?apiid=youtube.googleapis.com` + Credentials), a
  **Paste-from-clipboard** button, and **live key verification** that saves the key
  automatically on success. Used in onboarding and the parent dashboard.
- Added `YouTubeApi.validateKey()` (cheap `i18nLanguages` call) returning
  `ApiKeyStatus { valid, invalid, serviceDisabled, unreachable }`. Improved error
  reason parsing to read the `details[].reason` ErrorInfo (API_KEY_INVALID,
  SERVICE_DISABLED). Added `url_launcher`.
- Note: an app cannot silently mint a Google API key (requires the user's own
  Cloud project + consent); this is the compliant "as close to one-tap as possible".

### Branding
- Enlarged the cat in the app icon (~1.28×) and the Android adaptive foreground
  (0.64→0.82) so the logo fills the icon/launcher instead of looking small.
  Regenerated launcher icons + splash.

### Tests
- 41 passing (added `validateKey` cases: valid / empty / invalid / serviceDisabled /
  quota-as-valid). Updated onboarding widget test for the new setup UI.
- `flutter analyze`: 0 issues.

### Docs
- Landing page: updated player mock to the full-screen shorts UI, refreshed icon,
  added a "Full-screen shorts" feature.

## [0.1.0] — Initial build

### Compliance decision (the most important one)
- **Investigated** whether "log into a YouTube Kids account + override the
  algorithm" is permitted/possible. **Conclusion: no.**
  - No public **YouTube Kids API** exists → cannot authenticate Kids accounts.
  - YouTube API Services ToS **prohibit** overriding recommendations, building a
    substitute client, and extracting/re-serving video streams.
  - The official **embedded/IFrame player is mandatory** for playback.
- **Chosen approach:** a compliant *curated educational front-end*:
  - Discovery via **YouTube Data API v3** (search + metadata only).
  - Playback via the official **IFrame player** (`youtube_player_iframe`).
  - **Our own curation** (parent allowlist + Education/Science category filter) —
    explicitly **not** reading or altering YouTube's algorithm.
  - No Kids login; on-device profiles only; no child PII.

### Tech choices
- **Flutter** (single Android + iOS codebase). Rationale: one codebase, official
  IFrame player package available, and the Android side is buildable/testable on
  the Windows dev host.
- **Riverpod** for state, **go_router** for navigation, **google_fonts** (Baloo 2 /
  Nunito) for the kid-friendly type, **shared_preferences** for local storage.
- Riverpod resolved to **v3**, where `StateProvider`/`StateNotifierProvider` moved
  to `package:flutter_riverpod/legacy.dart`. **Decision:** import `legacy.dart`
  (officially supported) instead of rewriting to `Notifier` to keep the change
  surface small.

### Branding
- Designed an original **graduate-cat** logo (SVG) + wordmark; rasterized with
  `sharp` (`tool/icongen/generate.js`) into app icon, adaptive fg/bg, splash and
  wordmark PNGs. Generated launcher icons + native splash.

### Features implemented
- First-run **parent onboarding** (API key + PIN + interests).
- **Parent PIN gate** and **dashboard** (interests, channel allowlist with one-tap
  trusted channels + custom add, daily limit, videos-per-session, video length,
  Safe Search, reset today's watch time, compliance note).
- **Kid home** (interest tiles, time-left indicator, start session, locked state).
- **Session player**: finite curated queue via the official IFrame player,
  deliberate Next, progress dots, **daily time-limit enforcement**, break screen
  and time-up screen. Related videos restricted to the same channel.
- **Anti-doomscroll** guardrails throughout (finite sessions, no infinite feed,
  daily caps, parent gate).

### Data / curation
- `YouTubeApi`: `resolveChannelId`, `searchShortVideos` (embeddable + safe-search +
  short duration), `videos.list` hydration; structured error handling
  (`quotaExceeded`, invalid key, network).
- `CurationService.buildSession`: combines allowlist-scoped + open topic discovery,
  applies `filterEducational` (duration ≤ max, Education/Science category OR
  allowlisted channel, de-dup), shuffles (seedable) and caps to session size.
- `LocalStore`: config persistence, onboarding flag, per-day watch-time (clock
  injectable for tests).

### Testing
- 36 passing tests: duration parsing, curation filter, Data API client (mocked
  HTTP, incl. quota/invalid-key), local store + daily watch-time isolation,
  end-to-end session building, onboarding widget smoke tests.
- `flutter analyze`: **0 issues**.

### Platform config
- Android: label set to **KidKat**, added **INTERNET** permission (player + API).
- iOS: `CFBundleDisplayName` set to **KidKat**.

### Known limitations / next steps
- iOS must be compiled on macOS/Xcode (dev host is Windows).
- Real device/emulator playback should be validated end-to-end with a live API key.
- Possible future work: multiple kid profiles, offline "approved" cache, watch
  history for parents, localization, instrumented (integration) tests.
