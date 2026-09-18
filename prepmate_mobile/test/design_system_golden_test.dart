import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/core/providers/theme_provider.dart';
import 'package:prepmate_mobile/features/auth/data/models/user_model.dart';
import 'package:prepmate_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:prepmate_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:prepmate_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:prepmate_mobile/features/profile/presentation/viewmodels/profile_viewmodel.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Poppins')
      ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-Bold.ttf'));
    await loader.load();
  });

  testWidgets('profile uses the shared dark design system', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith(
            (ref) => ProfileViewModel(_PreviewProfileRepository()),
          ),
          themeModeProvider.overrideWith((ref) => _PreviewThemeNotifier()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ProfileScreen),
      matchesGoldenFile('goldens/profile_after_dark.png'),
    );
  });
}

class _PreviewThemeNotifier extends ThemeModeNotifier {
  _PreviewThemeNotifier() : super(loadPersisted: false) {
    state = ThemeMode.dark;
  }
}

class _PreviewProfileRepository implements ProfileRepository {
  final user = UserModel(
    id: 'preview-user',
    email: 'alex.morgan@example.com',
    fullName: 'Alex Morgan',
    title: 'Product Designer',
    location: 'Colombo, Sri Lanka',
    skills: const ['Product design', 'Research'],
  );

  @override
  Future<UserModel> getProfile() async => user;

  @override
  Future<void> logout() async {}

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) async => user;

  @override
  Future<UserModel> uploadProfileImage(String filePath) async => user;
}
