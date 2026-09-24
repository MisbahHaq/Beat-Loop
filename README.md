# Beat Loop — A Music Player for Your Favorite Tracks

Beat Loop is a Flutter music player app built with a neo-brutalist, scrapbook-inspired design. It plays a curated catalog of songs offline, organizes them into artist-based playlists, and keeps playing in the background with full lock-screen media controls.

## Features

- **Playlist Library** — Browse artist-based playlists (like Hasan Raheem, Afusic, AMVs, All Songs) presented as tilted, neo-brutalist cards with washi-tape accents.
- **Now Playing** — Spinning album art, handwritten-style artist labels, a draggable progress bar, and full playback controls.
- **Background Playback** — Plays with the screen off via `audio_service`, with media notification and lock-screen controls (play, pause, next, previous, seek).
- **Offline Playback** — Downloads songs to your device so they play without an internet connection. A "download all songs" button fetches the entire catalog with a progress overlay.
- **Recently Played** — A quick-access strip of your recent listens.
- **Search** — Filter the full song catalog by title.

## Player Controls

- Play / pause, previous / next (wraps around, or shuffles when shuffle is on)
- Loop toggle (repeat one song / let it finish)
- Shuffle toggle
- Tap or drag on the progress bar to seek

## Getting Started

```bash
git clone https://github.com/yourusername/beatloop.git
cd beatloop
flutter pub get
flutter run
```

## Tech Stack

- **Flutter** — UI built with Material widgets and custom painters
- **audioplayers & audio_session** — playback engine
- **audio_service** — background playback and system media controls
- **dio** — song downloads with retry support
- **path_provider** — local storage for cached audio and artwork
- **google_fonts** — Playfair Display, JetBrains Mono, Caveat, and Inter typography

## Project Structure

```
lib/
├── main.dart                 # Entry point + audio service init
├── songs_data.dart           # Hardcoded song catalog
├── playlist_service.dart     # Playlist generation from artists
├── audio_service.dart        # Playback and download logic
├── beatloop_audio_handler.dart  # Background media handler
├── models.dart               # Song and Playlist models
├── theme.dart                # Color scheme and styling
├── widgets/                  # Reusable neo-brutalist widgets
└── Services/
    └── Apollo.dart           # Main library and player UI
```

## Note

The song catalog and playlists are currently hardcoded in the source (no backend API). All content is authored by Misbah.