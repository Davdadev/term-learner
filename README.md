# Term Learner

A modern iOS and macOS app for learning vocabulary terms using AI-powered image extraction, spaced repetition, and smart daily reminders.

## Features

- **AI Image Extraction** — Upload a photo of any vocabulary list (1–70 terms). Claude AI extracts and organises every term automatically.
- **Smart Reminders** — Configurable daily pop-ups quiz you on terms at the right time.
- **Spaced Repetition** — SM-2 algorithm schedules reviews based on your performance, so you never forget a term.
- **Collections** — Organise terms into colour-coded collections.
- **Progress Tracking** — Visual mastery distribution, per-collection progress, accuracy stats, and streak tracking.
- **Privacy First** — Copyright-aware extraction. Your API key and data never leave your device.
- **Universal** — Runs natively on iPhone, iPad, and Mac (via Mac Catalyst).

## Requirements

- Xcode 15+
- iOS 17+ / macOS 14+ (Sonoma)
- A Claude API key from [console.anthropic.com](https://console.anthropic.com)

## Setup

### 1. Generate the Xcode project

```bash
# Install xcodegen (if not installed)
brew install xcodegen

# Generate TermLearner.xcodeproj
make open
```

This installs `xcodegen` if needed, generates `TermLearner.xcodeproj`, and opens it in Xcode.

### 2. Configure signing

In Xcode, select the **TermLearner** target → **Signing & Capabilities** → set your Apple Developer Team.

### 3. Add your Claude API key

Launch the app and go to **Settings → API Key** to enter your key, or enter it during onboarding.

### 4. Build & Run

Press **⌘R** to run on iPhone Simulator, or select **My Mac (Mac Catalyst)** for the desktop app.

## Project Structure

```
TermLearner/
├── TermLearnerApp.swift          # App entry point, SwiftData container
├── ContentView.swift             # Tab bar navigation
├── Models/
│   ├── Term.swift                # SwiftData model with SM-2 spaced repetition
│   └── TermCollection.swift      # SwiftData collection model
├── Views/
│   ├── Onboarding/               # 4-screen onboarding flow
│   ├── Home/                     # Dashboard with stats and due terms
│   ├── Upload/                   # Image picker + AI extraction + review
│   ├── Collections/              # Collection list and detail views
│   ├── Study/                    # Swipe-card flashcard study session
│   ├── Progress/                 # Charts, mastery distribution, streaks
│   ├── Settings/                 # Notification settings, API key management
│   └── Components/               # Shared UI components
├── Services/
│   ├── ClaudeService.swift       # Anthropic Claude API (vision)
│   └── NotificationService.swift # Local notification scheduling
└── Utilities/
    ├── Constants.swift           # App-wide constants and colours
    └── Extensions.swift          # SwiftUI / Foundation helpers
```

## Architecture

- **SwiftUI** — Declarative UI, fully adaptive across iPhone, iPad, and Mac Catalyst
- **SwiftData** — Local persistence (iOS 17+ / macOS 14+)
- **Claude AI** — `claude-haiku-4-5-20251001` for fast, cost-efficient term extraction from images
- **UserNotifications** — Local notifications (no push server required)
- **SM-2 Algorithm** — Spaced repetition intervals: 1 → 3 → 7 → 14 → 30 → 60 days

## Privacy

- API keys are stored in `UserDefaults` on-device only.
- Anthropic's API does not train on data submitted via the API.
- Copyright-detected images display a notice but are still processed for personal study use.

## Deployment

### iPhone / iPad
Archive via **Product → Archive** and distribute through TestFlight or the App Store.

### macOS
Enable **Mac Catalyst** (already configured). Archive with macOS destination and distribute via the Mac App Store or direct export.

## License

MIT
