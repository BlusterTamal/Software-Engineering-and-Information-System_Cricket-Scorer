# User Profile System

A comprehensive user profile system that displays user information and their created matches and tournaments.

## Features

### 🎯 Core Functionality
- **User Information Display**: Shows user name, email, and avatar
- **Match Management**: View all matches created by the user
- **Tournament Management**: View all tournaments created by the user
- **Statistics Overview**: Quick stats showing total matches, tournaments, and live matches
- **Quick Actions**: Easy access to create new matches, tournaments, and manage players

### 🎨 UI Components
- **ProfileMatchCard**: Specialized match card for profile display
- **Tabbed Interface**: Organized view with separate tabs for matches, tournaments, and actions
- **Statistics Cards**: Visual representation of user activity
- **Action Cards**: Quick access to common functions

## File Structure

```
lib/features/cricket_scoring/screens/profile/
├── user_profile_screen.dart          # Main user profile screen
└── README.md                         # This file

lib/features/cricket_scoring/widgets/
└── profile_match_card.dart           # Specialized match card widget
```

## Screen Overview

### User Profile Screen (`user_profile_screen.dart`)
**Main profile interface with comprehensive user information**

#### **Features:**
- **User Header**: Large avatar, name, and email display
- **Statistics Cards**: Total matches, tournaments, and live matches
- **Tabbed Interface**: Three tabs for different content types
- **Logout Functionality**: Easy logout with confirmation

#### **Three Main Tabs:**

##### 1. **My Matches Tab**
- Displays all matches created by the user
- Uses `ProfileMatchCard` for detailed match information
- Shows match status, teams, date/time, and overs
- Empty state with call-to-action to create first match
- Pull-to-refresh functionality

##### 2. **My Tournaments Tab**
- Displays all tournaments created by the user
- Shows tournament name, format, start/end dates
- Empty state with call-to-action to create first tournament
- Pull-to-refresh functionality

##### 3. **Quick Actions Tab**
- Create Individual Match
- Create Tournament
- Manage Players
- View Live Matches
- Easy navigation to all major functions

### Profile Match Card (`profile_match_card.dart`)
**Specialized widget for displaying match information in profile**

#### **Features:**
- **Status Indicator**: Color-coded status with icons
- **Team Information**: Team names with avatars
- **Match Details**: Date/time, overs, result summary
- **Visual Design**: Clean, card-based layout
- **Loading States**: Proper loading indicators

## Database Integration

### User-Specific Queries
```dart
// Get matches created by user
Future<List<MatchModel>> getMatchesByUser(String userId)

// Get tournaments created by user  
Future<List<TournamentModel>> getTournamentsByUser(String userId)

// Get user statistics
Future<Map<String, int>> getUserStats(String userId)
```

### Statistics Provided
- **Total Matches**: Count of all matches created
- **Total Tournaments**: Count of all tournaments created
- **Live Matches**: Count of currently live matches
- **Completed Matches**: Count of finished matches

## Navigation Integration

### Home Screen Integration
- **Profile Button**: Added to home screen app bar
- **Quick Access**: One-tap navigation to user profile
- **Consistent Design**: Matches overall app design

### Navigation Flow
```
Home Screen
    ↓ (Profile Button)
User Profile Screen
    ├── My Matches Tab
    │   └── ProfileMatchCard (for each match)
    ├── My Tournaments Tab
    │   └── Tournament List (for each tournament)
    └── Quick Actions Tab
        ├── Create Individual Match
        ├── Create Tournament
        ├── Manage Players
        └── View Live Matches
```

## UI/UX Features

### 🎨 Design Elements
- **Gradient Header**: Beautiful gradient background with user avatar
- **Statistics Cards**: Visual representation of user activity
- **Tabbed Interface**: Organized content with smooth transitions
- **Card-Based Layout**: Clean, modern card design
- **Status Indicators**: Color-coded match status with icons

### 📱 User Experience
- **Loading States**: Proper loading indicators throughout
- **Empty States**: Helpful messages when no data is available
- **Error Handling**: User-friendly error messages
- **Pull-to-Refresh**: Easy data refresh functionality
- **Responsive Design**: Works on different screen sizes

### 🔍 Visual Hierarchy
- **Clear Status Indicators**: Easy to identify match status
- **Team Information**: Prominent team names and avatars
- **Match Details**: Organized information display
- **Action Buttons**: Clear call-to-action buttons

## Match Status System

### Status Types
- **Upcoming**: Blue color with schedule icon
- **Live**: Red color with live TV icon
- **Completed**: Green color with check circle icon
- **Cancelled**: Grey color with cancel icon

### Status Display
- Color-coded containers with borders
- Appropriate icons for each status
- Consistent styling across all cards

## Quick Actions

### Available Actions
1. **Create Individual Match**: Direct navigation to match creation
2. **Create Tournament**: Direct navigation to tournament creation
3. **Manage Players**: Access to player management system
4. **View Live Matches**: Return to home screen

### Action Card Design
- **Icon + Text Layout**: Clear visual representation
- **Color Coding**: Different colors for different actions
- **Hover Effects**: Interactive feedback
- **Consistent Styling**: Uniform design language

## Data Flow

### Loading Process
1. **User Authentication**: Verify user is logged in
2. **Data Fetching**: Load matches, tournaments, and stats
3. **UI Updates**: Update interface with loaded data
4. **Error Handling**: Handle any loading errors gracefully

### Refresh Process
1. **Pull-to-Refresh**: User initiates refresh
2. **Data Reload**: Fetch latest data from database
3. **UI Update**: Update interface with new data
4. **Feedback**: Show success/error feedback

## Error Handling

### Common Scenarios
- **Network Errors**: User-friendly retry options
- **Authentication Errors**: Redirect to login
- **Data Loading Errors**: Clear error messages
- **Empty States**: Helpful guidance for users

### User Feedback
- **Loading Indicators**: Progress feedback during operations
- **Error Messages**: Clear error descriptions
- **Success Feedback**: Confirmation of successful operations
- **Empty State Messages**: Guidance when no data is available

## Future Enhancements

### Planned Features
- [ ] Match editing capabilities
- [ ] Tournament management tools
- [ ] User settings and preferences
- [ ] Match statistics and analytics
- [ ] Social features (sharing matches)
- [ ] Export functionality

### Technical Improvements
- [ ] Caching for better performance
- [ ] Offline support
- [ ] Push notifications
- [ ] Advanced filtering options
- [ ] Search functionality
- [ ] Data synchronization

## Best Practices

### Code Organization
- **Separation of Concerns**: UI, business logic, and data layers
- **Reusable Components**: Modular widget design
- **Consistent Naming**: Clear, descriptive function and variable names
- **Error Boundaries**: Proper try-catch blocks

### Performance
- **Efficient Loading**: Load data only when needed
- **Memory Management**: Proper disposal of controllers
- **Optimized Rendering**: Efficient widget rebuilding
- **Lazy Loading**: Load content as needed

This user profile system provides a comprehensive view of user activity and easy access to all major functions, creating a central hub for users to manage their cricket scoring activities.
