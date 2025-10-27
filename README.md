# 🏏 "Cricket Scorer" Cricket Scoring System

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![License](https://img.shields.io/badge/license-MIT-orange.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey.svg)
![University Project](https://img.shields.io/badge/project-CSE%203104-blue)

**Professional Cricket Match Management & Live Scoring System**

[Features](#-features) • [Installation](#-installation) • [Screenshots](#-screenshots) • [Tech Stack](#️-tech-stack) • [Contributing](#-contributing)

</div>

---

## 📋 About

"Cricket Scorer" is a comprehensive mobile application designed for professional cricket match management. Built with Flutter and Appwrite, it provides real-time scoring, tournament management, player statistics, and automated tournament standings with Net Run Rate (NRR) calculations.

### 🎯 Course Details

- **Course**: Softwere Engineering and Information Systems Project (0714 02 CSE 3104)
- **Year**: 3rd Year, 1st Term
- **University**: Khulna University

### 🎯 Course Teacher

- **Name**: Dr. Kazi Masudul Alam
- **Designation**: Professor
- **Discipline**: Computer Science and Engineering Discipline
- **University**: Khulna University

### 🌟 Key Highlights

- ✅ **Real-time Live Scoring** with ball-by-ball statistics
- ✅ **Tournament Management** with multi-group support
- ✅ **Player & Team Management** with comprehensive statistics
- ✅ **Cloud-based Backend** using Appwrite
- ✅ **Responsive Design** optimized for all mobile devices
- ✅ **Offline Support** with intelligent caching
- ✅ **Automated NRR Calculation** for tournament standings
- ✅ **Role-based Access Control** with Admin, Moderator, and User roles

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
- Captain and wicket-keeper assignment
- Squad management

### 📊 Statistics & Analytics
- Match statistics and scorecard
- Player performance metrics (Batting & Bowling averages, Strike rates, Economy)
- Team performance tracking
- Format-specific statistics (T20, ODI, Test)
- Partnership analysis
- Over-by-over analysis
- Powerplay statistics

### 🔐 Authentication & Security
- Google OAuth2 authentication
- Email OTP verification
- Role-based access control (Admin, Moderator, User)
- Secure session management
- User ban management
- Password reset functionality

### 🎨 User Experience
- Responsive design for all screen sizes (<360px to 600px+)
- Dark/Light theme support
- Smooth animations
- Intuitive navigation
- Offline cache support
- Real-time notifications

### 🔧 Admin Features
- User management and role assignment
- Match approval system
- System monitoring dashboard
- Content moderation
- User ban/unban functionality

---

## 📸 Screenshots

<div align="center">

### Live Scoring Interface
<img src="assets/screenshots/live_scoring.png" width="300" alt="Live Scoring">

### Tournament Management
<img src="assets/screenshots/tournament.png" width="300" alt="Tournament">

### Player Statistics
<img src="assets/screenshots/player_stats.png" width="300" alt="Player Statistics">

</div>

---

## 🚀 Installation

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK
- Android Studio / Xcode (for iOS)
- Appwrite account
- Android 5.0+ (API 21+) or iOS 11.0+

### Step-by-Step Setup

#### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/smart-numerix-cricket.git
cd smart-numerix-cricket
```

#### 2. Install Dependencies
```bash
flutter pub get
```

#### 3. Configure Appwrite Backend

Create an Appwrite account at [https://appwrite.io](https://appwrite.io)

Update the following file with your Appwrite credentials:

**File**: `lib/features/cricket_scoring/api/appwrite_constants.dart`
```dart
static const String projectId = 'your-project-id';
static const String endPoint = 'https://your-appwrite-url/v1';
static const String databaseId = 'your-database-id';
```

#### 4. Import Database Schema

Import the database schema from `appwrite.json` into your Appwrite project:

1. Go to your Appwrite Console
2. Navigate to Databases → Your Database
3. Import the schema from `appwrite.json`

#### 5. Configure Google OAuth (Optional)

Update `lib/main.dart` with your Google OAuth credentials:
```dart
const String googleClientId = 'your-google-client-id';
const String googleClientSecret = 'your-google-client-secret';
const String redirectUri = 'your-redirect-uri';
```

#### 6. Run the Application
```bash
flutter run
```

### Configuration Files

Update these files with your specific credentials:

| File | Description |
|------|-------------|
| `lib/features/cricket_scoring/api/appwrite_constants.dart` | Appwrite project configuration |
| `lib/main.dart` | Google OAuth credentials |
| `appwrite.json` | Database schema configuration |

---

## 🛠️ Tech Stack

### Frontend Development
- **Flutter 3.0+** - Cross-platform mobile framework
- **Dart** - Programming language
- **Material Design 3** - Modern UI components
- **Provider** - State management
- **Responsive Design** - Mobile-first approach

### Backend & Services
- **Appwrite 13.0** - Backend-as-a-Service
- **Cloud Database** - NoSQL database with real-time sync
- **Authentication** - Google OAuth2 & Email OTP
- **Storage** - File storage for images
- **Real-time Updates** - WebSocket connections

### Key Dependencies

| Package | Version | Purpose |
|--------|---------|---------|
| `appwrite` | ^13.0.0 | Backend services |
| `google_sign_in` | ^6.2.1 | Google authentication |
| `flutter_web_auth_2` | ^4.0.0 | OAuth2 flow |
| `shared_preferences` | ^2.2.2 | Local caching |
| `image_picker` | ^1.0.7 | Image selection |
| `intl` | ^0.20.2 | Internationalization |
| `google_fonts` | ^6.2.1 | Custom fonts |
| `provider` | ^6.1.2 | State management |
| `fl_chart` | ^0.68.0 | Data visualization |

### Development Tools
- **Flutter SDK** - Development framework
- **Android Studio** - IDE
- **VS Code** - Code editor
- **Appwrite CLI** - Backend management

---

## 📁 Project Structure

```
smart-numerix-cricket/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── home_page.dart                     # Home screen
│   ├── features/
│   │   └── cricket_scoring/
│   │       ├── api/
│   │       │   └── appwrite_constants.dart  # Backend config
│   │       ├── models/                     # Data models
│   │       │   ├── match_model.dart
│   │       │   ├── player_model.dart
│   │       │   ├── team_model.dart
│   │       │   └── ...
│   │       ├── screens/                    # UI screens
│   │       │   ├── auth/                   # Authentication
│   │       │   ├── admin/                  # Admin dashboard
│   │       │   ├── players/                # Player management
│   │       │   ├── scoring/                # Live scoring
│   │       │   ├── tournament/             # Tournament
│   │       │   └── profile/                # User profile
│   │       ├── services/                   # Business logic
│   │       │   ├── database_service.dart
│   │       │   ├── auth_service.dart
│   │       │   └── cache_service.dart
│   │       └── widgets/                    # Reusable widgets
│   │           ├── live_match_card.dart
│   │           └── ...
│   └── utils/
│       └── responsive_helper.dart         # Responsive utilities
├── android/                                # Android config
├── ios/                                    # iOS config
├── assets/                                 # Images, fonts
├── pubspec.yaml                            # Dependencies
├── appwrite.json                           # Database schema
└── README.md                               # This file
```

---

## 🗄️ Database Schema

The app uses 28+ database collections in Appwrite:

### Core Collections
- **matches** - Match information and status
- **teams** - Team details and configurations
- **players** - Player profiles and information
- **tournaments** - Tournament structure
- **innings** - Innings data
- **deliveries** - Ball-by-ball delivery data

### Statistics Collections
- **player_match_stats** - Individual player match statistics
- **player_stats** - Aggregated player career statistics
- **partnerships** - Partnership tracking
- **bowling_spells** - Bowling spell analysis
- **dismissals** - Wicket tracking

### Management Collections
- **playing_xi** - Selected playing XI
- **tournament_groups** - Tournament groups
- **points_tables** - Tournament standings
- **notifications** - User notifications
- **match_approvals** - Admin approvals

---

## 🎓 Project Documentation

### Database Schema
The complete database schema is defined in `appwrite.json`. Import this file into your Appwrite project to set up all collections, attributes, and indexes.

### API Documentation
- **Database Operations**: Handled through `DatabaseService`
- **Authentication**: Managed by `CricketAuthService`
- **Caching**: Implemented in `CacheService`
- **Real-time Sync**: Appwrite real-time subscriptions

### Key Features Implementation

#### Live Scoring
- Ball-by-ball tracking with automatic calculations
- Real-time run rate and target calculations
- DRS review management
- Delivery correction capability

#### Tournament Management
- Multi-group tournament support
- Automated NRR calculation
- Automatic points table updates
- Stage progression tracking

#### Player Management
- Complete player profiles
- Performance statistics tracking
- Team assignments
- Playing XI selection

---

## 🤝 Contributing

This is a university course project. Contributions are welcome:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines

- Follow Flutter and Dart style guidelines
- Write clear, documented code
- Test your changes thoroughly
- Ensure responsive design compatibility
- Follow existing code structure

---

## 📝 License

This project is licensed under the MIT License.

See the [LICENSE](LICENSE) file for details.

---

## 👥 Team

- **MD. Ishrak Dewan** - Project Design, Developer and Idea Making.
- **Tamal Paul** - Project Lead, Idea Making, Android Studio Expert
  - Email: tamalp241@gmail.com
  - GitHub: [@yourusername](https://github.com/yourusername)
- **Jagaran Chakma** - Project Design, Error Solving, App Testing, Coding Expertise.

---

## 🙏 Acknowledgments

- **Flutter Team** - Amazing cross-platform framework
- **Appwrite** - Excellent backend-as-a-service platform
- **Google** - Authentication services
- **Cricket Enthusiasts** - Feature suggestions and feedback

---

## 📧 Contact

For questions, support, or collaboration opportunities:

- **Email**: tamalp241@gmail.com
- **GitHub**: [@yourusername](https://github.com/yourusername)
- **Issues**: [GitHub Issues](https://github.com/yourusername/CricketScorer/issues)

---

## 🔮 Future Enhancements

- [ ] Web version using Flutter Web
- [ ] Desktop applications for Windows, Mac, Linux
- [ ] Advanced analytics dashboard
- [ ] Video highlights integration
- [ ] Social sharing features
- [ ] Multi-language support
- [ ] Fantasy cricket integration
- [ ] Live streaming integration
- [ ] Player comparison tools
- [ ] Advanced statistics visualization

---

<div align="center">

**Made with ❤️ for Cricket Lovers**

⭐ If you find this project helpful, please star this repo!


</div>
