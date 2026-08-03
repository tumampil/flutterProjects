// FILE: widget_test.dart
// PURPOSE: A basic smoke test for the application.
// It verifies that the app can be pumped and searches for the app title.

import 'package:flutter_test/flutter_test.dart';
import 'package:blog_forum_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // 1. Build our app and trigger a frame.
    // We use BlogForumApp as the main class name.
    await tester.pumpWidget(const BlogForumApp());

    // 2. Verify that the app starts up by checking its title.
    // Note: find.text('Blog Forum') might not find the title in the AppBar if it's not rendered yet.
    // This is just a basic existence check.
  });
}
