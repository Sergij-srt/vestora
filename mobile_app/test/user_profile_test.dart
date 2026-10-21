import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wardrobe/services/user_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProfileService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await UserProfileService.initialize();
    });

    test('Initializes with default user profile values', () {
      final p = UserProfileService.profile;
      expect(p.name, equals('Сергій'));
      expect(p.email, contains('@'));
      expect(p.currency, contains('UAH'));
      expect(p.pushDailyStylist, isTrue);
      expect(p.emailMonthlyDigest, isTrue);
      expect(p.twoFactorAuth, isFalse);
    });

    test('Saves and persists updated profile information', () async {
      await UserProfileService.saveProfile(
        name: 'Олександр',
        email: 'alex@example.com',
        phone: '+380 99 765 43 21',
        location: 'Львів, Україна',
        currency: 'EUR (€)',
        preferredStyle: 'Old Money',
      );

      final p = UserProfileService.profile;
      expect(p.name, equals('Олександр'));
      expect(p.email, equals('alex@example.com'));
      expect(p.phone, equals('+380 99 765 43 21'));
      expect(p.location, equals('Львів, Україна'));
      expect(p.currency, equals('EUR (€)'));
      expect(p.preferredStyle, equals('Old Money'));
    });

    test('Password validation enforces min 6 chars and matching confirmation', () async {
      final shortPass = await UserProfileService.changePassword(
        oldPassword: '123',
        newPassword: 'abc',
        confirmPassword: 'abc',
      );
      expect(shortPass.success, isFalse);
      expect(shortPass.message, contains('6 символів'));

      final mismatch = await UserProfileService.changePassword(
        oldPassword: 'old_secret',
        newPassword: 'new_secret_1',
        confirmPassword: 'new_secret_2',
      );
      expect(mismatch.success, isFalse);
      expect(mismatch.message, contains('не співпадають'));

      final valid = await UserProfileService.changePassword(
        oldPassword: 'old_secret',
        newPassword: 'strong_secret_123',
        confirmPassword: 'strong_secret_123',
      );
      expect(valid.success, isTrue);
      expect(valid.message, contains('успішно'));
    });

    test('Updates notification preferences for push and email', () async {
      await UserProfileService.saveNotifications(
        pushDailyStylist: false,
        emailEcoReport: false,
      );

      final p = UserProfileService.profile;
      expect(p.pushDailyStylist, isFalse);
      expect(p.emailEcoReport, isFalse);
      // Other flags remain true
      expect(p.pushStreakReminder, isTrue);
    });

    test('Toggles 2FA security setting', () async {
      await UserProfileService.setTwoFactor(true);
      expect(UserProfileService.profile.twoFactorAuth, isTrue);

      await UserProfileService.setTwoFactor(false);
      expect(UserProfileService.profile.twoFactorAuth, isFalse);
    });
  });
}
