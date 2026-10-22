import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yatraki_mobile/theme/app_theme.dart';

void main() {
  testWidgets('The Locals basic app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        title: 'THE LOCALS',
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: Text('THE LOCALS'),
          ),
        ),
      ),
    );
    expect(find.text('THE LOCALS'), findsOneWidget);
  });
}

