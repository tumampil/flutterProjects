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
  bool _isFetchingMore = false;
  int _currentPage = 0;
  bool _hasMore = true; // True if there are still more posts to load from the server.
  String? _errorMessage; // Store errors to show in the UI.

  // 3. Simple ways for the UI to read our state.
  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  // REFRESH: Clear everything and load the first set of posts again.
  Future<void> fetchPosts() async {
    _isLoading = true; // Show loading spinner.
    _currentPage = 0;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedPosts = await _postService.getPosts(page: _currentPage);
      _posts = fetchedPosts;
      
      // If we got fewer than 10 posts, it means we reached the end of the list.
      if (fetchedPosts.length < 10) _hasMore = false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching posts: $e');
    } finally {
      _isLoading = false; // Hide loading spinner.
      notifyListeners();
    }
  }

  // LOAD MORE: This is called when you scroll to the bottom.
  Future<void> fetchMorePosts() async {
    // Stop if we are already loading or if there are no more posts to get.
    if (_isFetchingMore || !_hasMore) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      _currentPage++; // Go to the next page.
      final morePosts = await _postService.getPosts(page: _currentPage);
      
      if (morePosts.isEmpty) {
        _hasMore = false; // No more posts to load.
      } else {
        _posts.addAll(morePosts); // Add the new posts to our current list.
        if (morePosts.length < 10) _hasMore = false;
      }
    } catch (e) {
      debugPrint('Error fetching more posts: $e');
      _currentPage--; // Go back a page if it failed.
    } finally {
      _isFetchingMore = false;
      notifyListeners();
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
