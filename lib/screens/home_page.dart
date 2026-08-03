// FILE: home_page.dart
// PURPOSE: This is the main screen of the app. It shows the public list of forum posts.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// Import our "Brains" (Providers) to see if we are logged in and get posts.
import '../provider/auth_provider.dart';
import '../provider/post_provider.dart';
import '../widgets/post_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 1. This controller lets us "listen" to the user scrolling.
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // 2. Load the first set of posts as soon as the page opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PostProvider>().fetchPosts();
    });

    // 3. Watch for when the user reaches the bottom of the list.
    _scrollController.addListener(() {
      // If the user scrolls to 90% of the page, tell the brain to load more posts.
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
        if (!mounted) return;
        context.read<PostProvider>().fetchMorePosts();
      }
    });
  }

  @override
  void dispose() {
    // 4. Clean up the scroll controller when we leave the page.
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for login changes and new posts.
    final auth = context.watch<AuthProvider>();
    final postProvider = context.watch<PostProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum App'),
        actions: [
          // 5. If logged in, show the Logout button. If not, show the Login button.
          if (auth.user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => auth.logout(),
            )
          else
            TextButton(
              onPressed: () => context.push('/login'),
              child: const Text(
                'Login',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      
      // 6. Pull-to-refresh allows user to drag the list down to reload.
      body: RefreshIndicator(
        onRefresh: () => postProvider.fetchPosts(),
        child: postProvider.isLoading && postProvider.posts.isEmpty
            ? const Center(child: CircularProgressIndicator()) // First-time loader
            : postProvider.posts.isEmpty
                ? const Center(child: Text('No posts found. Be the first to post!'))
                : ListView.builder(
                    controller: _scrollController,
                    // We add 1 to the count if there are more posts to load (for the spinner).
                    itemCount: postProvider.posts.length + (postProvider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      
                      // 7. If this is the extra item at the bottom, show a spinner.
                      if (index == postProvider.posts.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      // 8. Show each individual post card.
                      final post = postProvider.posts[index];
                      return PostCard(
                        post: post,
                        onTap: () {
                          // 9. Go to the details page for this specific post.
                          context.push('/post/${post.id}');
                        },
                      );
                    },
                  ),
      ),
      
      // 10. The "+" button to make a new post.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Check if user is logged in first.
          if (auth.user != null) {
            context.push('/create-post');
          } else {
            // If not logged in, show a message and go to Login page.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please login to create a post')),
            );
            context.push('/login');
          }
        },
        tooltip: 'Create Post',
        child: const Icon(Icons.add),
      ),
    );
  }
}
