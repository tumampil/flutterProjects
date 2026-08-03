// FILE: profile_provider.dart
// PURPOSE: This is the "Brain" for the user's profile info (Name and Photo).

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  // 1. Use the ProfileService to talk to the database.
  final ProfileService _profileService = ProfileService();

  // 2. Variables to store the user's profile info.
  String? _fullName;
  String? _avatarUrl;
  bool _isLoading = false;

  // 3. Simple ways for the UI to read our info.
  String? get fullName => _fullName;
  String? get avatarUrl => _avatarUrl;
  bool get isLoading => _isLoading;

  // FETCH: Get the user's info from the database.
  Future<void> loadProfile(String userId) async {
    _isLoading = true; // Tell the UI to show a loading spinner.
    notifyListeners();

    try {
      final profile = await _profileService.getProfile(userId);
      if (profile != null) {
        _fullName = profile['full_name'];
        _avatarUrl = profile['avatar_url'];
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      _isLoading = false; // Stop the loading spinner.
      notifyListeners();
    }
  }

  // UPDATE NAME: Save a new name to the database.
  Future<void> updateName(String userId, String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _profileService.updateProfile(userId: userId, fullName: name);
      _fullName = name; // Update the brain with the new name.
    } catch (e) {
      debugPrint('Error updating name: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // UPDATE PHOTO: Upload a new photo and save its link.
  Future<void> updateAvatar(String userId, XFile imageFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Upload the image file to the storage closet.
      final newUrl = await _profileService.uploadAvatar(imageFile, userId);
      
      // 2. Save the new link in the database table.
      await _profileService.updateProfile(userId: userId, avatarUrl: newUrl);
      
      _avatarUrl = newUrl; // Update the brain with the new photo link.
    } catch (e) {
      debugPrint('Error updating avatar: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
