// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rtsp_photo_app/main.dart';
import 'package:rtsp_photo_app/providers/photo_provider.dart';
import 'package:rtsp_photo_app/providers/auth_provider.dart';

void main() {
  testWidgets('RTSP Photo App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => PhotoProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Wait for the app to fully load
    await tester.pumpAndSettle();
    
    // Verify that the app has loaded successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
