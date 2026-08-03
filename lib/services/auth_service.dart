// FILE: auth_service.dart
// PURPOSE: This file handles talking directly to Supabase about users (Login, Signup).
// It doesn't care about the UI, only about sending and receiving user data.

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // 1. A shortcut to reach the Supabase tools.
  final SupabaseClient _supabase = Supabase.instance.client;

  // 2. A simple way to check if someone is currently logged in.
  Session? get currentSession => _supabase.auth.currentSession;

  // 3. A simple way to get the logged-in user's info (like their email).
  User? get currentUser => _supabase.auth.currentUser;

  // SIGN UP: This creates a new account using an email, password, and username.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    // 1. Tell Supabase: "Please make a new user."
    // We add the username to 'data' so it's stored in the Auth system too.
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': username},
    );

    // 2. If it worked, we manually create a row in our 'profile' table.
    // This ensures the user can immediately start posting and commenting.
    if (response.user != null) {
      await _supabase.from('profile').upsert({
        'id': response.user!.id,
        'full_name': username,
      });
    }

    return response;
  }

  // LOGIN: This checks if the user's email and password are correct.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    // We tell Supabase: "Check if this person is allowed to enter."
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // LOGOUT: This tells the app the user is leaving.
  Future<void> signOut() async {
    // We tell Supabase: "The user is logging out now."
    await _supabase.auth.signOut();
  }
}
