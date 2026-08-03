// FILE: main.dart
// PURPOSE: This is the starting point of the whole app. 
// It sets up the database (Supabase) and prepares the app's "brain" (Providers).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import our "Brains" (Providers) that hold our app data
import 'provider/post_provider.dart';
import 'provider/auth_provider.dart';
import 'provider/comment_provider.dart';

// Import our "GPS" (Router) that knows how to move between pages
import 'router/app_router.dart';

// This is the very first function that runs when you open the app
void main() async {
  // 1. Tell Flutter to get ready.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Try to connect to Supabase.
  // We use try-catch so that even if the internet or keys are wrong, the app still opens.
  try {
    await Supabase.initialize(
      url: 'https://uxzhxlnferekpnwmagsv.supabase.co',
      anonKey: 'sb_publishable_DCV0WFigPH1lPIIv0G2WsA_fpFqIiin',
    );
  } catch (e) {
    // If it fails, we print the error to the console so you can see it.
    debugPrint('Supabase Error: $e');
  }

  // 3. Start the application
  runApp(
    // MultiProvider is like a big box that holds all the "Brains" (Providers) of the app.
    // This makes sure every page can access the data it needs.
    MultiProvider(
      providers: [
        // This holds everything about the user (login, signup)
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // This holds all the posts and helps with loading them
        ChangeNotifierProvider(create: (_) => PostProvider()),

        // This holds the comments for the posts
        ChangeNotifierProvider(create: (_) => CommentProvider()),
      ],
      // This is the actual App widget
      child: const BlogForumApp(),
    ),
  );
}

// This is the root of the app that defines the look and navigation
class BlogForumApp extends StatelessWidget {
  const BlogForumApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp.router is used because we are using 'go_router' to move between pages.
    return MaterialApp.router(
      // Hides the small "Debug" tag in the corner of the screen
      debugShowCheckedModeBanner: false,
      
      // The name of the app
      title: 'Blog Forum',

      // Define the colors of the app
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      
      // Tell the app to use our GPS (Router) from app_router.dart
      routerConfig: appRouter,
    );
  }
}
