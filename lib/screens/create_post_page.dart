// FILE: create_post_page.dart
// PURPOSE: This is where you write the text and pick the photos for a new post.

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/post.dart';

// Import providers to get the user ID and save the post.
import '../provider/auth_provider.dart';
import '../provider/post_provider.dart';

class CreatePostPage extends StatefulWidget {
  final Post? postToEdit; // If this is not null, we are in "Edit" mode.
  const CreatePostPage({super.key, this.postToEdit});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class SelectedImage {
  final XFile? file; // Can be null if it's an existing image (URL).
  final Uint8List? bytes; // Can be null for existing images.
  final String? url; // Only for existing images.
  
  SelectedImage({this.file, this.bytes, this.url});
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  final List<SelectedImage> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // If we are editing, pre-fill the text and images.
    if (widget.postToEdit != null) {
      _contentController.text = widget.postToEdit!.content;
      for (var url in widget.postToEdit!.imageUrls) {
        _selectedImages.add(SelectedImage(url: url));
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _onPickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (var xfile in images) {
        final bytes = await xfile.readAsBytes();
        setState(() {
          _selectedImages.add(SelectedImage(file: xfile, bytes: bytes));
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _onSubmit() async {
    final content = _contentController.text.trim();
    final userId = context.read<AuthProvider>().user?.id;

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post content cannot be empty')),
      );
      return;
    }

    if (userId != null) {
      final postProvider = context.read<PostProvider>();
      bool success = false;

      if (widget.postToEdit != null) {
        // UPDATE MODE
        // We separate new files from existing URLs.
        final newFiles = _selectedImages
            .where((e) => e.file != null)
            .map((e) => e.file!)
            .toList();
        
        final existingUrls = _selectedImages
            .where((e) => e.url != null)
            .map((e) => e.url!)
            .toList();

        // 1. Upload new images
        final newUrls = await postProvider.uploadPostImages(newFiles, userId);
        
        // 2. Combine with remaining old ones
        final totalUrls = [...existingUrls, ...newUrls];

        // 3. Update in database
        success = await postProvider.updatePost(
          postId: widget.postToEdit!.id,
          content: content,
          imageUrls: totalUrls,
        );
      } else {
        // CREATE MODE
        success = await postProvider.addPost(
          userId, 
          content, 
          _selectedImages.map((e) => e.file!).toList(),
        );
      }
      
      if (mounted) {
        if (success) {
          context.pop();
        } else {
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
    final isLoading = context.watch<PostProvider>().isLoading;
    final isEditing = widget.postToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Post' : 'Create New Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // POST TEXT INPUT BOX
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: "What's on your mind? Share your thoughts...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // SUBMIT BUTTON (Below input, right aligned)
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 150,
                height: 45,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _onSubmit,
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEditing ? 'Save Changes' : 'Post Now'),
                ),
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
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // IMAGE PREVIEW GRID
            if (_selectedImages.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  final img = _selectedImages[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: img.url != null
                            ? Image.network(img.url!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                            : Image.memory(img.bytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                      ),
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
