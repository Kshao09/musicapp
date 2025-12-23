# SoundByte (Flutter)

A modern, dark-themed music app UI built with Flutter (Material 3).

This project focuses on **navigation, screen layouts, and player state flow** (mini-player + queue + Now Playing) so the app feels real end-to-end before plugging in a backend and an audio engine.

---

## Screenshots

> Captured on Android Emulator
<img width="209" height="473" alt="image" src="https://github.com/user-attachments/assets/9ed64a15-8bc0-431a-bec2-34ec56fac9db" />

<img width="203" height="473" alt="image" src="https://github.com/user-attachments/assets/0804d6d3-bfc9-49a0-b99d-12adeff7dd49" />

<img width="204" height="467" alt="image" src="https://github.com/user-attachments/assets/7b724f2f-dbcd-49cd-b7b7-fcb1ef12ac0c" />

<img width="209" height="467" alt="image" src="https://github.com/user-attachments/assets/99bee298-f272-47ad-a110-51c4b4494656" />

<img width="200" height="468" alt="image" src="https://github.com/user-attachments/assets/a8db2a38-4206-42ee-961c-d6dcc5c3240b" />

<img width="203" height="466" alt="image" src="https://github.com/user-attachments/assets/1d92bb6f-9564-44e5-99d7-cc0d55a8ca00" />

<img width="201" height="482" alt="image" src="https://github.com/user-attachments/assets/c42ed8d7-6f88-48e4-a8d1-d67bd55629c8" />

<img width="192" height="311" alt="image" src="https://github.com/user-attachments/assets/382547c7-0145-44ad-8b29-b67c29693a57" />

<p align="center">
  <img src="assets/screenshots/liked_songs.png" width="200" />
  <img src="assets/screenshots/profile.png" width="200" />
</p>
---

## Features

### Navigation & Screens
- Bottom navigation with 4 tabs: **Home / Search / Library / Profile**
- **Home**
  - “Recommended for you” playlists (horizontal cards)
  - “Quick Picks” track list with like + play actions
- **Search**
  - Search bar + results list UI
  - Track tiles with like + play actions
- **Library**
  - Sections: My Playlists, Liked Songs, Downloads
  - Playlist grid/cards
- **Profile**
  - Settings, Listening History, About
  - Quick actions (refresh / open liked songs)

### Player UI Flow
- Persistent **mini-player bar** (appears when a track is active)
- **Now Playing** screen
  - Large artwork + title/artist
  - Progress slider + timestamps
  - Playback controls (prev / play-pause / next)
  - “Up Next” queue list (“x in queue”)
- Queue-aware playback behavior (play from a list and navigate next/prev)

### UX Details
- Consistent dark UI styling + rounded cards
- Track action affordances (tap to play, like button, quick play icons)
- Clean spacing and list/card layout patterns

---

## Tech Stack
- Flutter / Dart
- Material 3
- Scoped state pattern:
  - `PlayerScope` for mini-player + queue + Now Playing state
  - (Optional) `SpotifyScope` for future integration

---

## Getting Started

### Prerequisites
- Flutter SDK
- Android Studio (emulator) or a physical Android device

Verify environment:
```bash
flutter doctor
