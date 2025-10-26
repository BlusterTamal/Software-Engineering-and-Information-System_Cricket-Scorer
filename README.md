# 🏏 Smart Numerix Cricket Scoring System

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![License](https://img.shields.io/badge/license-MIT-orange.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey.svg)
![University Project](https://img.shields.io/badge/project-CSE%203104-blue)

**Professional Cricket Match Management & Live Scoring System**

[Features](#-features) • [Installation](#-installation) • [Tech Stack](#️-tech-stack) • [Documentation](#-documentation)

</div>

---

## 📋 About

Smart Numerix Cricket Scoring System is a comprehensive mobile application designed for professional cricket match management. Built with Flutter and Appwrite, it provides real-time scoring, tournament management, player statistics, and much more.

### 🎯 Project Details

- **Course**: Software Engineering and Information System (0714 02 CSE 3104)
- **Year**: 3rd Year, 1st Term
- **Project Type**: Course Project

### 🌟 Key Highlights

- ✅ **Real-time Live Scoring** with ball-by-ball statistics
- ✅ **Tournament Management** with multi-group support
- ✅ **Player & Team Management** with comprehensive statistics
- ✅ **Cloud-based Backend** using Appwrite
- ✅ **Responsive Design** optimized for all mobile devices
- ✅ **Offline Support** with intelligent caching

---

## ✨ Features

### 🏏 Live Scoring
- Ball-by-ball scoring with detailed statistics
- Automatic striker/non-striker rotation
- Real-time run rate, required run rate, and target calculation
- DRS review tracking
- Time tracking per team
- Delivery correction feature

### 🏆 Tournament Management
- Multi-group tournament support
- Automated points table calculation
- Net Run Rate (NRR) calculation
- Stage-wise tournament progression
- Automatic standings update

### 👥 Player & Team Management
- Complete player profiles with photos
- Batting and bowling styles
- Player statistics and performance tracking
- Team creation and management
- Playing XI selection

### 📊 Statistics & Analytics
- Match statistics and scorecard
- Player performance metrics
- Team performance tracking
- Format-specific statistics (T20, ODI, Test)

---

## 🚀 Installation

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK
- Android Studio / Xcode
- Appwrite account

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/BlusterTamal/Software-Engineering-and-Information-System.git
   cd Software-Engineering-and-Information-System
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Secrets**
   - Copy `lib/config/secrets.dart.example` to `lib/config/secrets.dart`
   - Fill in your actual credentials in `lib/config/secrets.dart`:
     - Google OAuth Client ID and Secret
     - Appwrite endpoint and project ID
     - Redirect URI for OAuth
   - **NEVER commit `secrets.dart` to version control** (it's already in `.gitignore`)

4. **Configure Appwrite**
   - Create an Appwrite project
   - Update `lib/features/cricket_scoring/api/appwrite_constants.dart` with your credentials
   - Import the database schema from `appwrite.json`

5. **Run the application**
   ```bash
   flutter run
   ```

---

## 🔒 Security Notes

- All sensitive credentials are stored in `lib/config/secrets.dart` which is git-ignored
- Never commit actual secrets or API keys to the repository
- Use the example file (`secrets.dart.example`) as a template
- See `lib/config/README.md` for detailed configuration instructions

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **Material Design** - UI components

### Backend
- **Appwrite** - Backend-as-a-Service
- **Cloud Database** - NoSQL database
- **Authentication** - Built-in auth service

---

## 📁 Project Structure

```
lib/
├── main.dart
├── config/
│   ├── secrets.dart (git-ignored, contains actual credentials)
│   ├── secrets.dart.example (template file)
│   └── README.md (setup instructions)
├── home_page.dart
├── features/
│   └── cricket_scoring/
│       ├── api/
│       ├── models/
│       ├── screens/
│       ├── services/
│       └── widgets/
└── utils/
```

---

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👥 Team

- **Tamal** - Project Lead & Developer

---

## 📧 Contact

For questions or support:
- Email: tamalp241@gmail.com
- GitHub: [@BlusterTamal](https://github.com/BlusterTamal)

---

<div align="center">

**Made with ❤️ for Cricket Lovers**

⭐ Star this repo if you find it helpful!

</div>
