import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wardrobe/models/clothing_item.dart';
import 'package:smart_wardrobe/services/supabase_service.dart';
import 'package:smart_wardrobe/services/sync_mutation_queue.dart';
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

  group('Conflict Resolution & Last-Write-Wins (LWW)', () {
    test('When cloud item has newer updatedAt, local item is updated with cloud fields and max wearCount', () {
      final now = DateTime.now().toUtc();
      final localOlder = ClothingItem(
        id: 'item_1',
        title: 'Old Local Title',
        brand: 'Zara',
        imageUrl: 'https://example.com/item1.jpg',
        category: ClothingCategory.tops,
        color: 'Синій',
        wearCount: 10,
        updatedAt: now.subtract(const Duration(hours: 2)),
      );

      final cloudNewerRow = {
        'id': 'item_1',
        'title': 'New Cloud Title from iPad',
        'brand': 'Massimo Dutti',
        'image_url': 'https://example.com/item1_hd.jpg',
        'category': 'tops',
        'color': 'Navy Blue',
        'wear_count': 5, // Cloud has fewer wears than local!
        'updated_at': now.subtract(const Duration(minutes: 5)).toIso8601String(),
      };

      final diff = SupabaseService.reconcileCloudItems(
        localItems: [localOlder],
        deletedIds: {},
        cloudRows: [cloudNewerRow],
      );

      expect(diff.itemsToInsert, isEmpty);
      expect(diff.itemsToUpdate, hasLength(1));
      final updated = diff.itemsToUpdate.single;
      expect(updated.title, equals('New Cloud Title from iPad'));
      expect(updated.brand, equals('Massimo Dutti'));
      expect(updated.color, equals('Navy Blue'));
      // Wear count is merged to maximum (10 > 5) so local wears are never lost!
      expect(updated.wearCount, equals(10));
    });

    test('When local item has newer updatedAt, local fields are retained, but higher cloud wear count is merged', () {
      final now = DateTime.now().toUtc();
      final localNewer = ClothingItem(
        id: 'item_2',
        title: 'Newest Local Edit',
        brand: 'COS',
        imageUrl: 'https://example.com/item2.jpg',
        category: ClothingCategory.bottoms,
        color: 'Чорний',
        wearCount: 3,
        updatedAt: now,
      );

      final cloudOlderRow = {
        'id': 'item_2',
        'title': 'Stale Cloud Edit',
        'brand': 'COS',
        'image_url': 'https://example.com/item2.jpg',
        'category': 'bottoms',
        'color': 'Black',
        'wear_count': 15, // Cloud has higher wear count logged on phone
        'updated_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
      };

      final diff = SupabaseService.reconcileCloudItems(
        localItems: [localNewer],
        deletedIds: {},
        cloudRows: [cloudOlderRow],
      );

      // Local newer fields win; itemsToUpdate is empty
      expect(diff.itemsToInsert, isEmpty);
      expect(diff.itemsToUpdate, isEmpty);
      // Higher cloud wear count (15 > 3) is safely merged!
      expect(diff.itemsWithHigherCloudWear, hasLength(1));
      expect(diff.itemsWithHigherCloudWear.single.wearCount, equals(15));
      expect(diff.itemsWithHigherCloudWear.single.title, equals('Newest Local Edit'));
    });

    test('Tombstones prevent resurrecting deleted items even if cloud has newer updatedAt', () {
      final now = DateTime.now().toUtc();
      final cloudRow = {
        'id': 'deleted_item',
        'title': 'Zombie Item',
        'brand': 'Zara',
        'image_url': 'https://example.com/zombie.jpg',
        'category': 'tops',
        'updated_at': now.toIso8601String(),
      };

      final diff = SupabaseService.reconcileCloudItems(
        localItems: [],
        deletedIds: {'deleted_item'},
        cloudRows: [cloudRow],
      );

      expect(diff.itemsToInsert, isEmpty);
      expect(diff.itemsToUpdate, isEmpty);
      expect(diff.itemsWithHigherCloudWear, isEmpty);
    });
  });

  group('SyncMutationQueue Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SyncMutationQueue.initialize();
      await SyncMutationQueue.clear();
    });

    test('Enqueues and persists mutations to SharedPreferences', () async {
      expect(SyncMutationQueue.pendingCount, equals(0));

      await SyncMutationQueue.enqueue(SyncMutation(
        id: 'mut_1',
        action: SyncMutationAction.upsertItem,
        entityId: 'item_101',
        payload: {'id': 'item_101', 'title': 'Linen Shirt'},
      ));

      expect(SyncMutationQueue.pendingCount, equals(1));
      expect(SyncMutationQueue.pendingMutations.first.entityId, equals('item_101'));

      // Re-initialize from storage verifies persistence
      await SyncMutationQueue.initialize();
      expect(SyncMutationQueue.pendingCount, equals(1));
      expect(SyncMutationQueue.pendingMutations.first.payload['title'], equals('Linen Shirt'));
    });

    test('Coalesces mutations: deleteItem supersedes pending upsertItem', () async {
      await SyncMutationQueue.enqueue(SyncMutation(
        id: 'mut_1',
        action: SyncMutationAction.upsertItem,
        entityId: 'item_102',
        payload: {'id': 'item_102', 'title': 'Silk Dress'},
      ));
      expect(SyncMutationQueue.pendingCount, equals(1));

      // User deletes the item before sync occurs: queue coalesces to single delete
      await SyncMutationQueue.enqueue(SyncMutation(
        id: 'mut_2',
        action: SyncMutationAction.deleteItem,
        entityId: 'item_102',
        payload: {'id': 'item_102'},
      ));

      expect(SyncMutationQueue.pendingCount, equals(1));
      expect(SyncMutationQueue.pendingMutations.single.action, equals(SyncMutationAction.deleteItem));
    });

    test('Removing and clearing mutations works accurately', () async {
      await SyncMutationQueue.enqueue(SyncMutation(
        id: 'mut_a',
        action: SyncMutationAction.insertWearLog,
        entityId: 'log_1',
        payload: {'item_id': 'item_101', 'worn_on': '2026-10-25'},
      ));
      await SyncMutationQueue.enqueue(SyncMutation(
        id: 'mut_b',
        action: SyncMutationAction.upsertOutfit,
        entityId: 'plan_1',
        payload: {'planned_date': '2026-10-26'},
      ));

      expect(SyncMutationQueue.pendingCount, equals(2));

      await SyncMutationQueue.remove('mut_a');
      expect(SyncMutationQueue.pendingCount, equals(1));
      expect(SyncMutationQueue.pendingMutations.single.id, equals('mut_b'));

      await SyncMutationQueue.clear();
      expect(SyncMutationQueue.pendingCount, equals(0));
    });
  });
}
