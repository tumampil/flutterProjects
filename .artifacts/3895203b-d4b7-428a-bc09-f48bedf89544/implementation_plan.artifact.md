# Implementation Plan - Blog/Forum App Improvements

This plan outlines the steps to implement several feature requests and bug fixes for the Blog/Forum application, focusing on UX improvements, pagination, and registration flow.

## User Review Required

> [!IMPORTANT]
> **Registration Change**: We are adding a "Username" field. This username will be used as the display name throughout the app.
>
> **Profile Change**: As requested, the profile picture feature will be removed for now to prevent posting/commenting issues for users without an avatar.
>
> **Database Permission**: To fix the "cannot comment" issue, we will ensure every new user gets a matching entry in the `profile` table immediately upon registration.

## Proposed Changes

### 1. User Registration & Identity
- **[MODIFY] [RegisterPage](file:///D:/development/flutterProjects/lib/screens/register_page.dart)**: Add a `usernameController` and a new `TextField` for the Username.
- **[MODIFY] [AuthProvider](file:///D:/development/flutterProjects/lib/provider/auth_provider.dart)**: Update `register()` to accept `username`.
- **[MODIFY] [AuthService](file:///D:/development/flutterProjects/lib/services/auth_service.dart)**: After a successful `signUp`, automatically insert a new row into the `profile` table with the provided `username`. This fixes the "cannot comment" issue for new accounts.

### 2. Posts Module Enhancements
- **[MODIFY] [PostCard](file:///D:/development/flutterProjects/lib/widgets/post_card.dart)**:
    - Add **Edit** and **Delete** icons (visible only if the current user is the author).
    - Wrap images in a `GestureDetector` to open a full-size image viewer.
    - Implement a horizontally scrollable gallery for multiple images if they exist.
- **[MODIFY] [PostProvider](file:///D:/development/flutterProjects/lib/provider/post_provider.dart)**: Update default `pageSize` to **5**.
- **[MODIFY] [CreatePostPage](file:///D:/development/flutterProjects/lib/screens/create_post_page.dart)**:
    - Move the "Post Now" button from the AppBar to below the input field, aligned to the right.
    - Style it as a prominent `ElevatedButton`.

### 3. Comments Module Enhancements
- **[MODIFY] [PostDetailsPage](file:///D:/development/flutterProjects/lib/screens/post_details_page.dart)**:
    - Add **Edit** and **Delete** buttons for each comment (if the user is the author).
    - Implement a "Confirmation Popup" before deleting a comment.
    - Move the "Send" button below the comment input field for better visibility.
    - Make comment images clickable for full-size viewing.

### 4. Profile & UI Cleanup
- **[DELETE] [ProfilePage](file:///D:/development/flutterProjects/lib/screens/profile_page.dart)**: Remove this page entirely.
- **[MODIFY] [app_router.dart](file:///D:/development/flutterProjects/lib/router/app_router.dart)**: Remove the `/profile` route.
- **[MODIFY] [HomePage](file:///D:/development/flutterProjects/lib/screens/home_page.dart)**: Replace the Profile icon in the AppBar with a **Logout** icon button.
- **[MODIFY] [PostCard](file:///D:/development/flutterProjects/lib/widgets/post_card.dart)** & **[PostDetailsPage](file:///D:/development/flutterProjects/lib/screens/post_details_page.dart)**: Update the UI to show the `full_name` (Username) instead of the email address. Remove author avatars.

### 5. Utilities
- **[NEW] FullScreenImageViewer**: A small reusable widget or dialog to display an image in full size when clicked.

## Verification Plan

### Automated Tests
- No automated tests are configured yet, but we will verify all CRUD operations manually.

### Manual Verification
1.  **Registration**: Create a new account with a Username. Verify that the user can immediately post and comment.
2.  **Pagination**: Verify that only 5 posts load initially and more load on scroll.
3.  **Post CRUD**:
    - Check if Edit/Delete buttons appear on the home feed cards.
    - Verify the "Are you sure you want to delete this post?" popup.
4.  **Comment CRUD**:
    - Verify Edit/Delete buttons for comments.
    - Verify the "Are you sure you want to delete this comment?" popup.
5.  **Images**: Click images in posts/comments and ensure they open in full size.
6.  **Layout**: Ensure the Save/Post buttons are below the input boxes.
