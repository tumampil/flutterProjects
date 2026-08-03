// FILE: comment_service.dart
// PURPOSE: This file handles all the hard work of saving and loading Comments from Supabase.

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment.dart';

class CommentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // FETCH: Get all comments for a specific post.
  Future<List<Comment>> getComments(String postId) async {
    final response = await _supabase
        .from('comments')
        .select('*, profile(full_name)') // Get profile info too.
        .eq('post_id', postId) // Only get comments for THIS post.
        .order('created_at', ascending: false); // Show newest comments first.

    return (response as List).map((json) => Comment.fromJson(json)).toList();
  }

  // CREATE: Save a new comment to the database.
  Future<void> addComment({
    required String postId,
    required String userId,
    required String content,
    required List<String> imageUrls,
  }) async {
    await _supabase.from('comments').insert({
      'post_id': postId,
      'author_id': userId,
      'content': content,
      'image_urls': imageUrls,
    });
  }

  // UPDATE: Change an existing comment.
  Future<void> updateComment({
    required String commentId,
    required String content,
    required List<String> imageUrls,
  }) async {
    await _supabase.from('comments').update({
      'content': content,
      'image_urls': imageUrls,
    }).eq('id', commentId);
  }

  // DELETE: Remove a comment from the database.
  Future<void> deleteComment(String commentId) async {
    await _supabase.from('comments').delete().eq('id', commentId);
  }

  // UPLOAD: Save multiple comment images and get their links.
  // We use XFile to support both Web and Mobile.
  Future<List<String>> uploadCommentImages(List<XFile> images, String userId) async {
    List<String> urls = [];
    for (var i = 0; i < images.length; i++) {
      final fileName = '$userId/comment_${DateTime.now().millisecondsSinceEpoch}_$i.png';
      
      // Get the bytes for the image (works on Web & Mobile).
      final bytes = await images[i].readAsBytes();

      // Upload to the 'comment_images' storage bucket.
      await _supabase.storage.from('comment_images').uploadBinary(
        fileName, 
        bytes,
        fileOptions: const FileOptions(contentType: 'image/png'),
      );
      
      // Get the link for the photo.
      urls.add(_supabase.storage.from('comment_images').getPublicUrl(fileName));
    }
    return urls;
  }
}
