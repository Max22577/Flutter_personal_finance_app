import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fin/core/widgets/animated_empty_state.dart';


void main() {
  testWidgets('AnimatedEmptyChart displays message and rotates', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedEmptyChart(message: 'NO DATA'),
        ),
      ),
    );

    // Verify initial state
    expect(find.text('NO DATA'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Check for Rotation
    // Get the initial transform of the image
    Finder imageFinder = find.byType(Transform);
    Transform initialWidget = tester.widget(imageFinder.first);
    
    // Get the value at row 0, column 0 of the 4x4 matrix
    double initialEntry = initialWidget.transform.entry(0, 0);

    // Advance time by 1 second (halfway through the 2-second duration)
    await tester.pump(const Duration(seconds: 1));

    // Verify the transform has changed
    Transform updatedWidget = tester.widget(imageFinder.first);
    double updatedEntry = updatedWidget.transform.entry(0, 0);

    expect(initialEntry, isNot(equals(updatedEntry)));
  });

  testWidgets('Animation repeats indefinitely', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AnimatedEmptyChart(message: 'TEST')),
    );

    // Pump for 10 seconds to ensure it doesn't stop
    await tester.pump(const Duration(seconds: 10));
    
    // If the widget is still alive and didn't crash, it passed
    expect(find.byType(AnimatedEmptyChart), findsOneWidget);
  });
}