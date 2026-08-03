// FILE: profile_page.dart
// PURPOSE: This is the page where you can change your Name and Profile Photo.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Import providers to get the user ID and save profile info.
import '../provider/auth_provider.dart';
import '../provider/profile_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // 1.A box to hold the name you type.
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 2. Load the profile info as soon as this page opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // Stop if the user closed the page already.
      
      // Get the "Brains" (Providers) to find the user ID and load data.
      final authProvider = context.read<AuthProvider>();
      final profileProvider = context.read<ProfileProvider>();
      
      final userId = authProvider.user?.id;
      if (userId != null) {
        profileProvider.loadProfile(userId).then((_) {
          if (mounted) {
            // Put the user's current name into the input box.
            _nameController.text = profileProvider.fullName ?? '';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // 3. Clean up the input box when we leave the page.
    _nameController.dispose();
    super.dispose();
  }

  // This runs when you click the photo to change it.
  Future<void> _onPickImage() async {
    final ImagePicker picker = ImagePicker();
    // Open the phone's gallery to pick a photo.
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && mounted) {
      final authProvider = context.read<AuthProvider>();
      final profileProvider = context.read<ProfileProvider>();
      
      final userId = authProvider.user?.id;
      if (userId != null) {
        // Tell the brain to upload the new photo.
        await profileProvider.updateAvatar(userId, image);
      }
    }
  }

  // This runs when you click "Save Changes."
  void _onSaveName() async {
    final newName = _nameController.text.trim();
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final userId = authProvider.user?.id;

    if (newName.isNotEmpty && userId != null) {
      // Tell the brain to save the new name.
      await profileProvider.updateName(userId, newName);
      
      if (mounted) {
        // Show a "Success" message at the bottom of the screen.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for any changes in the profile data or user info.
    final profile = context.watch<ProfileProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      
      // Show a loading spinner if we are busy saving or loading.
      body: profile.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // PHOTO SECTION
                  GestureDetector(
                    onTap: _onPickImage, // Click the photo to change it.
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child: profile.avatarUrl == null
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap to change photo', style: TextStyle(color: Colors.blue)),
                  const SizedBox(height: 32),

                  // NAME INPUT BOX
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _onSaveName,
                      child: const Text('Save Changes'),
                    ),
                  ),
                  
                  const Divider(height: 64),

                  // LOGOUT BUTTON
                  TextButton.icon(
                    onPressed: () {
                      auth.logout(); // Tell the brain to sign out.
                      Navigator.of(context).pop(); // Go back to the Home page.
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ),
    );
  }
}
