# VidStream App

A minimal video streaming clone built with Flutter and Firebase.

## Prerequisites

- Flutter SDK (Latest Stable)
- Firebase Project

## Setup

1.  **Clone/Download** the repository.
2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Firebase Configuration**:
    - Create a new Firebase project in the [Firebase Console](https://console.firebase.google.com/).
    - Enable **Authentication** (Anonymous Sign-in).
    - Enable **Cloud Firestore** (Test Mode is fine for development).
    - Run `flutterfire configure` to generate `lib/firebase_options.dart`.
    - **OR** manually place your `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) in the respective folders and ensure `firebase_options.dart` is correctly set up.

## Running the App

To run the app on Chrome (Web) or an Emulator:

```bash
flutter run
```

## Features

- **Home Feed**: Displays a list of mock videos.
- **Watch Later**: Click the clock icon on any video to save it to your Firestore "Watch Later" list.
- **Library**: View your saved videos.
- **Video Player**: Click any video to open the player screen.

## Project Structure

- `lib/models`: Data models.
- `lib/services`: Logic for Auth, Firestore, and Mock Data.
- `lib/screens`: UI Screens (Home, Library, Player).
- `lib/widgets`: Reusable UI components.
