# ChessLens

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![Engine](https://img.shields.io/badge/Engine-Stockfish-informational)](https://stockfishchess.org)
[![AI Coach](https://img.shields.io/badge/AI%20Coach-Google%20Gemini-orange)](https://ai.google.dev)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

> **A free, open-source alternative to Chess.com's expensive Game Review.**  
> Stockfish analyzes your moves. Google Gemini explains them in plain English.

---

## Why ChessLens?

Chess.com has a popular **Game Review** feature that tells you your accuracy, tags your blunders, and explains your moves. However, full access is locked behind an expensive subscription (Diamond or Platinum membership at $100+/year). Once your single free daily review is used up, you have to pay.

**ChessLens is built to solve that.**

It is a completely free, open-source Android app that gives you unlimited, master-level game review on your phone. No paywalls, no daily limits, no subscriptions, and no middleman servers.

---

## What It Does & Key Features

- **Analyze Any Game**: Paste PGN text or share games directly from Chess.com, Lichess, or anywhere else.
- **On-Device Stockfish Engine**: Powered by **Stockfish** (the world's strongest chess engine) running directly on your phone using native C++ code. Analysis is lightning-fast and works **100% offline** without needing a remote server.
- **Move Classifications**: Every single move is tagged just like Chess.com's game review:
  - **Best** & **Excellent** (optimal moves)
  - **Good** (solid moves)
  - **Inaccuracy** (minor positional slips)
  - **Mistake** (tactical or strategic errors)
  - **Blunder** (game-changing mistakes)
- **Accuracy Scores & Evaluation Graph**: See overall game accuracy percentages for both White and Black, along with an interactive momentum graph tracking the advantage across the entire match.
- **AI Coach (Plain-English Explanations)**: Instead of staring at confusing engine lines like `+3.42 (14... Nxe4 15. Qh5+)`, the AI coach (powered by Google Gemini) tells you *why* your move was bad, what tactic you missed, and what you should have done instead.
- **100% Free & Private**: No account registration, no telemetry, and no tracking. Everything runs on your device. Your free Gemini API key is stored locally with hardware-backed encryption.

---

## How It Works (In Simple Terms)

1. **You paste a game**: ChessLens parses the moves and validates the chess rules.
2. **Stockfish calculates the numbers**: The engine evaluates every position on your phone to find the best moves and measure advantage shifts.
3. **Move tagging**: The app compares what you played against what Stockfish recommended, scoring each move from Best to Blunder.
4. **Gemini explains the chess**: For the critical blunders and mistakes, Google Gemini acts as your personal coach and writes concise, human explanations in plain English.

---

## The Tech Under the Hood

- **Search Engine**: **Stockfish** compiled natively for Android via C++ FFI. It gives you grandmaster-level depth and speed right on your mobile hardware.
- **AI Coach**: **Google Gemini** API (fast and high-quality tactical summaries).
- **Chess Board UI**: **flutter-chessground** (the same smooth, performant board technology used by Lichess).
- **Framework**: Built with **Flutter & Dart** for a modern, responsive mobile experience.

---

## Getting Started

### 1. Free AI Coach Setup (Takes 30 seconds)

The AI coach uses Google's free Gemini API. You don't need a credit card:

1. Grab a free API key at [Google AI Studio](https://aistudio.google.com/apikey).
2. Open ChessLens on your phone, go to **Settings**, paste your key, and tap **Save & Verify Key**.
3. You're done! Your key stays saved securely on your phone.

*(Note: Even without a Gemini key, the Stockfish engine, move classifications, accuracy scores, and eval graphs will still work completely offline!)*

---

### 2. Building & Running the App

#### Prerequisites
- [Flutter SDK](https://flutter.dev) (3.47+)
- Android SDK & NDK (for the local Stockfish engine build)

#### Run locally:
```bash
git clone https://github.com/TheVee7/Chess-lens.git
cd Chess-lens
flutter pub get
flutter run
```

#### Build a Lightweight APK for Your Phone:
Modern Android phones run on 64-bit ARM (`arm64-v8a`). To produce a lean ~27 MB APK without extra engine binaries for other architectures:

```bash
flutter build apk --split-per-abi --release
```

The resulting file will be located at:
```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## Project Structure

```text
lib/
├── ai/          # Gemini AI Coach service and prompt builders
├── chess/       # PGN parser and board state manager
├── core/        # App configuration, theme, and game controller
├── engine/      # Local Stockfish FFI engine and UCI parser
├── models/      # Game data models (ChessGame, MoveAnalysis, etc.)
├── screens/     # UI screens (Home, Import, Quick Report, Analysis, Settings)
└── widgets/     # Reusable UI widgets (Chessboard, Eval Bar, Graph, Move List)
```

---

## Author & Credits

- **Creator**: Built by **Varun Dev Sharma (Vee)** ([LinkedIn](https://www.linkedin.com/in/varun-dev-sharma-b88260259/))
- **Stockfish**: Thanks to the [Stockfish Team](https://stockfishchess.org) for the world's best open-source engine (GPL-3.0).
- **Board UI**: Powered by [flutter-chessground](https://github.com/lichess-org/flutter-chessground) by Lichess.

---

## License

This project is open-source under the **GNU General Public License v3.0** ([GPL-3.0](LICENSE)) to honor Stockfish's open-source licensing.
