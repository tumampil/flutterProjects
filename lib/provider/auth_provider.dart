// FILE: auth_provider.dart
// PURPOSE: This is the "Brain" for everything related to the user.
// It keeps track of whether someone is logged in and tells the UI when to update.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  // 1. Use the AuthService to do the actual work of talking to Supabase.
  final AuthService _authService = AuthService();

  // 2. Variables to store the current state (info) of the user.
  User? _user;           // Stores the user if logged in, or null if not.
  bool _isLoading = false; // True when we are waiting for the internet.
  String? _errorMessage;   // Stores an error message if something goes wrong.

  // 3. Simple ways for the UI (Pages) to read our variables.
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 4. When the app first starts, check if the user was already logged in from before.
  AuthProvider() {
    _user = _authService.currentUser;
  }

  // SIGN UP: Try to make a new account with a username.
  Future<void> register(String email, String password, String username) async {
    _setLoading(true); // Tell the app to show a loading spinner.
    _clearError();     // Remove any old error messages.

    try {
      // Call the service to do the signup.
      final response = await _authService.signUp(
        email: email, 
        password: password,
        username: username,
      );
      _user = response.user; // If it worked, save the user info.
      notifyListeners();      // Tell all pages to update their look.
    } catch (e) {
      _setError(e.toString()); // If it failed, save the error to show the user.
    } finally {
      _setLoading(false); // Stop the loading spinner.
    }
  }

  // LOGIN: Try to sign in.
  Future<void> login(String email, String password) async {
    _setLoading(true); // Start loading.
    _clearError();     // Clear old errors.

    try {
      // Call the service to do the login.
      final response = await _authService.signIn(email: email, password: password);
      _user = response.user; // If correct, save the user info.
      notifyListeners();      // Refresh the UI.
    } catch (e) {
      _setError(e.toString()); // If wrong, show the error.
    } finally {
      _setLoading(false); // Stop loading.
    }
  }

  // LOGOUT: Sign out.
  Future<void> logout() async {
    await _authService.signOut(); // Tell Supabase we are leaving.
    _user = null;                 // Forget the user info.
    notifyListeners();            // Refresh the UI.
  }

  // --- HELPERS: These make it easier to update the brain ---

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // Tell the UI that loading started or stopped.
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners(); // Tell the UI to show the error message.
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners(); // Tell the UI to hide the error message.
  }
}
