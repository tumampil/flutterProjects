// FILE: post_provider.dart
// PURPOSE: This is the "Brain" for everything related to posts.
// It keeps a list of posts and handles loading more as you scroll down.

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';

class PostProvider extends ChangeNotifier {
  // 1. Use the PostService to talk to the database.
  final PostService _postService = PostService();

  // 2. Variables to store the current list of posts and loading status.
  List<Post> _posts = [];
  bool _isLoading = false;
  int _currentPage = 0;
  int _totalCount = 0;
  final int _pageSize = 5;
  String? _errorMessage;

  // 3. Simple ways for the UI to read our state.
  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int get totalCount => _totalCount;
  int get totalPages => (_totalCount / _pageSize).ceil();
  String? get errorMessage => _errorMessage;

  // FETCH: Get posts for a specific page (Google-style).
  Future<void> fetchPosts({int page = 0}) async {
    _isLoading = true;
    _currentPage = page;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _postService.getPosts(page: _currentPage, pageSize: _pageSize);
      _posts = result['posts'] as List<Post>;
      _totalCount = result['totalCount'] as int;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching posts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to jump to a specific page number.
  void goToPage(int page) {
    if (page >= 0 && page < totalPages) {
      fetchPosts(page: page);
    }
  }

  // CREATE NEW POST: Handle image uploads first, then save the post.
  // Returns true if successful, false if not.
  Future<bool> addPost(String userId, String content, List<XFile> images) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Upload the chosen images to the storage closet and get links.
      final imageUrls = await _postService.uploadPostImages(images, userId);
      
      // 2. Save the post content and those links to the database.
      await _postService.createPost(
        userId: userId,
        content: content,
        imageUrls: imageUrls,
      );
      
      // 3. Refresh the whole list so the new post appears at the top.
      await fetchPosts();
      return true; // Success!
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error adding post: $e');
      return false; // Failed
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // UPDATE POST: Change content and images.
  Future<bool> updatePost({
    required String postId,
    required String content,
    required List<String> imageUrls,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _postService.updatePost(
        postId: postId,
        content: content,
        imageUrls: imageUrls,
      );
      
      // Update local list
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        // We just refresh the whole list to be sure and get profile info joined.
        await fetchPosts();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error updating post: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // UPLOAD IMAGES HELPER: Expose the service upload to the UI.
  Future<List<String>> uploadPostImages(List<XFile> images, String userId) async {
    if (images.isEmpty) return [];
    return await _postService.uploadPostImages(images, userId);
  }

  // DELETE POST: Remove from database and then from our local list.
  Future<void> deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);
      
      // Remove it from the list we are currently showing.
      _posts.removeWhere((p) => p.id == postId);
      notifyListeners(); // Refresh the UI immediately.
    } catch (e) {
      debugPrint('Error deleting post: $e');
    }
  }
}
