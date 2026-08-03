# Project Architecture & Development Guide

This document explains the structure of the Blog/Forum app and the step-by-step process used to build it. Every file in the `lib` folder has been commented line-by-line to help you learn as you read the code.

## 📁 Folder Purposes

### 1. `lib/models/`
**Purpose**: Data Definitions.
Before we can save a "Post" to a database, we must define what a "Post" is. These files contain Dart classes that act as templates. They also include `fromJson` methods to convert the raw data we get from Supabase into objects our app understands.
- [post.dart](file:///D:/development/flutterProjects/lib/models/post.dart)
- [comment.dart](file:///D:/development/flutterProjects/lib/models/comment.dart)

### 2. `lib/services/`
**Purpose**: The "External Communicators."
These files contain the logic for talking to Supabase. They don't know anything about the UI (buttons or colors); they only care about sending and receiving data. This separation makes the code easier to test and fix.
- [auth_service.dart](file:///D:/development/flutterProjects/lib/services/auth_service.dart)
- [post_service.dart](file:///D:/development/flutterProjects/lib/services/post_service.dart)
- [profile_service.dart](file:///D:/development/flutterProjects/lib/services/profile_service.dart)
- [comment_service.dart](file:///D:/development/flutterProjects/lib/services/comment_service.dart)

### 3. `lib/provider/`
**Purpose**: State Management (The App's Brain).
Providers sit between your UI and your Services. When a user clicks "Login," the UI tells the Provider, the Provider tells the Service, and when the Service gets a response, the Provider tells the UI to rebuild (e.g., hide the loading spinner).
- [auth_provider.dart](file:///D:/development/flutterProjects/lib/provider/auth_provider.dart)
- [post_provider.dart](file:///D:/development/flutterProjects/lib/provider/post_provider.dart)
- [profile_provider.dart](file:///D:/development/flutterProjects/lib/provider/profile_provider.dart)
- [comment_provider.dart](file:///D:/development/flutterProjects/lib/provider/comment_provider.dart)

### 4. `lib/screens/`
**Purpose**: The User Interface.
These are the full pages of your app. They "watch" the Providers for changes and display the data to the user.
- [home_page.dart](file:///D:/development/flutterProjects/lib/screens/home_page.dart)
- [login_page.dart](file:///D:/development/flutterProjects/lib/screens/login_page.dart)
- [register_page.dart](file:///D:/development/flutterProjects/lib/screens/register_page.dart)
- [profile_page.dart](file:///D:/development/flutterProjects/lib/screens/profile_page.dart)
- [create_post_page.dart](file:///D:/development/flutterProjects/lib/screens/create_post_page.dart)
- [post_details_page.dart](file:///D:/development/flutterProjects/lib/screens/post_details_page.dart)

---

## 🏗️ Step-by-Step Development Order

### Step 1: Foundation (The Skeleton)
**Files**: `pubspec.yaml`, `main.dart`, `router/app_router.dart`
**Why**: We started here to install our "tools" (Supabase, Provider, GoRouter) and set up the basic navigation. Without this, we can't move between screens.

### Step 2: Identity (Authentication)
**Files**: `auth_service.dart`, `auth_provider.dart`, `login_page.dart`, `register_page.dart`
**Why**: Almost everything in a forum app (posting, commenting, liking) requires a user account. By building this first, we ensured that for the rest of the development, we always had a "Logged In" user to work with.

### Step 3: User Details (Profile)
**Files**: `profile_service.dart`, `profile_provider.dart`, `profile_page.dart`
**Why**: This is the simplest form of database storage (one row per user). It allowed us to test if our Supabase connection and Storage (for photos) were working correctly before moving to more complex features.

### Step 4: The Core Feature (Posts)
**Files**: `post.dart`, `post_service.dart`, `post_provider.dart`, `home_page.dart`, `create_post_page.dart`
**Why**: This is the heart of the app. We implemented the ability to see a list of posts, create new ones with multiple images, and delete them. We also added "Infinite Scrolling" here.

### Step 5: Engagement (Comments)
**Files**: `comment.dart`, `comment_service.dart`, `comment_provider.dart`, `post_details_page.dart`
**Why**: Comments are a sub-feature of posts. You can't comment on something that doesn't exist. We built this last to complete the social experience of the forum.

---

## 📝 Line-by-Line Guidance
Every line of code in the project includes a comment above it. For example, in the **AuthProvider**:
```dart
  Future<void> login(String email, String password) async {
    _setLoading(true); // 1. Tell the UI to show a loading spinner
    _clearError();     // 2. Remove any old error messages from the screen

    try {
      // 3. Try to authenticate with Supabase using the email/password
      final response = await _authService.signIn(email: email, password: password);
      _user = response.user; // 4. Save the logged-in user to memory
      notifyListeners();      // 5. Tell every screen in the app to rebuild
    } catch (e) {
      _setError(e.toString()); // 6. If it fails, capture the error to show the user
    } finally {
      _setLoading(false); // 7. Stop the loading spinner regardless of success or failure
    }
  }
```

> [!TIP]
> **Learning Strategy**: Start by reading the `models` to see how data is structured, then the `services` to see how we talk to the internet, then the `providers` to see the logic, and finally the `screens` to see the UI.
