// FILE: app_router.dart
// PURPOSE: This is like the "GPS" of the app. 
// It defines which screen to show based on the address (URL) you go to.

import 'package:go_router/go_router.dart';

// Import all the pages our app has.
import '../screens/home_page.dart';
import '../screens/login_page.dart';
import '../screens/register_page.dart';
import '../screens/profile_page.dart';
import '../screens/create_post_page.dart';
import '../screens/post_details_page.dart';

// This handles the navigation paths.
final GoRouter appRouter = GoRouter(
  // The first page shown when the app opens.
  initialLocation: '/',
  
  routes: [
    // HOME PAGE: The main forum list.
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const HomePage();
      },
    ),
    
    // LOGIN PAGE.
    GoRoute(
      path: '/login',
      builder: (context, state) {
        return const LoginPage();
      },
    ),
    
    // REGISTRATION PAGE.
    GoRoute(
      path: '/register',
      builder: (context, state) {
        return const RegisterPage();
      },
    ),

    // PROFILE PAGE: Where users edit their name/photo.
    GoRoute(
      path: '/profile',
      builder: (context, state) {
        return const ProfilePage();
      },
    ),

    // CREATE POST PAGE: Where you write a new post.
    GoRoute(
      path: '/create-post',
      builder: (context, state) {
        return const CreatePostPage();
      },
    ),

    // POST DETAILS PAGE: Shows one post and all its comments.
    // ':id' is a shortcut for the post's unique number.
    GoRoute(
      path: '/post/:id',
      builder: (context, state) {
        // Find which post the user clicked on by its ID.
        final postId = state.pathParameters['id']!;
        return PostDetailsPage(postId: postId);
      },
    ),
  ],
);
