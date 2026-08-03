// FILE: comment.dart
// PURPOSE: This is the "Blueprint" for a comment on a post.
// It defines exactly what information every comment should have.

class Comment {
  // 1. A unique number for each comment.
  final String id;
  
  // 2. The ID of the post that this comment belongs to.
  final String postId;
  
  // 3. The ID of the user who wrote the comment.
  final String authorId;
  
  // 4. The author's name and profile photo (from the database).
  final String? authorName;
  final String? authorAvatar;
  
  // 5. The actual text written in the comment.
  final String content;
  
  // 6. A list of links for any images attached to the comment.
  final List<String> imageUrls;
  
  // 7. When the comment was posted.
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    this.authorName,
    this.authorAvatar,
    required this.content,
    required this.imageUrls,
    required this.createdAt,
  });

  // This function takes raw data (JSON) from the database and turns it into a real "Comment" object.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['post_id'],
      authorId: json['author_id'],
      
      // These come from joining the Comments table with the Profiles table.
      authorName: json['profile']?['full_name'],
      authorAvatar: json['profile']?['avatar_url'],
      
      content: json['content'] ?? '',
      
      // Convert database list into a Dart list of Strings.
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      
      // Turn the date string from the database into a real Dart Date.
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
