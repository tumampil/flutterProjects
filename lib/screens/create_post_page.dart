// FILE: create_post_page.dart
// PURPOSE: This is where you write the text and pick the photos for a new post.

import 'dart:typed_data'; // Add this for Uint8List
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// Import providers to get the user ID and save the post.
import '../provider/auth_provider.dart';
import '../provider/post_provider.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

// 0. A small helper class to hold both the file and its bytes for preview.
class SelectedImage {
  final XFile file;
  final Uint8List bytes;
  SelectedImage(this.file, this.bytes);
}

class _CreatePostPageState extends State<CreatePostPage> {
  // 1. Controller for the post's text.
  final TextEditingController _contentController = TextEditingController();
  
  // 2. A list to keep the images and their bytes for preview.
  final List<SelectedImage> _selectedImages = [];
  
  // 3. This tool helps us pick the photos.
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    // 4. Always clean up when leaving.
    _contentController.dispose();
    super.dispose();
  }

  // Runs when you click "Add Images."
  Future<void> _onPickImages() async {
    // Open the gallery to pick multiple photos.
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (var xfile in images) {
        final bytes = await xfile.readAsBytes();
        setState(() {
          _selectedImages.add(SelectedImage(xfile, bytes));
        });
      }
    }
  }

  // Runs when you click the "X" on a selected photo to remove it.
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Runs when you click the "Check" button at the top to submit.
  void _onSubmit() async {
    final content = _contentController.text.trim();
    final userId = context.read<AuthProvider>().user?.id;

    // Check if there is any text.
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post content cannot be empty')),
      );
      return;
    }

    if (userId != null) {
      final postProvider = context.read<PostProvider>();
      
      // 5. Tell the "Brain" to save. We now catch if it fails.
      final success = await postProvider.addPost(
        userId, 
        content, 
        _selectedImages.map((e) => e.file).toList(),
      );
      
      if (mounted) {
        if (success) {
          // Go back to the Home Page only if it worked.
          context.pop();
        } else {
          // Show the error message if it failed.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save: ${postProvider.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // See if the post is still being saved (loading).
    final isLoading = context.watch<PostProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post'),
        actions: [
          // Show a spinner if we are saving, otherwise show the Check icon.
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, size: 28),
              onPressed: _onSubmit,
              tooltip: 'Post Now',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // POST TEXT INPUT BOX
            TextField(
              controller: _contentController,
              maxLines: 8, // Allow up to 8 lines of text.
              decoration: const InputDecoration(
                hintText: "What's on your mind? Share your thoughts...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // ADD IMAGES BUTTON
            ElevatedButton.icon(
              onPressed: _onPickImages,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add Images'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),

            // IMAGE PREVIEW GRID
            if (_selectedImages.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Grid shouldn't scroll itself.
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Show 3 images per row.
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      // The photo preview (Uses Image.memory to work on Web & Mobile)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _selectedImages[index].bytes,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      // The "X" delete button on top of each preview
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8)),
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
