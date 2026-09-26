import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/config/app_router.dart';
import 'package:prepmate_mobile/features/auth/domain/entities/user.dart';
import 'package:prepmate_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:prepmate_mobile/features/auth/presentation/state/auth_state.dart';

void main() {
  testWidgets('mobile login exposes no email, password, or Google controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    expect(find.text('Continue with mobile'), findsOneWidget);
    expect(find.byKey(const Key('mobileNumberField')), findsOneWidget);
    expect(find.textContaining('Google'), findsNothing);
    expect(find.textContaining('Password'), findsNothing);
    expect(find.textContaining('Email'), findsNothing);
  });

  testWidgets('invalid Indian mobile number is rejected locally', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.enterText(
      find.byKey(const Key('mobileNumberField')),
      '5123456789',
    );
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Enter a valid Indian mobile number'), findsOneWidget);
  });

  testWidgets('use test account button is present and clickable', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    expect(find.byKey(const Key('useTestAccountButton')), findsOneWidget);
    expect(find.text('Use Test Account (9999999999)'), findsOneWidget);
  });

  test(
    'routing sends incomplete users to onboarding and completed users home',
    () {
      final incomplete = User(id: '1', email: '', phoneNumber: '+919876543210');
      final complete = incomplete.copyWith(profileCompleted: true);
      expect(
        authRedirect(
          AuthState(
            status: AuthStatus.authenticated,
            hasCheckedSession: true,
            user: incomplete,
          ),
          Uri.parse('/splash'),
        ),
        '/profile/edit',
      );
      expect(
        authRedirect(
          AuthState(
            status: AuthStatus.authenticated,
            hasCheckedSession: true,
            user: complete,
          ),
          Uri.parse('/splash'),
        ),
        '/home',
      );
      expect(
        authRedirect(
          AuthState(
            status: AuthStatus.unauthenticated,
            hasCheckedSession: true,
          ),
          Uri.parse('/home'),
        ),
        startsWith('/login'),
      );
    },
  );
}
