// FILE: profile_service.dart
// PURPOSE: This file handles saving the user's name and photo to Supabase.

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  // A shortcut to use the Supabase tools.
  final SupabaseClient _supabase = Supabase.instance.client;

  // FETCH: Get the user's info (name and photo link) from the database.
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await _supabase
        .from('profile')
        .select()
        .eq('id', userId)
        .single(); // We only want one profile.
    return response;
  }

  // UPDATE: Save a new name or a new photo link to the database.
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
  }) async {
    // A list of info to update.
    final Map<String, dynamic> updates = {
      'id': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    // Upsert means: Update the row if it exists, or create it if not.
    await _supabase.from('profile').upsert(updates);
  }

  // UPLOAD: Save the actual image file to Supabase's storage "closet."
  // We use XFile to support both Web and Mobile.
  Future<String> uploadAvatar(XFile imageFile, String userId) async {
    // Create a unique name for the photo.
    final String fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.png';
    
    // Get the bytes for the image (works on Web & Mobile).
    final bytes = await imageFile.readAsBytes();

    // Send the file to the 'avatars' storage bucket.
    await _supabase.storage.from('avatars').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true, contentType: 'image/png'),
        );

    // Get the public link for the photo so everyone can see it.
    final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
    return publicUrl;
  }
}
