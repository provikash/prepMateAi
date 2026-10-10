import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/core/responsive/responsive.dart';
import 'package:prepmate_mobile/core/widgets/adaptive_app_shell.dart';

void main() {
  test('breakpoints resolve at every boundary', () {
    expect(AppBreakpoints.resolve(390), AppLayoutSize.compact);
    expect(AppBreakpoints.resolve(599), AppLayoutSize.compact);
    expect(AppBreakpoints.resolve(600), AppLayoutSize.medium);
    expect(AppBreakpoints.resolve(1023), AppLayoutSize.medium);
    expect(AppBreakpoints.resolve(1024), AppLayoutSize.expanded);
    expect(AppBreakpoints.resolve(1439), AppLayoutSize.expanded);
    expect(AppBreakpoints.resolve(1440), AppLayoutSize.large);
  });

  test('responsive values inherit the nearest smaller value', () {
    const value = ResponsiveValue<int>(compact: 1, expanded: 3);
    expect(value.resolve(AppLayoutSize.compact), 1);
    expect(value.resolve(AppLayoutSize.medium), 1);
    expect(value.resolve(AppLayoutSize.expanded), 3);
    expect(value.resolve(AppLayoutSize.large), 3);
  });

  for (final size in <Size>[
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1024, 768),
    const Size(1366, 768),
    const Size(1440, 900),
    const Size(1920, 1080),
  ]) {
    testWidgets(
      'adaptive shell has no overflow at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AdaptiveAppShell(
              location: '/dashboard',
              child: Scaffold(body: Center(child: Text('Dashboard content'))),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Dashboard content'), findsOneWidget);
        if (size.width >= AppBreakpoints.compact) {
          expect(find.text('Dashboard'), findsWidgets);
        }
      },
    );
  }
}
