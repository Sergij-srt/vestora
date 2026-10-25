import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wardrobe/services/secure_vault_service.dart';
import 'package:smart_wardrobe/services/ai_config_service.dart';
import 'package:smart_wardrobe/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SecureVaultService.clearAll();
  });

  group('SecureVaultService Core Operations', () {
    test('write, read, containsKey, and delete work correctly', () async {
      expect(await SecureVaultService.containsKey('test_secret'), isFalse);
      expect(await SecureVaultService.read('test_secret'), isNull);

      await SecureVaultService.write('test_secret', 'ultra_secret_value_123');

      expect(await SecureVaultService.containsKey('test_secret'), isTrue);
      expect(await SecureVaultService.read('test_secret'), 'ultra_secret_value_123');

      await SecureVaultService.delete('test_secret');

      expect(await SecureVaultService.containsKey('test_secret'), isFalse);
      expect(await SecureVaultService.read('test_secret'), isNull);
    });

    test('clearAll removes all stored credentials', () async {
      await SecureVaultService.write('k1', 'v1');
      await SecureVaultService.write('k2', 'v2');

      expect(await SecureVaultService.containsKey('k1'), isTrue);
      expect(await SecureVaultService.containsKey('k2'), isTrue);

      await SecureVaultService.clearAll();

      expect(await SecureVaultService.containsKey('k1'), isFalse);
      expect(await SecureVaultService.containsKey('k2'), isFalse);
    });
  });

  group('SecureVaultService Auto-Migration from SharedPreferences', () {
    test('transparently migrates legacy plaintext keys and cleans SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'vestora_gemini_api_key': 'AIzaSyLegacyKey123',
        'vestora_supabase_url': 'https://legacy-project.supabase.co',
        'vestora_supabase_anon_key': 'legacy-anon-key-xyz',
        'vestora_auth_session_token': 'legacy-session-token-abc',
      });

      await SecureVaultService.migrateFromSharedPreferences();

      // Check values in SecureVault
      expect(await SecureVaultService.read('vestora_gemini_api_key'), 'AIzaSyLegacyKey123');
      expect(await SecureVaultService.read('vestora_supabase_url'), 'https://legacy-project.supabase.co');
      expect(await SecureVaultService.read('vestora_supabase_anon_key'), 'legacy-anon-key-xyz');
      expect(await SecureVaultService.read('vestora_auth_session_token'), 'legacy-session-token-abc');

      // Check that plaintext values are eradicated from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('vestora_gemini_api_key'), isNull);
      expect(prefs.getString('vestora_supabase_url'), isNull);
      expect(prefs.getString('vestora_supabase_anon_key'), isNull);
      expect(prefs.getString('vestora_auth_session_token'), isNull);
    });
  });

  group('Service Integrations with SecureVault', () {
    test('AiConfigService persists and reads API key from SecureVault', () async {
      await AiConfigService.setApiKey('AIzaSyNewSecureKey999');

      expect(AiConfigService.apiKey, 'AIzaSyNewSecureKey999');
      expect(await SecureVaultService.read('vestora_gemini_api_key'), 'AIzaSyNewSecureKey999');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('vestora_gemini_api_key'), isNull);

      // Re-initialize and verify it loads from SecureVault
      await AiConfigService.initialize();
      expect(AiConfigService.apiKey, 'AIzaSyNewSecureKey999');

      await AiConfigService.setApiKey(null);
      expect(AiConfigService.apiKey, isNull);
      expect(await SecureVaultService.read('vestora_gemini_api_key'), isNull);
    });

    test('SupabaseService disconnect removes credentials from SecureVault', () async {
      await SecureVaultService.write('vestora_supabase_url', 'https://test.supabase.co');
      await SecureVaultService.write('vestora_supabase_anon_key', 'test-anon-key');

      await SupabaseService.disconnect();

      expect(await SecureVaultService.read('vestora_supabase_url'), isNull);
      expect(await SecureVaultService.read('vestora_supabase_anon_key'), isNull);
    });
  });
}
