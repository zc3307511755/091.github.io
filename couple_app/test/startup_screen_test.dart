import 'package:couple_app/screens/startup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows branding before opening the app', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StartupScreen(
          waitForAuthentication: false,
          destination: Scaffold(body: Text('destination')),
        ),
      ),
    );

    expect(find.text('我们俩'), findsOneWidget);
    expect(find.text('destination'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.text('destination'), findsNothing);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('destination'), findsOneWidget);
    expect(find.text('我们俩'), findsNothing);
  });
}
