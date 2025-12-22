# MusicApp (Flutter)

A modern **music browsing UI** built with **Flutter**.  
Includes Home recommendations, search, library, profile, playlist detail pages, and a simple mini-player state flow.

> Current focus: UI-first scaffolding (navigation + screens) before real audio + backend integration.

---

## Features (Current)
- Bottom navigation with 4 tabs: **Home / Search / Library / Profile**
- **Home** page sections:
  - Recommended playlists (horizontal cards)
  - Quick picks (track list)
  - Recently played (mini album cards)
- **Playlist detail** page with track list + durations
- Mini player bar (shows when a track is active)
- Basic player state management using `PlayerScope`

---

## Tech Stack
- **Flutter / Dart**
- Material 3 UI
- Local demo data (`lib/data/demo_data.dart`) for fast UI iteration

---
## Getting Started

### Prerequisites
- Flutter SDK installed
- Android Studio (for Android emulator) OR a physical Android phone
- Verify setup:

```bash
flutter doctor
```

Roadmap (Next Steps)

UI-first approach (in order):

Polish Home layout + spacing + cards

Add search interactions + results UI

Build Library screens (playlists, liked songs)

Improve Profile page + settings

Add “Now Playing” screen interactions

Replace demo data with real API/backend
