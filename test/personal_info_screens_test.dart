import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/features/auth/data/models/user_model.dart';
import 'package:prepmate_mobile/features/profile/domain/entities/profile_lifecycle_models.dart';
import 'package:prepmate_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:prepmate_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:prepmate_mobile/features/profile/presentation/screens/personal_info_screen.dart';
import 'package:prepmate_mobile/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:prepmate_mobile/features/profile/presentation/widgets/personal_info_modal_sheets.dart';
import 'package:prepmate_mobile/features/profile/presentation/widgets/personal_info_edge_state_sheets.dart';

class MockProfileRepository implements ProfileRepository {
  UserModel currentUser;
  ProfileMetadata metadata;
  bool shouldThrowConflict = false;
  Map<String, dynamic>? lastUpdatedData;
  List<String>? lastCascadedIds;

  MockProfileRepository({
    required this.currentUser,
    ProfileMetadata? metadata,
  }) : metadata = metadata ??
            const ProfileMetadata(
              countries: [
                CountryOption(
                    code: 'US',
                    name: 'United States',
                    dialCode: '+1',
                    flag: '🇺🇸'),
                CountryOption(
                    code: 'CA',
                    name: 'Canada',
                    dialCode: '+1',
                    flag: '🇨🇦'),
                CountryOption(
                    code: 'GB',
                    name: 'United Kingdom',
                    dialCode: '+44',
                    flag: '🇬🇧'),
                CountryOption(
                    code: 'IN',
                    name: 'India',
                    dialCode: '+91',
                    flag: '🇮🇳'),
              ],
              industries: [
                IndustryOption(
                    name: 'Technology & Software',
                    category: 'Technology'),
                IndustryOption(
                    name: 'Finance & Banking',
                    category: 'Finance'),
                IndustryOption(
                    name: 'Healthcare & Life Sciences',
                    category: 'Healthcare'),
              ],
              timeZones: [
                TimeZoneOption(
                    id: 'utc_m5',
                    name: 'Central Time · UTC-05:00'),
                TimeZoneOption(
                    id: 'utc_0',
                    name: 'UTC · UTC+00:00'),
              ],
            );

  @override
  Future<UserModel> getProfile() async => currentUser;

  @override
  Stream<CachedValue<UserModel>> watchProfile() => Stream.value(
        CachedValue(
            value: currentUser,
            isOffline: false,
            isStale: false,
            updatedAt: DateTime.now()),
      );

