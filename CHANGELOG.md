# Changelog & Decision Log

All notable changes, decisions, and approaches (including rejected ones) are
recorded here so the project's history is traceable.

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
