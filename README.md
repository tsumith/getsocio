# Get Socio 🎵

**Distributed Real-Time Audio Synchronization System for Flutter**

Get Socio is a Mobile application, which has an audio synchronization engine that allows a host to broadcast high-fidelity music to multiple client devices simultaneously. By leveraging local hotspots and a custom synchronization protocol, it achieves near real-time precision, effectively turning a group of mobile devices into a distributed speaker system.

---

## ✨ Key Features

- **⚡ Low-latency Sync:** Custom NTP-based clock synchronization to eliminate audio drift across devices.
- **📡 Local-First Networking:** Works over mobile hotspots/Wi-Fi using low-level Socket programming (TCP/IP).
- **🧵 Multi-Threaded Indexing:** Utilizes Dart Isolates for background metadata extraction and database writes.
- **🎵 Gapless Streaming:** Custom `StreamAudioSource` for real-time binary chunk playback.
- **💾 Optimized Persistence:** Transactional Sqflite implementation for fast, atomic music library indexing.

---

## ⚙️ How It Works (The Architecture)

### 1. Clock Sync Handshake

The system uses a four-way handshake similar to the Network Time Protocol (NTP).

1.  **Client** sends a `SyncTime` request with its current timestamp.
2.  **Host** receives it, appends its local arrival and departure timestamps, and sends it back.
3.  **Client** calculates the **Round Trip Time (RTT)** and the **Clock Offset**.
4.  This offset is applied to all future "Play" commands to ensure global synchronization.

### 2. High-Concurrency Music Indexing

To keep the UI running at a smooth, the app offloads intensive I/O tasks to **Dart Isolates**.

- **Metadata Isolate:** Scans files, extracts ID3 tags, and generates album art thumbnails in the background.
- **DB Writer Isolate:** Receives data from the metadata isolate and uses a **batch-processing strategy** to commit songs to the SQLite database.

### 3. Buffered Binary Streaming

Instead of sending whole files, the host streams audio in chunks.

- Clients use a `StreamingBufferSource` to feed these chunks into the `just_audio` engine.
- A **Ready-State Handshake** ensures playback only begins once all clients have buffered enough data (256KB-512KB) to prevent mid-song stuttering.

---

## 🚀 Tech Stack

- **Frontend:** [Flutter](https://flutter.dev) (Dart)
- **Audio Engine:** [just_audio](https://pub.dev/packages/just_audio)
- **Local DB:** [Sqflite](https://pub.dev/packages/sqflite)
- **Networking:** Dart `dart:io` Sockets (TCP)
- **Metadata:** `audio_metadata_reader`, `image`

---

## 📦 Project Structure

```text
lib/
├── core/
│   ├── sychro/        # Socket services, NTP Logic, & Sync Controller
│   ├── streaming/     # Custom ByteStream & Mime Helpers
│   └── database/      # Sqflite initialization & Isolate workers
├── models/            # Data models for Songs and Sync Messages
└── home/
    └── music_lib/     # UI Providers for Library & Playback state
```