  @override
  Future<UserModel> refreshProfile() async => currentUser;

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    lastUpdatedData = data;
    if (shouldThrowConflict) {
      throw const ProfileConflictException(
        message: 'Conflict detected: profile updated on another device.',
        serverVersion: 2,
        serverData: {
          'id': 'user-1',
          'email': 'alex@example.com',
          'full_name': 'Server Alex Morgan',
          'job_title': 'Staff Platform Architect',
          'location': 'Austin, TX',
          'version': 2,
        },
      );
    }
    currentUser = currentUser.copyWith(
      fullName: data['full_name'] as String? ?? currentUser.fullName,
      preferredName:
          data['preferred_name'] as String? ?? currentUser.preferredName,
      title: data['job_title'] as String? ?? currentUser.title,
      city: data['city'] as String? ?? currentUser.city,
      stateRegion:
          data['state_region'] as String? ?? currentUser.stateRegion,
      country: data['country'] as String? ?? currentUser.country,
      industry: data['industry'] as String? ?? currentUser.industry,
      linkedin: data['linkedin'] as String? ?? currentUser.linkedin,
      github: data['github'] as String? ?? currentUser.github,
      portfolioUrl:
          data['portfolio_url'] as String? ?? currentUser.portfolioUrl,
      version: currentUser.version + 1,
    );
    return currentUser;
  }

  @override
  Future<UserModel> uploadProfileImage(String filePath) async {
    currentUser = currentUser.copyWith(
        profileImage: 'https://cdn.prepmate.ai/avatars/new.png');
    return currentUser;
  }

  @override
  Future<UserModel> deleteProfileImage() async {
    currentUser = currentUser.copyWith(profileImage: '');
    return currentUser;
  }

  @override
  Future<ProfileMetadata> getMetadata() async => metadata;

  @override
  Future<CascadeResumesResult> cascadeResumes(List<String> resumeIds,
      {List<String> fields = const ['job_title', 'location']}) async {
    lastCascadedIds = resumeIds;
    return CascadeResumesResult(
      updatedCount: resumeIds.length,
      message: 'Cascaded to ${resumeIds.length} resumes',
      resumes:
          resumeIds.map((id) => {'id': id, 'title': 'Resume $id'}).toList(),
    );
  }

  @override
  Future<Map<String, dynamic>> requestPhoneChange(String newPhoneNumber) async {
    return {
      'message': 'OTP sent to $newPhoneNumber',
      'challenge_id': 'chal_12345',
      'expires_in': 300,
    };
  }

  @override
  Future<Map<String, dynamic>> verifyPhoneChange(
      String newPhoneNumber, String challengeId, String otp) async {
    currentUser = currentUser.copyWith(
      phoneNumber: newPhoneNumber,
      verifiedPhone: newPhoneNumber,
      isPhoneVerified: true,
    );
    return {
      'message': 'Phone number updated successfully',
      'verified_phone': newPhoneNumber,
    };
  }

  @override
  Future<UserModel> completeOnboarding() async => currentUser;

  @override
  Future<void> logout() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserModel _createTestUser({
  String fullName = 'Alex Morgan',
  String? preferredName = 'Alex',
  String? title = 'Senior Systems Architect',
  String? location = 'San Francisco, CA',
  String? city = 'San Francisco',
  String? stateRegion = 'CA',
  String? country = 'United States',
  String? industry = 'Technology & Software',
  String? linkedin = 'https://linkedin.com/in/alexmorgan',
  String? github = 'https://github.com/alexmorgan',
  String? portfolioUrl = 'https://alexmorgan.dev',
  String? verifiedPhone = '+1 ••••• 8921',
  bool isPhoneVerified = true,
  String? verifiedEmail = 'alex.morgan@example.com',
  bool isEmailVerified = true,
  int completenessPercentage = 85,
  List<String> missingRecommendedFields = const ['custom_links'],
}) {
  return UserModel(
    id: 'user-1',
    email: 'alex.morgan@example.com',
    fullName: fullName,
    preferredName: preferredName,
    title: title,
    location: location,
    city: city,
    stateRegion: stateRegion,
    country: country,
    countryCode: 'US',
    industry: industry,
    linkedin: linkedin,
    github: github,
    portfolioUrl: portfolioUrl,
    verifiedPhone: verifiedPhone,
    phoneNumber: '+14155558921',
    isPhoneVerified: isPhoneVerified,
    verifiedEmail: verifiedEmail,
    isEmailVerified: isEmailVerified,
    completenessPercentage: completenessPercentage,
    missingRecommendedFields: missingRecommendedFields,
    version: 1,
  );
}

