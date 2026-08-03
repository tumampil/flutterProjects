// FILE: post_details_page.dart
// PURPOSE: This page shows one post in detail and all the comments written for it.
// It also has a box at the bottom to write a new comment.

import 'dart:typed_data'; // Add this for Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Import providers to get the post info and comments.
import '../provider/auth_provider.dart';
import '../provider/comment_provider.dart';
import '../provider/post_provider.dart';

class PostDetailsPage extends StatefulWidget {
  final String postId; // Each post has a unique ID number.
  const PostDetailsPage({super.key, required this.postId});

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

// A small helper to hold the image and its bytes for preview.
class SelectedCommentImage {
  final XFile file;
  final Uint8List bytes;
  SelectedCommentImage(this.file, this.bytes);
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  // 1. Controller for the comment's text.
  final TextEditingController _commentController = TextEditingController();
  
  // 2. A list for photos you want to attach to your comment.
  final List<SelectedCommentImage> _commentImages = [];
  
  // 3. Tool for picking photos from the gallery.
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 4. Load the comments for this post as soon as the page opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentProvider>().fetchComments(widget.postId);
    });
  }

  @override
  void dispose() {
    // 5. Cleanup the text box when we leave the page.
    _commentController.dispose();
    super.dispose();
  }

  // Runs when you click the "Send" icon.
  void _onAddComment() async {
    final content = _commentController.text.trim();
    final userId = context.read<AuthProvider>().user?.id;

    // Don't do anything if there's no text.
    if (content.isEmpty) return;

    if (userId != null) {
      // Tell the brain to save the comment.
      await context.read<CommentProvider>().addComment(
        postId: widget.postId,
        userId: userId,
        content: content,
        images: _commentImages.map((e) => e.file).toList(),
      );
      
      // Clear the inputs if it worked.
      setState(() {
        _commentController.clear();
        _commentImages.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 6. Look through all posts and find the one that matches our ID.
    // Use firstWhere with orElse to handle cases where post might be missing.
    final postProvider = context.watch<PostProvider>();
    final post = postProvider.posts.cast<dynamic>().firstWhere(
      (p) => p.id == widget.postId, 
      orElse: () => null,
    );
    
    // Watch for new comments and login status.
    final commentProvider = context.watch<CommentProvider>();
    final auth = context.watch<AuthProvider>();

    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post Details')),
        body: const Center(child: Text('Post not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: Column(
        children: [
          // THE SCROLLABLE CONTENT (Post + Comments)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // POST HEADER (Author and Date)
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: post.authorAvatar != null ? NetworkImage(post.authorAvatar!) : null,
                        child: post.authorAvatar == null ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.authorName ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(DateFormat.yMMMd().format(post.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const Spacer(),
                      // Show delete button only if YOU wrote this post.
                      if (auth.user?.id == post.authorId)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            context.read<PostProvider>().deletePost(post.id);
                            Navigator.of(context).pop(); // Go back after deleting.
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // THE POST TEXT
                  Text(post.content, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  
                  // THE POST PHOTOS
                  if (post.imageUrls.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: post.imageUrls.map<Widget>((url) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
                      )).toList(),
                    ),
                  
                  const Divider(height: 48),
                  const Text('Comments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // THE LIST OF COMMENTS
                  if (commentProvider.isLoading && commentProvider.comments.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(), // Important inside ScrollView.
                      itemCount: commentProvider.comments.length,
                      itemBuilder: (context, index) {
                        final comment = commentProvider.comments[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(backgroundImage: comment.authorAvatar != null ? NetworkImage(comment.authorAvatar!) : null),
                          title: Text(comment.authorName ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment.content),
                              // Comment photos (if any)
                              if (comment.imageUrls.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Wrap(
                                    spacing: 4,
                                    children: comment.imageUrls.map((url) => ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
                                    )).toList(),
                                  ),
                                ),
                            ],
                          ),
                          // Delete icon only for your own comments.
                          trailing: (auth.user?.id == comment.authorId)
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20), 
                                  onPressed: () => commentProvider.deleteComment(comment.id, post.id),
                                )
                              : null,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // COMMENT INPUT BAR (Sticky at the bottom)
          if (auth.user != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))]),
              child: Column(
                children: [
                  // Previews of photos you are about to upload.
                  if (_commentImages.isNotEmpty)
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _commentImages.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4), 
                                child: Image.memory(_commentImages[index].bytes, width: 60, height: 60, fit: BoxFit.cover),
                              ),
                              Positioned(right: 0, top: 0, child: GestureDetector(onTap: () => setState(() => _commentImages.removeAt(index)), child: Container(color: Colors.black54, child: const Icon(Icons.close, size: 16, color: Colors.white)))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      // Add Photo Button
                      IconButton(icon: const Icon(Icons.add_a_photo_outlined), onPressed: () async {
                        final picked = await _picker.pickMultiImage();
                        if (picked.isNotEmpty) {
                          for (var x in picked) {
                            final b = await x.readAsBytes();
                            setState(() => _commentImages.add(SelectedCommentImage(x, b)));
                          }
                        }
                      }),
                      // Text Box
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(hintText: 'Write a comment...', border: InputBorder.none),
                          maxLines: null,
                        ),
                      ),
                      // Send Icon
                      IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _onAddComment),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
