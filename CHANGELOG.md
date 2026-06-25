# Changelog & Decision Log

All notable changes, decisions, and approaches (including rejected ones) are
recorded here so the project's history is traceable.

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
