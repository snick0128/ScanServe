import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scan_serve/app.dart';
import 'package:scan_serve/views/home_page.dart';

void main() {
  testWidgets('App should show home page with title', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const App());

    // Verify that the app's title is shown
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('App should have a material app with theme', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    
    // Verify the app uses MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Get the theme
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme, isNotNull);
    expect(materialApp.theme!.colorScheme.primary, const Color(0xFFFF6E40));
  });
}
