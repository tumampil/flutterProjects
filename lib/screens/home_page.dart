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
  @override
  void initState() {
    super.initState();
    // Load the first page as soon as the app opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchPosts(page: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final postProvider = context.watch<PostProvider>();

    return Scaffold(
      app_bar: AppBar(
        title: const Text('Forum App'),
        actions: [
          if (auth.user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => auth.logout(),
            )
          else
            TextButton(
              onPressed: () => context.push('/login'),
              child: const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. THE LIST OF POSTS
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => postProvider.fetchPosts(page: postProvider.currentPage),
              child: postProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : postProvider.posts.isEmpty
                      ? const Center(child: Text('No posts found.'))
                      : ListView.builder(
                          itemCount: postProvider.posts.length,
                          itemBuilder: (context, index) {
                            final post = postProvider.posts[index];
                            return PostCard(
                              post: post,
                              onTap: () => context.push('/post/${post.id}'),
                            );
                          },
                        ),
            ),
          ),

          // 2. GOOGLE-STYLE PAGINATION (1 2 3 4 5...)
          if (postProvider.totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous Button
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: postProvider.currentPage > 0 
                          ? () => postProvider.goToPage(postProvider.currentPage - 1) 
                          : null,
                    ),
                    
                    // Page Numbers
                    ...List.generate(postProvider.totalPages, (index) {
                      final isSelected = index == postProvider.currentPage;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => postProvider.goToPage(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.blue,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Next Button
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: postProvider.currentPage < postProvider.totalPages - 1 
                          ? () => postProvider.goToPage(postProvider.currentPage + 1) 
                          : null,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (auth.user != null) {
            context.push('/create-post');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to post')));
            context.push('/login');
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
