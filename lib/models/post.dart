// FILE: post.dart
// PURPOSE: This is the "Blueprint" for a blog post. 
// It tells the app exactly what info each post should have.

class Post {
  // 1. A unique number for each post.
  final String id;
  
  // 2. The ID of the person who wrote it.
  final String authorId;
  
  // 3. The name and photo of the author (from the database).
  final String? authorName;
  final String? authorAvatar;
  
  // 4. The actual words in the post.
  final String content;
  
  // 5. A list of links for any images in the post.
  final List<String> imageUrls;
  
  // 6. When the post was created.
  final DateTime createdAt;

  Post({
    required this.id,
    required this.authorId,
    this.authorName,
    this.authorAvatar,
    required this.content,
    required this.imageUrls,
    required this.createdAt,
  });

  // This function takes a row from the database (JSON) and turns it into a "Post" object.
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      authorId: json['author_id'],
      
      // These come from a different table (Profiles) that was joined with the Posts table.
      authorName: json['profile']?['full_name'],
      authorAvatar: json['profile']?['avatar_url'],
      
      content: json['content'] ?? '',
      
      // Convert the database list into a Dart list of Strings.
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      
      // Turn the date string from the database into a real Dart Date.
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
