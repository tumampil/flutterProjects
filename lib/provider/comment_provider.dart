// FILE: comment_provider.dart
// PURPOSE: This is the "Brain" for comments on a specific post.
// It handles fetching and adding comments with images.

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';

class CommentProvider extends ChangeNotifier {
  // 1. Use the CommentService to talk to the database.
  final CommentService _commentService = CommentService();

  // 2. Variables to store the current comments and loading status.
  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _errorMessage;

  // 3. Simple ways for the UI to read our info.
  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // FETCH: Get all comments for a post when the page opens.
  Future<void> fetchComments(String postId) async {
    _isLoading = true; // Tell the UI to show a loader.
    _errorMessage = null;
    notifyListeners();

    try {
      _comments = await _commentService.getComments(postId);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching comments: $e');
    } finally {
      _isLoading = false; // Hide the loader.
      notifyListeners();
    }
  }

  // ADD: Upload images and save the comment text.
  Future<bool> addComment({
    required String postId,
    required String userId,
    required String content,
    required List<XFile> images,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Upload any attached images and get their links.
      final imageUrls = await _commentService.uploadCommentImages(images, userId);
      
      // 2. Save the comment text and links to the database.
      await _commentService.addComment(
        postId: postId,
        userId: userId,
        content: content,
        imageUrls: imageUrls,
      );
      
      // 3. Reload comments so the new one appears immediately.
      await fetchComments(postId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error adding comment: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // UPDATE: Edit an existing comment.
  Future<bool> updateComment({
    required String commentId,
    required String postId,
    required String content,
    required List<String> imageUrls,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _commentService.updateComment(
        commentId: commentId,
        content: content,
        imageUrls: imageUrls,
      );
      await fetchComments(postId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error updating comment: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // UPLOAD HELPER:
  Future<List<String>> uploadCommentImages(List<XFile> images, String userId) async {
    if (images.isEmpty) return [];
    return await _commentService.uploadCommentImages(images, userId);
  }

  // DELETE: Remove a comment and refresh the list.
  Future<void> deleteComment(String commentId, String postId) async {
    try {
      await _commentService.deleteComment(commentId);
      
      // Remove it from our local list immediately.
      _comments.removeWhere((c) => c.id == commentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting comment: $e');
    }
  }
}
