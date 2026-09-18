import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/core/widgets/app_loading.dart';
import 'package:prepmate_mobile/core/widgets/app_button.dart';
import 'package:prepmate_mobile/core/widgets/app_state.dart';
import 'package:prepmate_mobile/config/page_transitions.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/features/courses/data/models/ai_course_model.dart';
import 'package:prepmate_mobile/features/auth/presentation/authWidgets/auth_shell.dart';

void main() {
  testWidgets('loading animation respects reduced motion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: AppLoading()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(AppLoading), findsOneWidget);
  });

  testWidgets('tab transition preserves the form when revisiting a tab', (
    tester,
  ) async {
    Widget page(bool active) => MaterialApp(
      home: Scaffold(
        body: TabEntrance(active: active, child: const TextField()),
      ),
    );
    await tester.pumpWidget(page(true));
    await tester.enterText(find.byType(TextField), 'My draft');
    await tester.pumpWidget(page(false));
    await tester.pumpWidget(page(true));
    await tester.pumpAndSettle();
    expect(find.text('My draft'), findsOneWidget);
  });

  test('course preserves playlist identity', () {
    final course = AICourse.fromJson({
      'video_id': 'abcdefghijk',
      'playlist_id': 'PLexample',
    });
    expect(course.playlistId, 'PLexample');
    expect(
      course.copyWith(title: 'Updated').toJson()['playlist_id'],
      'PLexample',
    );
  });

  testWidgets('semantic design colors are available in light and dark themes', (
    tester,
  ) async {
    Future<AppColors> colorsFor(ThemeData theme) async {
      late AppColors colors;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              colors = AppColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return colors;
    }

    final light = await colorsFor(AppTheme.lightTheme);
    final dark = await colorsFor(AppTheme.darkTheme);
    expect(light.primary, isNot(light.screenBackground));
    expect(light.error, isNot(light.success));
    expect(dark.cardBackground, isNot(dark.screenBackground));
    expect(dark.textPrimary, isNot(dark.textSecondary));
  });

  testWidgets('primary action disables interaction while loading', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppPrimaryButton(
            label: 'Save resume',
            loading: true,
            onPressed: () => presses++,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(AppPrimaryButton));
    expect(presses, 0);
    expect(find.byType(AppLoading), findsOneWidget);
  });

  testWidgets('shared empty and error states expose actions', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: AppErrorState(
          message: 'Please try again.',
          onAction: () => retried = true,
        ),
      ),
    );
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const AppEmptyState(
          title: 'No resumes yet',
          message: 'Your resumes will appear here.',
        ),
      ),
    );
    expect(find.text('No resumes yet'), findsOneWidget);
  });

  testWidgets('auth shell scrolls without overflow at 200 percent text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
          ),
          child: const AuthShell(
            title: 'Welcome back to your professional career companion',
            subtitle:
                'Sign in to continue building and improving your professional future.',
            showBack: false,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Email address'),
                ),
                SizedBox(height: AppSpacing.md),
                TextField(decoration: InputDecoration(labelText: 'Password')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
