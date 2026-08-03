// FILE: post_details_page.dart
// PURPOSE: This page shows one post in detail and all the comments written for it.
// It also has a box at the bottom to write or edit a comment.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Import providers to get the post info and comments.
import '../provider/auth_provider.dart';
import '../provider/comment_provider.dart';
import '../provider/post_provider.dart';
import '../models/comment.dart';
import '../widgets/full_screen_image_viewer.dart';

class PostDetailsPage extends StatefulWidget {
  final String postId;
  const PostDetailsPage({super.key, required this.postId});

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class SelectedCommentImage {
  final XFile? file;
  final Uint8List? bytes;
  final String? url;
  SelectedCommentImage({this.file, this.bytes, this.url});
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  final TextEditingController _commentController = TextEditingController();
  final List<SelectedCommentImage> _commentImages = [];
  final ImagePicker _picker = ImagePicker();
  
  // Track if we are currently editing a comment.
  Comment? _editingComment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentProvider>().fetchComments(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _onAddComment() async {
    final content = _commentController.text.trim();
    final userId = context.read<AuthProvider>().user?.id;

    if (content.isEmpty) return;

    if (userId != null) {
      final commentProvider = context.read<CommentProvider>();
      bool success = false;

      if (_editingComment != null) {
        // UPDATE COMMENT
        final newFiles = _commentImages.where((e) => e.file != null).map((e) => e.file!).toList();
        final existingUrls = _commentImages.where((e) => e.url != null).map((e) => e.url!).toList();
        
        final newUrls = await commentProvider.uploadCommentImages(newFiles, userId);
        success = await commentProvider.updateComment(
          commentId: _editingComment!.id,
          postId: widget.postId,
          content: content,
          imageUrls: [...existingUrls, ...newUrls],
        );
      } else {
        // ADD COMMENT
        success = await commentProvider.addComment(
          postId: widget.postId,
          userId: userId,
          content: content,
          images: _commentImages.map((e) => e.file!).toList(),
        );
      }
      
      if (success) {
        setState(() {
          _commentController.clear();
          _commentImages.clear();
          _editingComment = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${commentProvider.errorMessage}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onEditComment(Comment comment) {
    setState(() {
      _editingComment = comment;
      _commentController.text = comment.content;
      _commentImages.clear();
      for (var url in comment.imageUrls) {
        _commentImages.add(SelectedCommentImage(url: url));
      }
    });
  }

  void _showDeleteCommentConfirmation(Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<CommentProvider>().deleteComment(comment.id, widget.postId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    final post = postProvider.posts.cast<dynamic>().firstWhere(
      (p) => p.id == widget.postId, 
      orElse: () => null,
    );
    
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // POST HEADER
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blue, size: 30),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.authorName ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(DateFormat.yMMMd().format(post.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // POST TEXT
                  Text(post.content, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  
                  // POST PHOTOS (Horizontal scrollable)
                  if (post.imageUrls.isNotEmpty)
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: post.imageUrls.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageUrl: post.imageUrls[index]))),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(post.imageUrls[index], width: 280, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  const Divider(height: 48),
                  const Text('Comments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // LIST OF COMMENTS
                  if (commentProvider.isLoading && commentProvider.comments.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: commentProvider.comments.length,
                      itemBuilder: (context, index) {
                        final comment = commentProvider.comments[index];
                        final isOwnComment = auth.user?.id == comment.authorId;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, color: Colors.grey, size: 20),
                                    const SizedBox(width: 8),
                                    Text(comment.authorName ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    if (isOwnComment)
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                            onPressed: () => _onEditComment(comment),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            onPressed: () => _showDeleteCommentConfirmation(comment),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(comment.content),
                                if (comment.imageUrls.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Wrap(
                                      spacing: 4,
                                      children: comment.imageUrls.map((url) => GestureDetector(
                                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageUrl: url))),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
                                        ),
                                      )).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // COMMENT INPUT BAR
          if (auth.user != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_editingComment != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          const Text('Editing comment...', style: TextStyle(color: Colors.blue, fontSize: 12)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() {
                              _editingComment = null;
                              _commentController.clear();
                              _commentImages.clear();
                            }),
                            child: const Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_a_photo_outlined),
                        onPressed: () async {
                          final picked = await _picker.pickMultiImage();
                          if (picked.isNotEmpty) {
                            for (var x in picked) {
                              final b = await x.readAsBytes();
                              setState(() => _commentImages.add(SelectedCommentImage(file: x, bytes: b)));
                            }
                          }
                        },
                      ),
                      if (_commentImages.isNotEmpty)
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _commentImages.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4), 
                                      child: _commentImages[index].url != null
                                          ? Image.network(_commentImages[index].url!, width: 50, height: 50, fit: BoxFit.cover)
                                          : Image.memory(_commentImages[index].bytes!, width: 50, height: 50, fit: BoxFit.cover),
                                    ),
                                    Positioned(right: 0, top: 0, child: GestureDetector(onTap: () => setState(() => _commentImages.removeAt(index)), child: Container(color: Colors.black54, child: const Icon(Icons.close, size: 14, color: Colors.white)))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      ElevatedButton(
                        onPressed: commentProvider.isLoading ? null : _onAddComment,
                        child: commentProvider.isLoading
                            ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_editingComment != null ? 'Save' : 'Send'),
                      ),
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
