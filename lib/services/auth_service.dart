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

  // SIGN UP: This creates a new account using an email and password.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    // We tell Supabase: "Please make a new user with this email and password."
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
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
