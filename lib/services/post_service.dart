// FILE: post_service.dart
// PURPOSE: This file handles all the hard work of saving and loading Posts from Supabase.

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';

class PostService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // FETCH: Get a list of posts and the total count for pagination.
  Future<Map<String, dynamic>> getPosts({int page = 0, int pageSize = 5}) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    // 1. Get the actual posts
    final postsResponse = await _supabase
        .from('posts')
        .select('*, profile(full_name)')
        .order('created_at', ascending: false)
        .range(from, to);

    // 2. Get the total count for pagination
    // head: true means we only want the count, not the data.
    final countResponse = await _supabase
        .from('posts')
        .select('id')
        .order('created_at', ascending: false);
    
    final totalCount = countResponse.length;

    return {
      'posts': (postsResponse as List).map((json) => Post.fromJson(json)).toList(),
      'totalCount': totalCount,
    };
  }

  // CREATE: Save a new post to the database.
  Future<void> createPost({
    required String userId,
    required String content,
    required List<String> imageUrls,
  }) async {
    await _supabase.from('posts').insert({
      'author_id': userId,
      'content': content,
      'image_urls': imageUrls,
    });
  }

  // UPDATE: Change the content of an existing post.
  Future<void> updatePost({
    required String postId,
    required String content,
    required List<String> imageUrls,
  }) async {
    await _supabase.from('posts').update({
      'content': content,
      'image_urls': imageUrls,
    }).eq('id', postId); // Match the post ID.
  }

  // DELETE: Remove a post from the database.
  Future<void> deletePost(String postId) async {
    await _supabase.from('posts').delete().eq('id', postId);
  }

  // UPLOAD: Save multiple image files to the storage closet and get their links.
  // We use XFile to support both Web and Mobile.
  Future<List<String>> uploadPostImages(List<XFile> images, String userId) async {
    List<String> urls = [];
    
    for (var i = 0; i < images.length; i++) {
      // Create a unique name for each image.
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}_$i.png';
      
      // Get the bytes for the image (works on Web & Mobile).
      final bytes = await images[i].readAsBytes();

      // Upload to the 'post_images' storage bucket.
      await _supabase.storage.from('post_images').uploadBinary(
        fileName, 
        bytes,
        fileOptions: const FileOptions(contentType: 'image/png'),
      );
      
      // Get the link for the photo.
      final publicUrl = _supabase.storage.from('post_images').getPublicUrl(fileName);
      urls.add(publicUrl);
    }
    
    return urls;
  }
}
