import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventrack/main.dart';  // ✅ Based on error showing package:flutter_lib

 

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const RetailApp());

    // Verify that the role selection page loads
    expect(find.text('Choose Role'), findsOneWidget);
    
    // Verify that both role buttons are present
    expect(find.text('Shopkeeper'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    
    // Verify the icons are present
    expect(find.byIcon(Icons.storefront), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('Navigate to login page', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const RetailApp());

    // Tap the Shopkeeper button
    await tester.tap(find.text('Shopkeeper'));
    await tester.pumpAndSettle(); // Wait for navigation animation

    // Verify we're on the login page
    expect(find.text('Shopkeeper Login'), findsOneWidget);
    expect(find.text('Email / Mobile'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
