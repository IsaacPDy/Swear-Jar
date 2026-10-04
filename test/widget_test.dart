import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swear_jar/main.dart';
import 'package:swear_jar/presentation/providers/providers.dart';

void main() {
  testWidgets('Swear Jar App unauthenticated shows AuthScreen with Google Sign-In',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SwearJarApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('SWEAR JAR 2.0'), findsOneWidget);
    expect(find.text('Sign In with Google'), findsOneWidget);
    expect(find.text('Switch to Local Demo Mode'), findsOneWidget);
  });

  testWidgets('Swear Jar App with mock provider navigates through all 5 tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isLiveModeProvider.overrideWith((ref) => false),
        ],
        child: const SwearJarApp(),
      ),
    );

    await tester.pumpAndSettle();

    // In mock mode, user Fiona is logged in by default and Isaac is the active keeper with GCash
    expect(find.text('JAR KEEPER GCASH'), findsOneWidget);
    expect(find.text('YOUR JAR BALANCE'), findsOneWidget);
    expect(find.text('Report a Swear'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Jar'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    expect(find.text('Report History & Review'), findsOneWidget);

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    expect(find.text('Who swore?'), findsOneWidget);
    expect(find.text('Which word did they say?'), findsOneWidget);
    expect(find.text('When did it happen?'), findsOneWidget);
    expect(find.text('Swear count for this report'), findsOneWidget);
    expect(find.text('Add to Ledger'), findsOneWidget);

    await tester.tap(find.text('Jar'));
    await tester.pumpAndSettle();
    expect(find.text('TO BE RECEIVED'), findsOneWidget);
    expect(find.text('COLLECTED ALREADY'), findsNothing);
    expect(find.text('Collection Progress'), findsNothing);
    expect(find.text('PAYMENT HISTORY'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your Profile'), findsOneWidget);
    expect(find.text('GROUP MEMBERS'), findsOneWidget);
    expect(find.text('QUICK DEMO SWITCHER'), findsNothing);
    expect(find.text('Switch'), findsNothing);
  });

  testWidgets('Swear Jar App shows Firebase warning when init error is provided',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseInitErrorProvider
              .overrideWith((ref) => 'Firebase could not connect to project'),
        ],
        child: const SwearJarApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Firebase Setup Warning'), findsOneWidget);
    expect(find.text('Firebase could not connect to project'), findsOneWidget);
  });

  testWidgets('Swear Jar App adapts between phone layout and laptop computer layout',
      (WidgetTester tester) async {
    // 1. Test Phone sizing (390x844) -> BottomNavigationBar present
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isLiveModeProvider.overrideWith((ref) => false),
        ],
        child: const SwearJarApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('YOUR JAR BALANCE'), findsOneWidget);

    // 2. Test Laptop / Computer sizing (1280x800) -> Computer sidebar instead of BottomNavigationBar
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('SWEAR JAR'), findsOneWidget);
    expect(find.text('YOUR JAR BALANCE'), findsOneWidget);
    expect(find.text('YOUR ACTIVE OBLIGATIONS'), findsOneWidget);

    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    expect(find.text('Report History & Review'), findsOneWidget);

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    expect(find.text('Who swore?'), findsOneWidget);
    expect(find.text('Which word did they say?'), findsOneWidget);

    await tester.tap(find.text('Jar'));
    await tester.pumpAndSettle();
    expect(find.text('TO BE RECEIVED'), findsOneWidget);
    expect(find.text('COLLECTED ALREADY'), findsNothing);
    expect(find.text('PAYMENT HISTORY'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your Profile'), findsOneWidget);
  });

  testWidgets(
      'AdminScreen supports adding a manual user, assigning a pending Google login, unlinking account, and deleting user',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        isLiveModeProvider.overrideWith((ref) => false),
      ],
    );
    addTearDown(container.dispose);

    // Sign in as Leo (Admin & Keeper)
    await container.read(authRepositoryProvider).signInWithDemo('user_leo');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SwearJarApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Profile -> Admin Dashboard
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Admin Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Admin Console'), findsOneWidget);
    expect(find.text('PENDING GOOGLE SIGN-INS (1)'), findsOneWidget);

    // 1. Add a manual user ("Marco")
    await tester.tap(find.text('Add Member'));
    await tester.pumpAndSettle();

    expect(find.text('Add Member Manually'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Display Name *'),
      'Marco',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'GCash Mobile Number (Optional)'),
      '09175556677',
    );
    await tester.tap(find.text('Add Member').last);
    await tester.pumpAndSettle();

    expect(find.text('Marco'), findsWidgets);
    expect(find.text('Manual Profile (Unlinked)'), findsOneWidget);

    // 2. Assign pending Google user ("Alex (Pending)") to "Marco"
    await tester.tap(find.text('Assign to Existing'));
    await tester.pumpAndSettle();

    expect(find.text('Assign Google Login to Existing User'), findsOneWidget);
    // Marco is unlinked, so Marco is preselected at the top of the list
    await tester.tap(find.text('Assign Account'));
    await tester.pumpAndSettle();

    expect(find.text('PENDING GOOGLE SIGN-INS (0)'), findsOneWidget);
    expect(find.text('alex@swearjar.app'), findsOneWidget);

    // 3. Open Manage dialog for Sam and test Option 1 (Unlink Account) & Option 2 (Delete User)
    final deleteButtons = find.byTooltip('Remove Account or Delete User');
    expect(deleteButtons, findsWidgets);
    await tester.tap(deleteButtons.last);
    await tester.pumpAndSettle();

    expect(find.text('Option 1: Remove Linked Account Only'), findsOneWidget);
    expect(find.text('Option 2: Delete User & All History'), findsOneWidget);

    // Unlink account first
    await tester.tap(find.text('Remove Account from Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Manual Profile (Unlinked)'), findsOneWidget);

    // Now delete the user completely
    await tester.tap(deleteButtons.last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete User & History'));
    await tester.pumpAndSettle();

    expect(find.text('MANAGE MEMBERS (3)'), findsOneWidget);
  });

  testWidgets(
      'Admin can add Language and Swear templates, and ReportSwearScreen syncs swear counts (allows over, blocks under)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        isLiveModeProvider.overrideWith((ref) => false),
      ],
    );
    addTearDown(container.dispose);

    // Sign in as Leo (Admin)
    await container.read(authRepositoryProvider).signInWithDemo('user_leo');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SwearJarApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Go to Profile -> Admin Dashboard
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Admin Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('SWEAR TEMPLATES BY LANGUAGE (2)'), findsOneWidget);

    // Add a new Language ("Spanish")
    final languageInput = find.widgetWithText(TextField, 'Language Name');
    await tester.ensureVisible(languageInput);
    await tester.enterText(languageInput, 'Spanish');
    await tester.tap(find.text('Add Language'));
    await tester.pumpAndSettle();

    expect(find.text('SWEAR TEMPLATES BY LANGUAGE (3)'), findsOneWidget);
    expect(find.text('Spanish'), findsOneWidget);

    // Add swears inside Spanish
    final spanishSwearInput = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          w.decoration?.hintText ==
              'Add swear(s) to Spanish (comma-separated)...',
    );
    await tester.ensureVisible(spanishSwearInput);
    await tester.enterText(spanishSwearInput, 'Carajo, Mierda');
    await tester.tap(find.text('Add Swear').last);
    await tester.pumpAndSettle();

    expect(find.text('Carajo'), findsOneWidget);
    expect(find.text('Mierda'), findsOneWidget);

    // Navigate back and go to Report Swear tab
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    expect(find.text('Who swore?'), findsOneWidget);
    expect(find.text('Which word did they say?'), findsOneWidget);

    // Select the newly created 'Spanish' language chip
    await tester.tap(find.text('Spanish'));
    await tester.pumpAndSettle();

    expect(find.text('Carajo'), findsOneWidget);
    expect(find.text('Mierda'), findsOneWidget);

    // Tap 'Carajo' (+1) and 'Mierda' (+2) -> total template count = 3
    await tester.tap(find.text('Carajo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mierda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mierda ×1').first);
    await tester.pumpAndSettle();

    expect(find.text('Clear (3)'), findsOneWidget);
    expect(
      find.text('Minimum 3 from selected swear templates'),
      findsOneWidget,
    );

    // Increment main counter OVER template sum (3 -> 4)
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    expect(
      find.text('Minimum 3 from selected swear templates (+1 extra)'),
      findsOneWidget,
    );

    // Decrement main counter back to 3, and verify trying to decrement below 3 is blocked
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    expect(
      find.text('Minimum 3 from selected swear templates'),
      findsOneWidget,
    );

    // Tapping remove again should stay at 3 (blocked from going under template sum)
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    expect(
      find.text('Minimum 3 from selected swear templates'),
      findsOneWidget,
    );
  });

  testWidgets(
      'Keeper can record a partial payment with payment date and edit payment history in Group Jar & Ledger',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        isLiveModeProvider.overrideWith((ref) => false),
      ],
    );
    addTearDown(container.dispose);

    // Sign in as Leo (Keeper & Admin)
    await container.read(authRepositoryProvider).signInWithDemo('user_leo');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SwearJarApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Jar tab
    await tester.tap(find.text('Jar'));
    await tester.pumpAndSettle();

    expect(find.text('Group Jar & Ledger'), findsOneWidget);
    expect(find.text('AMOUNT EACH PERSON SHOULD PAY (TO BE RECEIVED)'), findsNothing);
    expect(find.text('COLLECTED ALREADY'), findsNothing);
    expect(find.text('Collection Progress'), findsNothing);
    expect(find.text('PAYMENT HISTORY'), findsOneWidget);

    // Every approved member (Fiona, Sam, Leo) is shown in the person boxes with Record Payment button below each card
    expect(find.text('Fiona'), findsWidgets);
    expect(find.text('Sam'), findsWidgets);
    expect(find.text('Leo'), findsWidgets);
    expect(find.text('Record Payment'), findsNWidgets(3));

    // Initially +₱50 is shown in PAYMENT HISTORY
    expect(find.text('+₱50'), findsOneWidget);

    // Tap the first enabled Record Payment button below a person card
    await tester.tap(find.text('Record Payment').first);
    await tester.pumpAndSettle();

    expect(find.text('Full Payment'), findsOneWidget);
    expect(find.text('Partial Payment'), findsOneWidget);
    expect(find.text('PAYMENT DATE'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);

    // Switch to Partial Payment and enter 20
    await tester.tap(find.widgetWithText(InkWell, 'Partial Payment'));
    await tester.pumpAndSettle();

    final amountField = find.widgetWithText(
      TextField,
      'Partial Payment Amount (₱)',
    );
    await tester.enterText(amountField, '20');
    await tester.pumpAndSettle();

    expect(find.text('Remaining To Be Received'), findsOneWidget);
    expect(find.text('Record Partial Payment (₱20)'), findsOneWidget);

    await tester.tap(find.text('Record Partial Payment (₱20)'));
    await tester.pumpAndSettle();

    // +₱20 is now recorded in PAYMENT HISTORY (just the payment amount is shown)
    expect(find.text('+₱20'), findsOneWidget);

    // Edit the +₱20 payment in PAYMENT HISTORY to ₱30
    final editButtons = find.byTooltip('Edit Payment');
    expect(editButtons, findsWidgets);
    await tester.tap(editButtons.first);
    await tester.pumpAndSettle();

    final editAmountField = find.widgetWithText(
      TextField,
      'Payment Amount (₱)',
    );
    await tester.enterText(editAmountField, '30');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('+₱30'), findsOneWidget);
  });

  testWidgets(
      'ReportsScreen displays Month filter chips and Analytics of People Who Swore and Words Said',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        isLiveModeProvider.overrideWith((ref) => false),
      ],
    );
    addTearDown(container.dispose);

    // Submit a historical report in an earlier month to test month filtering
    await container.read(reportRepositoryProvider).submitReport(
          reporterId: 'user_fiona',
          accusedId: 'user_leo',
          count: 3,
          swearBreakdown: const {'Gago': 3},
          rateApplied: 50.0,
          swearDate: DateTime(2025, 12, 15),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SwearJarApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Reports tab
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();

    expect(find.text('Report History & Review'), findsOneWidget);
    expect(find.text('All Months'), findsOneWidget);
    expect(find.text('Dec 2025 (1)'), findsOneWidget);
    expect(find.text('People Who Swore'), findsOneWidget);
    expect(find.text('Words Said'), findsOneWidget);
    expect(find.text('"Fuck"'), findsOneWidget);
    expect(find.text('"Gago"'), findsOneWidget);

    // Filter by Dec 2025
    await tester.ensureVisible(find.text('Dec 2025 (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dec 2025 (1)'));
    await tester.pumpAndSettle();

    expect(find.text('SWEAR ANALYTICS • DECEMBER 2025'), findsOneWidget);
    expect(find.text('REPORT LOG (1)'), findsOneWidget);
    expect(find.text('"Gago"'), findsOneWidget);
    expect(find.text('"Fuck"'), findsNothing);

    // Reset back to All Months
    await tester.tap(find.text('Reset Filters'));
    await tester.pumpAndSettle();

    expect(find.text('SWEAR ANALYTICS • ALL MONTHS'), findsOneWidget);
    expect(find.text('REPORT LOG (4)'), findsOneWidget);
  });

  testWidgets(
      'Denying a pending user does not block them from signing in again and waiting for access',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        isLiveModeProvider.overrideWith((ref) => false),
      ],
    );
    addTearDown(container.dispose);

    // 1. Admin rejects the pending user (user_alex)
    await container.read(userRepositoryProvider).rejectUser('user_alex');
    expect(container.read(pendingUsersProvider), isEmpty);

    // 2. Denied user signs in again to have another go
    await container.read(authRepositoryProvider).signInWithDemo('user_alex');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SwearJarApp(),
      ),
    );
    await tester.pumpAndSettle();

    // User sees Approval Pending (waiting for access) instead of Access Denied
    expect(find.text('Approval Pending'), findsOneWidget);
    expect(find.text('Access Denied'), findsNothing);

    // User also reappears in the Admin pending sign-ins list
    expect(container.read(pendingUsersProvider).length, 1);
    expect(container.read(pendingUsersProvider).first.id, 'user_alex');
  });
}

