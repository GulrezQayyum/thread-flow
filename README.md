# ThreadFlow – AI-Powered Chat Application

A modern, feature-rich chat application built with Flutter that combines real-time messaging with AI-powered conversation analysis and thread organization.

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Project Structure](#-project-structure)
- [Key Features Explained](#-key-features-explained)
- [Contributing](#-contributing)
- [Security](#-security)
- [License](#-license)
- [Acknowledgments](#-acknowledgments)
  
---

## 🚀 Overview

ThreadFlow is an intelligent chat application that organizes conversations into **threads** and uses **AI** to automatically generate summaries, analyze sentiment, and extract keywords from conversations. Built with Flutter and Firebase, it provides a seamless real-time messaging experience with powerful AI enhancements.

### Why ThreadFlow?

- **Organized Conversations:** Threads keep discussions focused and easy to follow  
- **AI-Powered Insights:** Automatic summaries and sentiment analysis  
- **Real-Time Communication:** Instant messaging with typing indicators  
- **Cross-Platform:** Works on Android, iOS, and Web  

---

## ✨ Features

### Core Features

- ✅ **User Authentication** – Email/Password signup and login with Firebase Auth  
- ✅ **Real-Time Messaging** – Instant message delivery with Firestore streams  
- ✅ **Thread Organization** – Create and manage conversation threads  
- ✅ **Group Chats** – Create group chats and add members  
- ✅ **Message Reactions** – React to messages with emojis  
- ✅ **Image Sharing** – Upload and share images (Cloudinary integration)  
- ✅ **AI Summaries** – Auto-generated thread summaries using Groq LLM  
- ✅ **Sentiment Analysis** – AI-powered sentiment detection  
- ✅ **Search Messages** – Search through chat history  
- ✅ **Typing Indicators** – See when others are typing  
- ✅ **Delete/Leave Chats** – Delete chats or leave groups  
- ✅ **Dark Mode** – System-aware theme switching  
- ✅ **User Profiles** – Customizable user profiles with avatars  

### AI Features

- 🤖 **Thread Summaries:** 1–2 sentence summaries of conversations  
- 🤖 **Sentiment Analysis:** Positive, neutral, or negative sentiment detection  
- 🤖 **Keyword Extraction:** Extract key topics from conversations  
- 🤖 **Suggested Replies:** AI-powered reply suggestions  
- 🤖 **Thread Titles:** Auto-generated thread titles  

---

## 🛠️ Tech Stack

### Frontend

| Technology     | Version | Purpose              |
|----------------|---------|----------------------|
| Flutter        | 3.x     | UI Framework         |
| Dart           | 3.x     | Programming Language |
| Riverpod       | 2.4.0   | State Management     |
| Hooks Riverpod | 2.4.0   | Hooks + Riverpod     |
| Flutter Hooks  | 0.20.3  | Stateful Widgets     |

### Backend & Services

| Service                | Purpose                                 |
|------------------------|-----------------------------------------|
| Firebase Auth          | User Authentication                     |
| Firebase Firestore     | Real-time Database                      |
| Groq API               | AI-powered features (LLaMA 3.3 70B)     |
| Cloudinary             | Image Upload & Storage                  |
| Firebase Cloud Firestore | Real-time data sync                   |

### Dependencies

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  flutter_riverpod: ^2.4.0
  hooks_riverpod: ^2.4.0
  image_picker: ^1.0.4
  cloudinary_public: ^0.23.1
  google_sign_in: ^6.1.5
  cached_network_image: ^3.3.0
  flutter_dotenv: ^5.1.0
```

---

## 🏗️ Architecture

### Project Structure

```text
lib/
├── config/
│   ├── firebase_config.dart          # Firebase initialization
│   ├── firebase_options.dart         # Firebase platform configs
│   ├── groq_config.dart              # Groq API configuration
│   └── cloudinary_config.dart        # Cloudinary configuration
│
├── models/
│   ├── chat_model.dart               # Chat data model
│   ├── message_model.dart            # Message data model
│   ├── thread_model.dart             # Thread data model
│   └── user_model.dart               # User data model
│
├── providers/
│   ├── auth_provider.dart            # Authentication state
│   ├── chat_provider.dart            # Chat operations
│   ├── message_provider.dart         # Message operations
│   ├── ai_provider.dart              # AI features
│   ├── typing_provider.dart          # Typing indicators
│   ├── storage_provider.dart         # Image upload
│   └── service_providers.dart        # Service locator
│
├── services/
│   ├── auth_service.dart             # Firebase Auth service
│   ├── firestore_service.dart        # Firestore operations
│   ├── groq_service.dart             # Groq API integration
│   ├── cloudinary_storage_service.dart # Cloudinary upload
│   └── typing_indicator_service.dart # Typing management
│
└── ui/
    ├── screens/
    │   ├── auth/
    │   │   ├── login_screen.dart
    │   │   ├── signup_screen.dart
    │   │   └── forgot_password_screen.dart
    │   ├── home_screen.dart
    │   ├── chat_screen.dart
    │   ├── profile_screen.dart
    │   ├── settings_screen.dart
    │   └── chat_info_screen.dart
    ├── widgets/
    │   ├── message_bubble.dart       # Message display
    │   ├── message_input.dart        # Message composer
    │   ├── chat_list.dart            # Chat list
    │   ├── summary_banner.dart       # AI summary display
    │   ├── typing_indicator.dart     # Typing indicator
    │   ├── user_avatar.dart          # User avatar
    │   └── reaction_picker.dart      # Emoji reactions
    └── theme/
        └── app_theme.dart            # App theming
```

### Data Flow

```text
User Action → Provider → Service → Firestore/Groq → UI Update
     ↓
UI State ← Provider ← Service ← Firestore/Groq
```

---

## 📦 Installation

### Prerequisites

- Flutter SDK (3.x or higher)  
- Android Studio / VS Code  
- Firebase Account (free tier)  
- Groq API Key  
- Cloudinary Account (free tier)  

### Step 1: Clone the Repository

```bash
git clone https://github.com/GulrezQayyum/thread-flow.git
cd thread-flow
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Setup Firebase

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)  
2. Register your app (Android, iOS, Web)  
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)  
4. Place files in the respective directories  
5. Enable Authentication (Email/Password)  
6. Enable Firestore Database  
7. Update Firestore rules (see below)  

### Step 4: Environment Variables

Create a `.env` file in the project root:

```env
GROQ_API_KEY=your_groq_api_key
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

### Step 5: Firestore Rules

Update Firestore rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Step 6: Run the App

```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome
```

---

## 🔧 Configuration

### Groq API Setup

1. Sign up at [Groq Console](https://console.groq.com/)  
2. Generate an API key  
3. Add the key to your `.env` file  
4. Model used: `llama-3.3-70b-versatile`  

### Cloudinary Setup

1. Sign up at [Cloudinary](https://cloudinary.com/)  
2. Get your Cloud Name, API Key, API Secret  
3. Create an upload preset named `ml_default`  
4. Add credentials to `.env` file  

### Firebase Setup

- Enable Email/Password authentication  
- Enable Firestore Database  
- Set up security rules  
- Configure indexes (see below)  

### Required Firestore Indexes

| Collection | Fields                  | Order                  |
|------------|-------------------------|------------------------|
| chats      | members, lastMessageAt  | Ascending, Descending  |
| messages   | createdAt               | Ascending              |
| messages   | threadId, createdAt     | Ascending, Ascending   |
| threads    | lastMessageAt           | Descending             |

---

## 🎯 Key Features Explained

### Thread System

Threads organize conversations around specific topics:

```dart
// Creating a thread
final threadId = DateTime.now().millisecondsSinceEpoch.toString();
await sendMessage(
  text: "How's the project going?",
  threadId: threadId,
  isThreadStart: true,
);
```

### AI Summaries

Automatic thread summaries using Groq API:

```dart
// AI summary generation
final summary = await groqService.generateThreadSummary(messages);
// Result: "Team discussing project updates and Adam's whereabouts"
```

### Typing Indicators

Real-time typing indicators using Firestore:

```dart
// Set typing indicator
await typingService.setTyping(chatId, userId, userName);
// Auto-clears after 3 seconds
```

### Message Reactions

WhatsApp-style reactions:

```dart
// Toggle reaction
await toggleReaction(messageId, userId, '❤️');
```

---

## 🤝 Contributing

1. Fork the repository  
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)  
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)  
4. Push to the branch (`git push origin feature/AmazingFeature`)  
5. Open a Pull Request  

### Development Guidelines

- Follow Flutter/Dart best practices  
- Use Riverpod for state management  
- Write meaningful commit messages  
- Test thoroughly before submitting PR  

---

## 🔒 Security

### Authentication

- Firebase Authentication with Email/Password  
- Secure password reset flow  
- Session management via Firebase Auth  

### Firestore Security Rules

```javascript
// Basic security rules
allow read: if request.auth != null;
allow write: if request.auth != null && 
  request.auth.uid == request.resource.data.userId;
```

### API Keys

- All API keys stored in `.env` file  
- `.env` added to `.gitignore`  
- Keys not exposed in client code  

---

## 📄 License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) – UI Framework  
- [Firebase](https://firebase.google.com/) – Backend services  
- [Groq](https://groq.com/) – AI API  
- [Cloudinary](https://cloudinary.com/) – Image hosting  
- [Riverpod](https://riverpod.dev/) – State management  

---

Built with love, code, and too much coffee ☕
