// FILE: login_page.dart
// PURPOSE: This is the page where users enter their email and password to log in.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../provider/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. Boxes to hold the text the user types (Email and Password).
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    // 2. Clean up these boxes when we leave this page to save memory.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // This runs when the "Login" button is clicked.
  void _onLoginPressed() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 3. Make sure the user didn't leave the boxes empty.
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password')),
      );
      return;
    }

    // 4. Tell the "Brain" (AuthProvider) to try to log in.
    await context.read<AuthProvider>().login(email, password);

    // 5. If login worked, move the user to the Home Page.
    if (mounted && context.read<AuthProvider>().user != null) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the "Brain" to see if we are currently loading or have an error.
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Name at the top
            const Text(
              'Blog/Forum App',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 48),

            // Email Input Box
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            // Password Input Box
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true, // This hides the password as you type
            ),
            const SizedBox(height: 24),

            // Show an error message in red if the login failed.
            if (authProvider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  authProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                ),
              ),

            // The Login Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                // Disable the button while we are waiting for the server.
                onPressed: authProvider.isLoading ? null : _onLoginPressed,
                child: authProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login', style: TextStyle(fontSize: 18)),
              ),
            ),
            
            const SizedBox(height: 16),

            // A link to go to the Signup/Register page.
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text("Don't have an account? Register now"),
            ),
          ],
        ),
      ),
    );
  }
}
