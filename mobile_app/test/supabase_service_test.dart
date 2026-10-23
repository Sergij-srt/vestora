import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wardrobe/services/supabase_service.dart';
import 'package:smart_wardrobe/services/wardrobe_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SupabaseService Initialization & State', () {
    test('Default unconfigured state returns isConfigured == false safely', () async {
      await SupabaseService.initialize();

      expect(SupabaseService.isConfigured, isFalse);
      expect(SupabaseService.isAuthenticated, isFalse);
      expect(SupabaseService.currentUser, isNull);
      expect(SupabaseService.currentUserId, isNull);
      expect(SupabaseService.currentUserEmail, isNull);
      expect(SupabaseService.client, isNull);
    });

    test('getSqlSchema returns complete production PostgreSQL DDL with RLS & S3 bucket', () {
      final schema = SupabaseService.getSqlSchema();

      expect(schema, isNotEmpty);
      expect(schema, contains('create extension if not exists "uuid-ossp";'));
      expect(schema, contains('public.profiles'));
      expect(schema, contains('public.clothing_items'));
      expect(schema, contains('public.outfits'));
      expect(schema, contains('public.wear_logs'));
      expect(schema, contains('vestora-wardrobe'));
      expect(schema, contains('enable row level security'));
      expect(schema, contains('auth.uid()'));
      expect(schema, contains('auth.role() = \'authenticated\''));
    });

    test('Disconnect resets credentials and returns to offline mode', () async {
      SharedPreferences.setMockInitialValues({
        'vestora_supabase_url': 'https://example.supabase.co',
        'vestora_supabase_anon_key': 'test-anon-key-123',
      });

      await SupabaseService.disconnect();

      expect(SupabaseService.isConfigured, isFalse);
      expect(SupabaseService.configuredUrl, isNull);
      expect(SupabaseService.configuredAnonKey, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('vestora_supabase_url'), isNull);
      expect(prefs.getString('vestora_supabase_anon_key'), isNull);
    });
  });

  group('SupabaseService Auth & Sync Fallbacks', () {
    test('Auth methods return structured error when not connected without throwing', () async {
      await SupabaseService.disconnect();

      final signInResult = await SupabaseService.signInWithPassword(
        email: 'user@vestora.app',
        password: 'password123',
      );
      expect(signInResult.success, isFalse);
      expect(signInResult.error, contains('Supabase не підключено'));

      final signUpResult = await SupabaseService.signUp(
        email: 'user@vestora.app',
        password: 'password123',
        fullName: 'Olena Luxury',
      );
      expect(signUpResult.success, isFalse);
      expect(signUpResult.error, contains('Supabase не підключено'));

      final googleResult = await SupabaseService.signInWithGoogle();
      expect(googleResult.success, isFalse);
      expect(googleResult.error, contains('Supabase не підключено'));

      expect(() async => await SupabaseService.signOut(), returnsNormally);
    });

    test('syncWardrobe safely returns error message when unauthenticated without throwing', () async {
      await SupabaseService.disconnect();
      final wardrobe = WardrobeProvider();

      final result = await SupabaseService.syncWardrobe(
        wardrobe: wardrobe,
        pushLocal: true,
        pullCloud: true,
      );

      expect(result.success, isFalse);
      expect(result.pushed, 0);
      expect(result.pulled, 0);
      expect(result.message, contains('Необхідно налаштувати Supabase'));
    });
  });
}