Widget _buildTestApp({
  required MockProfileRepository repository,
  Widget? home,
}) {
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(repository),
      profileProvider.overrideWith(
        (ref) => ProfileViewModel(repository)..loadProfile(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: home ?? const PersonalInfoScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Screen 81: Personal Information Editor', () {
    testWidgets('Renders all sections, header, and populated fields',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockProfileRepository(currentUser: _createTestUser());

      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      // Verify Header and sync indicator
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('All Changes Saved'), findsOneWidget);
      expect(find.text('Profile Auto-Sync Active'), findsOneWidget);

      // Verify Basic Details section
      expect(find.text('Basic details'), findsOneWidget);
      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(find.text('Senior Systems Architect'), findsOneWidget);
      expect(find.text('San Francisco'), findsOneWidget);
      expect(find.text('United States'), findsOneWidget);

      // Verify Verified Contacts Card
      expect(find.text('Verified contact'), findsOneWidget);
      expect(find.textContaining('••••• 8921'), findsOneWidget);
      expect(find.text('Verified'), findsWidgets);

      // Verify Social Links
      expect(find.text('Social & professional links'), findsOneWidget);
      expect(find.text('https://linkedin.com/in/alexmorgan'), findsOneWidget);
      expect(find.text('https://github.com/alexmorgan'), findsOneWidget);

      // Verify Resume Defaults Card
      expect(find.text('Defaults for new resumes'), findsOneWidget);

      // Drag to reveal Private Profile Vault
      await tester.drag(find.byType(ListView).last, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('Private Profile Vault'), findsOneWidget);

      // Verify Sticky Bottom Bar
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets(
        'Security contacts are read-only and phone change action routes',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockProfileRepository(currentUser: _createTestUser());

      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      // Mobile number has a dedicated Change button
      final changePhoneBtn = find.text('Change');
      expect(changePhoneBtn, findsOneWidget);

      await tester.tap(changePhoneBtn);
      await tester.pumpAndSettle();

      // Expect ChangePhoneModal to open
      expect(find.text('Change Mobile Number'), findsOneWidget);
      expect(find.text('Send Verification Code'), findsOneWidget);
    });

    testWidgets('Social links allow adding custom link with validation',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockProfileRepository(currentUser: _createTestUser());

      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      // Initially, 0 custom links
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      // Tap Add Custom Link
      final addLinkBtn = find.text('Add Custom Link');
      expect(addLinkBtn, findsOneWidget);
      await tester.tap(addLinkBtn);
      await tester.pumpAndSettle();

      // Enter details in dialog
      final dialogFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(dialogFields.first, 'Behance');
      await tester.enterText(dialogFields.last, 'https://behance.net/alex');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Now 1 custom link with close/remove button
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap remove on the newly added custom link
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });
  });

  group('Screen 82: Validation and Incomplete States', () {
    testWidgets('State switcher pill 2 switches to Errors and shows banner',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockProfileRepository(currentUser: _createTestUser());

      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      // Tap pill 2. Errors
      final errorPill = find.text('2. Errors');
      await tester.ensureVisible(errorPill);
      await tester.tap(errorPill);
      await tester.pumpAndSettle();

      expect(find.text('Please fix issues before saving'), findsOneWidget);
      expect(find.text('Action required'), findsOneWidget);
    });

    testWidgets('State switcher pill 3 displays Incomplete profile card',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final incompleteUser = _createTestUser(
        completenessPercentage: 65,
        missingRecommendedFields: ['portfolio_url', 'custom_links'],
      );
      final repo = MockProfileRepository(currentUser: incompleteUser);

      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      // Tap pill 3. Incomplete
      final incompletePill = find.text('3. Incomplete');
      await tester.ensureVisible(incompletePill);
      await tester.tap(incompletePill);
      await tester.pumpAndSettle();

      expect(find.text('Profile is 65% complete'), findsOneWidget);
    });
  });

  group('Screen 83: Selection and Modal Sheets', () {
    testWidgets('CountrySelectionSheet searches and selects country',
        (tester) async {
      CountryOption? selectedCountry;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => CountrySelectionSheet(
                      currentCountry: 'United States',
                      countries: const [
                        CountryOption(
                            code: 'US',
                            name: 'United States',
                            dialCode: '+1',
                            flag: '🇺🇸'),
                        CountryOption(
                            code: 'CA',
                            name: 'Canada',
                            dialCode: '+1',
                            flag: '🇨🇦'),
                      ],
                      onSelected: (val) => selectedCountry = val,
                    ),
                  );
                },
                child: const Text('Open Country Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Country Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Select country or region'), findsOneWidget);
      expect(find.text('United States'), findsOneWidget);
      expect(find.text('Canada'), findsOneWidget);

      // Search for Canada
      await tester.enterText(find.byType(TextField), 'Canada');
      await tester.pumpAndSettle();

      final canadaItem = find.widgetWithText(InkWell, 'Canada');
      expect(canadaItem, findsOneWidget);
      await tester.tap(canadaItem);
      await tester.pumpAndSettle();

      // Tap Confirm selection
      await tester.tap(find.text('Confirm selection'));
      await tester.pumpAndSettle();

      expect(selectedCountry?.name, 'Canada');
    });

    testWidgets(
        'PhotoActionSheet renders camera, gallery, view and remove options',
        (tester) async {
      bool actionTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => PhotoActionSheet(
                      hasExistingPhoto: true,
                      imageUrl: 'https://cdn.prepmate.ai/avatars/alex.png',
                      onChoice: (act) => actionTapped = true,
                    ),
                  );
                },
                child: const Text('Open Photo Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Photo Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Profile Photo'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);
      expect(find.text('Take photo'), findsOneWidget);
      expect(find.text('Remove photo'), findsOneWidget);

      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      expect(actionTapped, isTrue);
    });

    testWidgets(
        'LeaveConfirmationDialog displays discard warning and keeps editing',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    builder: (_) => const LeaveConfirmationDialog(),
                  );
                },
                child: const Text('Show Leave Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Leave Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      expect(find.text('Keep editing'), findsOneWidget);
      expect(find.text('Discard changes'), findsOneWidget);

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsNothing);
    });
  });

  group('Screen 84: Edge States & Conflict Recovery', () {
    testWidgets('ConflictResolutionCard shows comparison and resolves pick',
        (tester) async {
      tester.view.physicalSize = const Size(500, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Map<String, dynamic>? resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ConflictResolutionCard(
                serverData: const {
                  'full_name': 'Alex Morgan (Cloud Sync)',
                  'job_title': 'Principal Architect',
                  'location': 'Austin, TX',
                },
                localData: const {
                  'full_name': 'Alex Morgan',
                  'job_title': 'Staff Systems Architect',
                  'location': 'San Francisco, CA',
                },
                serverVersion: 3,
                onResolve: (data) => resolved = data,
                onCancel: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile changed on another device'), findsOneWidget);
      expect(find.text('Cloud Sync'), findsOneWidget);
      expect(find.text('Staff Systems Architect'), findsOneWidget);

      // Tap Confirm & Synchronize Changes
      await tester.tap(find.text('Confirm & Synchronize Changes'));
      await tester.pumpAndSettle();

      expect(resolved, isNotNull);
      expect(resolved!['version'], 3);
    });

    testWidgets(
        'OfflineDraftCard renders pending sync queue and reconnect retry',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool retryPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: OfflineDraftCard(
                queue: [
                  OfflineDraftItem(
                    field: 'job_title',
                    label: 'Professional Title',
                    displayValue: 'Lead Architect',
                    timestamp: DateTime.now(),
                  ),
                  OfflineDraftItem(
                    field: 'location',
                    label: 'Location',
                    displayValue: 'Seattle, WA',
                    timestamp: DateTime.now(),
                  ),
                ],
                onRetry: () => retryPressed = true,
                onClear: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("You're currently offline"), findsOneWidget);
      expect(find.text('Value: "Lead Architect"'), findsOneWidget);
      expect(find.text('Value: "Seattle, WA"'), findsOneWidget);

      await tester.tap(find.text('Retry Connection'));
      await tester.pumpAndSettle();

      expect(retryPressed, isTrue);
    });

    testWidgets('CascadingResumesSheet requires explicit opt-in checkboxes',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      List<String>? selectedResumes;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CascadingResumesSheet(
                jobTitle: 'Staff Architect',
                location: 'San Francisco, CA',
                onApply: (ids) => selectedResumes = ids,
                onSkip: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Update Selected Resumes?'), findsOneWidget);
      expect(
          find.textContaining('Strict opt-in: only checked resumes will update'),
          findsOneWidget);

      // Confirm checkboxes are initially unchecked (strict opt-in)
      expect(find.text('Apply Updates to Selected (0)'), findsOneWidget);

      // Check the first resume
      await tester.tap(find.text('Senior Flutter Lead 2026'));
      await tester.pumpAndSettle();

      expect(find.text('Apply Updates to Selected (1)'), findsOneWidget);

      // Apply
      await tester.tap(find.text('Apply Updates to Selected (1)'));
      await tester.pumpAndSettle();

      expect(selectedResumes, isNotNull);
      expect(selectedResumes!.length, 1);
    });
  });
}
