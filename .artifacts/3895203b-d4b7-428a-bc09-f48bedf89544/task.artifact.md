# Task List - Blog/Forum App Improvements

## Phase 1: Registration & Identity
- [x] Add Username field to `RegisterPage` UI
- [x] Update `AuthProvider` to handle username
- [x] Update `AuthService` to create profile record on signup
- [x] Fix "cannot comment" issue for new accounts

## Phase 2: Post Module Enhancements
- [x] Add Edit/Delete buttons to `PostCard` in home feed
- [x] Implement Delete confirmation popup for Posts
- [x] Update `PostProvider` pagination to 5 posts per page
- [x] Move Post button in `CreatePostPage` below input field
- [x] Implement horizontally scrollable gallery for multiple images in `PostCard`

## Phase 3: Comment Module Enhancements
- [x] Add Edit/Delete buttons for comments in `PostDetailsPage`
- [x] Implement Delete confirmation popup for Comments
- [x] Move Send button below comment input field
- [x] Make comment images clickable for full-size viewing

## Phase 4: Image Viewing & UI Cleanup
- [x] Create `FullScreenImageViewer` utility widget
- [x] Make all images clickable in Posts and Comments
- [x] Delete `ProfilePage` and remove its route
- [x] Move Logout button to `HomePage` AppBar
- [x] Update UI to show Username (Full Name) and remove all avatars

## Phase 5: Verification & Final Deployment
- [ ] Verify Registration flow with automatic profile creation
- [ ] Verify Edit/Delete CRUD for both Posts and Comments
- [ ] Verify Pagination (5 posts per page)
- [ ] Verify Image gallery and full-screen view
- [ ] Final push to GitHub for auto-deployment
