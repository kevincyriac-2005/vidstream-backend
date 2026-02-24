# Vidstream
A high-performance, open-source video streaming client — built with Flutter & Firebase for a seamless cross-platform experience.
Centralizes video discovery, personalized libraries, real-time community engagement, and cross-device synchronization — all powered by the YouTube Data API.

Run it on Android, iOS, Web, or Desktop with a single codebase.

**Framework:** Flutter  
**Backend:** Firebase  
**License:** MIT  

---

[Key Features](#-key-features) • [Technology Stack](#-technology-stack) • [User Experience](#-user-experience) • [Installation](#-installation-and-configuration) • [Usage](#-usage) • [API Documentation](#-api-documentation) • [Troubleshooting](#-troubleshoot) • [Contributing](#-contributing) • [License](#license)

---

## ✨ Key Features


*   **Hybrid Authentication** — Seamless transition from Anonymous guest sessions to Google-authenticated profiles.
*   **Real-Time Engagement** — Instant comment synchronization and persistence powered by Cloud Firestore.
*   **Intelligent Discovery** — Global search and "Most Popular" feeds fetched directly via YouTube Data API v3.
*   **Privacy-First Player** — Custom IFrame implementation using the `youtube-nocookie` domain for ad-light, private viewing.
*   **Advanced Player Controls** — Support for Theater Mode, Autoplay toggles, and variable playback speeds.
*   **Cross-Platform UI** — A fully responsive, glassmorphic design that adapts to Desktop, Tablet, and Mobile screens.
*   **Subscription Sync** — Fetch and display actual user subscriptions for authenticated Google accounts.

---

## 💻 Technology Stack

*   **Frontend** — Flutter (3.x)
*   **Backend** — Firebase (Authentication & Cloud Firestore)
*   **API Layer** — YouTube Data API v3
*   **State Management** — Provider
*   **Navigation** — GoRouter (Declarative routing)
*   **Libraries**
    *   `youtube_player_iframe` — Logic-heavy IFrame controller
    *   `google_sign_in` — OAuth2 integration
    *   `flutter_dotenv` — Secure environment variable management
    *   `intl` — Localization and date formatting

---

## 👥 User Experience

### Guest User
*   Browse trending videos and search the global database.
*   Watch videos in a high-performance player.
*   View public comments and related suggestions.

### Authenticated User
*   **Custom Library**: Save videos to a persistent "Watch Later" list.
*   **Community**: Post comments and engage with video discussions.
*   **Subscribers**: Access a personalized view of subscribed channels.
*   **Sync**: Carry library and preferences across all supported platforms.

---

## 🛠️ Installation and Configuration

### Prerequisites
*   Flutter SDK (Stable channel)
*   Firebase CLI
*   Google Cloud Console Account (for YouTube API Key)

### 1. Clone the project
```bash
git clone https://github.com/kevin-cyriac2005/vidstream-app.git
cd vidstream_app
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Environment Setup
Create a `.env` file in the root directory:
```env
YOUTUBE_API_KEY=your_api_key_here
GOOGLE_WEB_CLIENT_ID=your_client_id_here
```

### 4. Firebase Configuration
Initialize Firebase for your platforms:
```bash
flutterfire configure
```
This will generate `lib/firebase_options.dart`. Ensure you enable **Google** and **Anonymous** providers in the Firebase Auth console.

### 5. Launch
```bash
flutter run
```

---

## 🚀 Usage

1.  **Browse**: Open the app to see the latest popular videos from YouTube.
2.  **Search**: Use the top search bar to find specific content.
3.  **Sign In**: Use the Profile tab to sign in with Google for a personalized experience.
4.  **Save**: Tap the clock icon on any video card to add it to your Library.
5.  **Interact**: Open a video to read or post comments in the real-time discussion thread.

---

## 🔌 API Documentation

The app interacts with the YouTube Data API v3 and Firebase Services.

### Internal Services
Files located in `lib/services/`.

| Service | Category | Description |
| :--- | :--- | :--- |
| `YoutubeService` | Data | Fetching popular videos, search results, and subscriptions. |
| `AuthService` | Auth | Managing Google Sign-In and Anonymous sessions. |
| `FirestoreService` | Persistence | Handling comments, watch later lists, and user data. |

### YouTube API Endpoints (Used)
| Endpoint | Method | Purpose |
| :--- | :--- | :--- |
| `/videos` | GET | Fetching "Most Popular" chart and video details. |
| `/search` | GET | Global search for video content. |
| `/subscriptions` | GET | Retrieving authenticated user's channel list. |

---

## ⚠️ Troubleshoot

### "Video Unavailable" or Error 152
*   **Cause**: The video creator has disabled embedding for third-party apps.
*   **Fix**: This is a restriction by the content owner; try a different video.

### YouTube API Quota Exceeded
*   **Cause**: You have hit the daily free limit (10,000 units) for your Google Cloud Project.
*   **Fix**: Wait 24 hours or request a quota increase in the Google Cloud Console.

### Comments not loading
*   **Cause**: Firestore rules are blocking access or Firebase is not initialized.
*   **Fix**: Ensure `flutterfire configure` was run and Firestore rules allow authenticated/anonymous read/write.

---

## 🤝 Contributing

1.  Fork the repo
2.  Create your feature branch (`git checkout -b feature/awesome-feature`)
3.  Commit your changes (`git commit -m 'Add some feature'`)
4.  Push to the branch (`git push origin feature/awesome-feature`)
5.  Open a Pull Request

---

## 👥 Contributors

*   **Kevin Cyriac** — Lead Developer & Architect

---

## License

Distributed under the MIT License. See `LICENSE` for more information.
