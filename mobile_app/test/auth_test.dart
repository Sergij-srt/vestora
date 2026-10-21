import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wardrobe/services/auth_service.dart';
import 'package:smart_wardrobe/services/user_profile_service.dart';
import 'package:smart_wardrobe/screens/auth_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initialize();
    await UserProfileService.initialize();
  });

  group('AuthService Unit Tests', () {
    test('Google Sign-In updates profile and sets active session', () async {
      final auth = AuthService.instance;
      final res = await auth.signInWithGoogle(
        email: 'olena.fashion@gmail.com',
        displayName: 'Олена Шевченко',
      );

      expect(res.success, isTrue);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentMethod, equals(AuthMethod.google));
      expect(auth.currentUser?.email, equals('olena.fashion@gmail.com'));
      expect(auth.currentUser?.displayName, equals('Олена Шевченко'));
      expect(UserProfileService.profile.email, equals('olena.fashion@gmail.com'));
    });

    test('Email and Password authentication validates format and registers new users', () async {
      final auth = AuthService.instance;

      // Bad email validation
      final badEmail = await auth.signInWithEmailAndPassword(
        email: 'invalid-email',
        password: 'password123',
      );
      expect(badEmail.success, isFalse);

      // Short password validation
      final shortPass = await auth.signInWithEmailAndPassword(
        email: 'test@vestora.app',
        password: '123',
      );
      expect(shortPass.success, isFalse);

      // Register new user
      final regRes = await auth.registerWithEmailAndPassword(
        name: 'Вікторія',
        email: 'viktoria@vestora.app',
        password: 'securePassword2026',
      );
      expect(regRes.success, isTrue);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUser?.displayName, equals('Вікторія'));

      // Sign Out
      await auth.signOut();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.currentUser, isNull);

      // Sign In with registered credentials
      final loginRes = await auth.signInWithEmailAndPassword(
        email: 'viktoria@vestora.app',
        password: 'securePassword2026',
      );
      expect(loginRes.success, isTrue);
      expect(auth.isLoggedIn, isTrue);
    });

    test('Password reset email simulation sends instructions', () async {
      final auth = AuthService.instance;
      final res = await auth.sendPasswordResetEmail('designer@vestora.app');
      expect(res.success, isTrue);
      expect(res.message, contains('designer@vestora.app'));

      final badRes = await auth.sendPasswordResetEmail('not-an-email');
      expect(badRes.success, isFalse);
    });

    test('Guest sign-in enables exploration without credentials', () async {
      final auth = AuthService.instance;
      await auth.signInAsGuest();
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentMethod, equals(AuthMethod.guest));
    });
  });

  group('AuthScreen Widget Tests', () {
    testWidgets('Renders Google Sign-In and Email form with tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Brand headers
      expect(find.text('VESTORA'), findsOneWidget);
      expect(find.text('SMART DIGITAL CLOSET & HAUTE CAPSULE'), findsOneWidget);

      // Google Sign-In button
      expect(find.text('Продовжити через Google'), findsOneWidget);

      // Mode toggles
      expect(find.text('Вхід у кабінет'), findsOneWidget);
      expect(find.text('Реєстрація'), findsOneWidget);

      // Switch to Sign Up
      await tester.tap(find.text('Реєстрація'));
      await tester.pump();
      expect(find.text('ВАШЕ ІМ\'Я'), findsOneWidget);
      expect(find.text('ПІДТВЕРДЖЕННЯ ПАРОЛЮ'), findsOneWidget);
      expect(find.text('Створити акаунт'), findsOneWidget);

      // Switch back to Sign In
      await tester.tap(find.text('Вхід у кабінет'));
      await tester.pump();
      expect(find.text('Забули пароль?'), findsOneWidget);
      expect(find.text('Увійти з Email та паролем'), findsOneWidget);

      // Guest button
      expect(find.text('Продовжити як гість (Демо-режим)'), findsOneWidget);
    });
  });
}
