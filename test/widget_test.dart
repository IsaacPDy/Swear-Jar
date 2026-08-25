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

    // In mock mode, user Fiona is logged in by default
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
    expect(find.text('WHO COMMITTED THE SWEAR?'), findsOneWidget);
    expect(find.text('SWEAR COUNT (1–99)'), findsOneWidget);

    await tester.tap(find.text('Jar'));
    await tester.pumpAndSettle();
    expect(find.text('TOTAL GROUP OUTSTANDING'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your Profile'), findsOneWidget);
  });
}

