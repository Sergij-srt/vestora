import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clothing_item.dart';
import 'outfit_calendar_service.dart';
import 'secure_vault_service.dart';
import 'user_profile_service.dart';
import 'wardrobe_provider.dart';
import 'weather_stylist_service.dart';

class SupabaseService {
  static const String _keySupabaseUrl = 'vestora_supabase_url';
  static const String _keySupabaseAnonKey = 'vestora_supabase_anon_key';
  static const String _keyAutoSync = 'vestora_supabase_auto_sync';

  static bool _isInitialized = false;
  static String? _configuredUrl;
  static String? _configuredAnonKey;
  static bool _autoSyncEnabled = true;

  static bool get isInitialized => _isInitialized;
  static bool get isConfigured =>
      _configuredUrl != null &&
      _configuredUrl!.trim().isNotEmpty &&
      _configuredAnonKey != null &&
      _configuredAnonKey!.trim().isNotEmpty;

  static String? get configuredUrl => _configuredUrl;
  static String? get configuredAnonKey => _configuredAnonKey;
  static bool get autoSyncEnabled => _autoSyncEnabled;

  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static User? get currentUser => client?.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;
  static String? get currentUserId => currentUser?.id;
  static String? get currentUserEmail => currentUser?.email;

  /// Converts a local [ClothingItem] into a PostgreSQL `public.clothing_items` snake_case row.
  static Map<String, dynamic> itemToRow(ClothingItem item, String userId) =>
      item.toPostgresRow(userId);

  /// Converts a PostgreSQL `public.clothing_items` snake_case row into a [ClothingItem].
  static ClothingItem itemFromRow(Map<String, dynamic> row) =>
      ClothingItem.fromPostgresRow(row);

  /// Converts a [PlannedDayOutfit] into a PostgreSQL `public.outfits` row.
  static Map<String, dynamic> plannedOutfitToRow(PlannedDayOutfit plan, String userId) {
    final itemIds = <String>[
      if (plan.outerwearId != null) 'outerwear:${plan.outerwearId}',
      if (plan.topId != null) 'top:${plan.topId}',
      if (plan.bottomId != null) 'bottom:${plan.bottomId}',
      if (plan.shoesId != null) 'shoes:${plan.shoesId}',
    ];
    return {
      'id': 'plan_${userId}_${plan.dateStr}',
      'user_id': userId,
      'title': plan.eventTitle,
      'planned_date': plan.dateStr,
      'occasion': plan.occasion.name,
      'weather_temp': plan.weatherTemp,
      'weather_condition': plan.weatherCondition.name,
      'aesthetic_vibe': plan.occasion.label,
      'is_favorite': false,
      'is_worn': plan.isWorn,
      'comfort_score': 95,
      'item_ids': itemIds,
      'notes': plan.notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Reconstructs a [PlannedDayOutfit] from a PostgreSQL `public.outfits` row if it has `planned_date`.
  static PlannedDayOutfit? plannedOutfitFromRow(Map<String, dynamic> row) {
    final dateStr = row['planned_date']?.toString();
    if (dateStr == null || dateStr.isEmpty) return null;
    final parsedDate = DateTime.tryParse(dateStr);
    if (parsedDate == null) return null;

    String? outerwearId;
    String? topId;
    String? bottomId;
    String? shoesId;
    final rawItemIds = row['item_ids'];
    if (rawItemIds is List) {
      for (final rawEntry in rawItemIds) {
        final entry = rawEntry.toString();
        if (entry.startsWith('outerwear:')) {
          outerwearId = entry.substring('outerwear:'.length);
        } else if (entry.startsWith('top:')) {
          topId = entry.substring('top:'.length);
        } else if (entry.startsWith('bottom:')) {
          bottomId = entry.substring('bottom:'.length);
        } else if (entry.startsWith('shoes:')) {
          shoesId = entry.substring('shoes:'.length);
        }
      }
    }

    WeatherCondition condition = WeatherCondition.cloudy;
    final rawCond = row['weather_condition']?.toString();
    if (rawCond != null) {
      for (final c in WeatherCondition.values) {
        if (c.name == rawCond) {
          condition = c;
          break;
        }
      }
    }

    Occasion occasion = Occasion.casual;
    final rawOcc = row['occasion']?.toString();
    if (rawOcc != null) {
      for (final o in Occasion.values) {
        if (o.name == rawOcc) {
          occasion = o;
          break;
        }
      }
    }

    return PlannedDayOutfit(
      dateStr: dateStr,
      date: parsedDate,
      weatherTemp: (row['weather_temp'] as num?)?.toInt() ?? 17,
      weatherCondition: condition,
      occasion: occasion,
      eventTitle: row['title']?.toString() ?? 'Образ дня',
      outerwearId: outerwearId,
      topId: topId,
      bottomId: bottomId,
      shoesId: shoesId,
      isWorn: row['is_worn'] as bool? ?? false,
      notes: row['notes']?.toString(),
    );
  }

  /// Reconciles cloud rows against local items, wear logs, and deletion tombstones (pure helper for unit tests & sync).
  static ({
    List<ClothingItem> itemsToInsert,
    List<ClothingItem> itemsWithHigherCloudWear,
  }) reconcileCloudItems({
    required List<ClothingItem> localItems,
    required Set<String> deletedIds,
    required List<Map<String, dynamic>> cloudRows,
    Map<String, int> cloudWearLogCounts = const {},
  }) {
    final localById = {for (final item in localItems) item.id: item};
    final toInsert = <ClothingItem>[];
    final toUpdateWear = <ClothingItem>[];

    for (final row in cloudRows) {
      final cloudItem = itemFromRow(row);
      if (cloudItem.id.isEmpty || deletedIds.contains(cloudItem.id)) {
        // Tombstone guard: never resurrect locally deleted items from cloud!
        continue;
      }

      final loggedWears = cloudWearLogCounts[cloudItem.id] ?? 0;
      final effectiveCloudWear =
          loggedWears > cloudItem.wearCount ? loggedWears : cloudItem.wearCount;

      final existingLocal = localById[cloudItem.id];
      if (existingLocal == null) {
        toInsert.add(
          effectiveCloudWear > cloudItem.wearCount
              ? cloudItem.copyWith(wearCount: effectiveCloudWear)
              : cloudItem,
        );
      } else if (effectiveCloudWear > existingLocal.wearCount) {
        toUpdateWear.add(existingLocal.copyWith(wearCount: effectiveCloudWear));
      }
    }

    return (
      itemsToInsert: toInsert,
      itemsWithHigherCloudWear: toUpdateWear,
    );
  }

  /// Loads saved configuration and initializes Supabase client safely
  static Future<bool> initialize({String? customUrl, String? customAnonKey}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final secureUrl = await SecureVaultService.read(_keySupabaseUrl);
      final secureKey = await SecureVaultService.read(_keySupabaseAnonKey);

      _configuredUrl = customUrl ?? (secureUrl?.isNotEmpty == true ? secureUrl : prefs.getString(_keySupabaseUrl));
      _configuredAnonKey = customAnonKey ?? (secureKey?.isNotEmpty == true ? secureKey : prefs.getString(_keySupabaseAnonKey));
      _autoSyncEnabled = prefs.getBool(_keyAutoSync) ?? true;

      // Migrate legacy plaintext keys if found
      if (secureUrl == null && prefs.containsKey(_keySupabaseUrl) && _configuredUrl != null) {
        await SecureVaultService.write(_keySupabaseUrl, _configuredUrl!);
        await prefs.remove(_keySupabaseUrl);
      }
      if (secureKey == null && prefs.containsKey(_keySupabaseAnonKey) && _configuredAnonKey != null) {
        await SecureVaultService.write(_keySupabaseAnonKey, _configuredAnonKey!);
        await prefs.remove(_keySupabaseAnonKey);
      }

      if (!isConfigured) {
        _isInitialized = false;
        return false;
      }

      if (_isInitialized) {
        return true;
      }

      await Supabase.initialize(
        url: _configuredUrl!.trim(),
        // ignore: deprecated_member_use
        anonKey: _configuredAnonKey!.trim(),
      );

      _isInitialized = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Supabase initialization warning (Local Fallback Active): $e');
      }
      _isInitialized = false;
      return false;
    }
  }

  /// Saves Supabase credentials securely and re-initializes
  static Future<bool> saveCredentials({
    required String url,
    required String anonKey,
    bool autoSync = true,
  }) async {
    final cleanUrl = url.trim();
    final cleanKey = anonKey.trim();

    try {
      await SecureVaultService.write(_keySupabaseUrl, cleanUrl);
      await SecureVaultService.write(_keySupabaseAnonKey, cleanKey);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySupabaseUrl);
      await prefs.remove(_keySupabaseAnonKey);
      await prefs.setBool(_keyAutoSync, autoSync);

      _configuredUrl = cleanUrl;
      _configuredAnonKey = cleanKey;
      _autoSyncEnabled = autoSync;

      return await initialize(customUrl: cleanUrl, customAnonKey: cleanKey);
    } catch (_) {
      return false;
    }
  }

  /// Clears credentials and returns to offline-only mode
  static Future<void> disconnect() async {
    try {
      await SecureVaultService.delete(_keySupabaseUrl);
      await SecureVaultService.delete(_keySupabaseAnonKey);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySupabaseUrl);
      await prefs.remove(_keySupabaseAnonKey);
      await client?.auth.signOut();
    } catch (_) {}

    _configuredUrl = null;
    _configuredAnonKey = null;
    _isInitialized = false;
  }

  /// Signs in with Email and Password
  static Future<({bool success, String? error, User? user})> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final cli = client;
    if (cli == null) {
      return (
        success: false,
        error: 'Supabase не підключено. Вкажіть URL та Anon Key у налаштуваннях.',
        user: null,
      );
    }

    try {
      final response = await cli.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return (success: true, error: null, user: response.user);
    } catch (e) {
      return (success: false, error: e.toString(), user: null);
    }
  }

  /// Signs up with Email and Password
  static Future<({bool success, String? error, User? user})> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final cli = client;
    if (cli == null) {
      return (
        success: false,
        error: 'Supabase не підключено. Вкажіть URL та Anon Key у налаштуваннях.',
        user: null,
      );
    }

    try {
      final response = await cli.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
      return (success: true, error: null, user: response.user);
    } catch (e) {
      return (success: false, error: e.toString(), user: null);
    }
  }

  /// Signs in with Google OAuth
  static Future<({bool success, String? error})> signInWithGoogle() async {
    final cli = client;
    if (cli == null) {
      return (
        success: false,
        error: 'Supabase не підключено. Вкажіть URL та Anon Key у налаштуваннях.',
      );
    }

    try {
      await cli.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.vestora://login-callback/',
      );
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  /// Signs out of Supabase
  static Future<void> signOut() async {
    try {
      await client?.auth.signOut();
    } catch (_) {}
  }

  /// Permanently deletes all cloud rows (`wear_logs`, `outfits`, `clothing_items`, `profiles`),
  /// per-user storage objects (`vestora-wardrobe/{uid}/...`), and the `auth.users` account record
  /// via the `public.delete_own_user()` SECURITY DEFINER RPC.
  static Future<bool> deleteCloudUserData() async {
    final cli = client;
    final userId = currentUserId;
    if (cli == null || userId == null) return false;

    try {
      // 1. Delete user's uploaded images inside per-user folder `vestora-wardrobe/{userId}/`
      try {
        final objects = await cli.storage.from('vestora-wardrobe').list(path: userId);
        if (objects.isNotEmpty) {
          final paths = objects.map((o) => '$userId/${o.name}').toList();
          await cli.storage.from('vestora-wardrobe').remove(paths);
        }
      } catch (_) {}

      // 2. Delete relational rows across all user tables
      await cli.from('wear_logs').delete().eq('user_id', userId);
      await cli.from('outfits').delete().eq('user_id', userId);
      await cli.from('clothing_items').delete().eq('user_id', userId);
      await cli.from('profiles').delete().eq('id', userId);

      // 3. Delete `auth.users` record via SECURITY DEFINER RPC (cascades any remaining auth rows)
      try {
        await cli.rpc('delete_own_user');
      } catch (_) {}

      try {
        await cli.auth.signOut();
      } catch (_) {}
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Supabase cloud data deletion warning: $e');
      }
      return false;
    }
  }

  /// Full bidirectional synchronization (Local ⇄ Supabase Cloud) across:
  /// - `clothing_items` (tombstone propagation -> pull & max-wear reconciliation -> push)
  /// - `profiles` (pull & field/streak reconciliation -> push)
  /// - `outfits` (tombstone propagation -> pull -> push planned calendar capsules)
  /// - `wear_logs` (pull counts -> push pending logs)
  static Future<({bool success, int pushed, int pulled, String? message})> syncWardrobe({
    required WardrobeProvider wardrobe,
    bool pushLocal = true,
    bool pullCloud = true,
  }) async {
    final cli = client;
    if (cli == null || !isAuthenticated) {
      return (
        success: false,
        pushed: 0,
        pulled: 0,
        message: 'Необхідно налаштувати Supabase та увійти у свій обліковий запис.',
      );
    }

    await wardrobe.initialized;
    final userId = currentUserId!;
    int pushedCount = 0;
    int pulledCount = 0;
    final syncWarnings = <String>[];
    final newlyPulledItemIds = <String>{};

    try {
      // 1. Propagate local deletion tombstones FIRST so deleted items/outfits are never resurrected
      final itemTombstones = wardrobe.deletedItemIds.toList();
      if (pushLocal && itemTombstones.isNotEmpty) {
        await cli
            .from('clothing_items')
            .delete()
            .eq('user_id', userId)
            .inFilter('id', itemTombstones);
        await wardrobe.markTombstonesSynced(itemTombstones);
      }

      if (pushLocal) {
        try {
          final deletedDates = (await OutfitCalendarService.getDeletedDates()).toList();
          if (deletedDates.isNotEmpty) {
            final outfitIdsToDelete =
                deletedDates.map((d) => 'plan_${userId}_$d').toList();
            await cli
                .from('outfits')
                .delete()
                .eq('user_id', userId)
                .inFilter('id', outfitIdsToDelete);
            await OutfitCalendarService.markDeletedDatesSynced(deletedDates);
          }
        } catch (e) {
          syncWarnings.add('outfits-delete');
        }
      }

      // 2. Pull & reconcile cloud state BEFORE pushing local rows so higher cloud wearCount,
      // streak_days, and remote profile/outfit updates are never overwritten by stale local values!
      if (pullCloud) {
        final cloudWearLogCounts = <String, int>{};
        try {
          final wearRows =
              await cli.from('wear_logs').select('item_id').eq('user_id', userId);
          for (final raw in (wearRows as List)) {
            final itemId = (raw as Map)['item_id']?.toString();
            if (itemId != null && itemId.isNotEmpty) {
              cloudWearLogCounts[itemId] = (cloudWearLogCounts[itemId] ?? 0) + 1;
            }
          }
        } catch (_) {
          syncWarnings.add('wear_logs-pull');
        }

        final response = await cli
            .from('clothing_items')
            .select()
            .eq('user_id', userId);

        final cloudList = (response as List).cast<Map<String, dynamic>>();
        final reconciled = reconcileCloudItems(
          localItems: wardrobe.items,
          deletedIds: wardrobe.deletedItemIds,
          cloudRows: cloudList,
          cloudWearLogCounts: cloudWearLogCounts,
        );

        if (reconciled.itemsToInsert.isNotEmpty) {
          for (final it in reconciled.itemsToInsert) {
            newlyPulledItemIds.add(it.id);
          }
          await wardrobe.addMultipleItems(reconciled.itemsToInsert);
          pulledCount += reconciled.itemsToInsert.length;
        }
        for (final updatedWearItem in reconciled.itemsWithHigherCloudWear) {
          await wardrobe.updateItem(updatedWearItem);
        }

        // Pull `public.profiles` before upserting local profile
        try {
          final profileRows = await cli.from('profiles').select().eq('id', userId);
          if ((profileRows as List).isNotEmpty) {
            final row = Map<String, dynamic>.from(profileRows.first as Map);
            final cloudStreak = (row['streak_days'] as num?)?.toInt();
            if (cloudStreak != null) {
              wardrobe.setStreakDaysFromSync(cloudStreak);
            }
            await UserProfileService.reconcileCloudProfile(
              row,
              preferCloud: !pushLocal,
            );
          }
        } catch (_) {
          syncWarnings.add('profiles-pull');
        }

        // Pull `public.outfits` before upserting local plans
        try {
          final outfitRows = await cli.from('outfits').select().eq('user_id', userId);
          final parsedPlans = <PlannedDayOutfit>[];
          for (final raw in (outfitRows as List)) {
            final plan = plannedOutfitFromRow(Map<String, dynamic>.from(raw as Map));
            if (plan != null) parsedPlans.add(plan);
          }
          pulledCount += await OutfitCalendarService.mergeCloudPlans(parsedPlans);
        } catch (_) {
          syncWarnings.add('outfits-pull');
        }
      }

      // 3. Push reconciled local state to Supabase
      if (pushLocal) {
        final itemsToPush = wardrobe.items
            .where((item) => !newlyPulledItemIds.contains(item.id))
            .map((item) => itemToRow(item, userId))
            .toList();
        if (itemsToPush.isNotEmpty) {
          await cli.from('clothing_items').upsert(itemsToPush);
          pushedCount += itemsToPush.length;
        }

        try {
          final profile = UserProfileService.profile;
          await cli.from('profiles').upsert({
            'id': userId,
            'email': currentUserEmail ?? profile.email,
            'full_name': profile.name,
            'avatar_url': profile.avatarUrl,
            'location': profile.location,
            'preferred_style': profile.preferredStyle,
            'currency': profile.currency,
            'size_system': profile.sizeSystem,
            'streak_days': wardrobe.streakDays,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (_) {
          syncWarnings.add('profiles-push');
        }

        try {
          final plans = await OutfitCalendarService.getAllPlans();
          if (plans.isNotEmpty) {
            final outfitPayload = plans.values
                .map((plan) => plannedOutfitToRow(plan, userId))
                .toList();
            await cli.from('outfits').upsert(outfitPayload);
          }
        } catch (_) {
          syncWarnings.add('outfits-push');
        }

        try {
          if (wardrobe.pendingWearLogs.isNotEmpty) {
            final validItemIds = wardrobe.items.map((e) => e.id).toSet();
            final logsPayload = wardrobe.pendingWearLogs
                .where((log) => validItemIds.contains(log['item_id']))
                .map((log) => {
                      'user_id': userId,
                      'item_id': log['item_id'],
                      'worn_on': log['worn_on'],
                    })
                .toList();
            if (logsPayload.isNotEmpty) {
              await cli.from('wear_logs').insert(logsPayload);
            }
            await wardrobe.markWearLogsSynced();
          }
        } catch (_) {
          syncWarnings.add('wear_logs-push');
        }
      }

      final warningSuffix = syncWarnings.isEmpty
          ? ''
          : ' (часткові попередження: ${syncWarnings.join(", ")})';

      return (
        success: true,
        pushed: pushedCount,
        pulled: pulledCount,
        message:
            'Синхронізація успішна! Вивантажено: $pushedCount, отримано: $pulledCount.$warningSuffix',
      );
    } catch (e) {
      return (
        success: false,
        pushed: pushedCount,
        pulled: pulledCount,
        message: 'Помилка синхронізації: $e',
      );
    }
  }

  /// Returns the complete PostgreSQL Schema to run in Supabase Dashboard
  static String getSqlSchema() {
    return '''-- ==============================================================================
-- VESTORA · Supabase PostgreSQL Schema with Row Level Security (RLS)
-- Run this in your Supabase Project: SQL Editor -> New Query -> Run
-- ==============================================================================

create extension if not exists "uuid-ossp";

-- 1. Profiles Table
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  email text,
  full_name text,
  avatar_url text,
  location text default 'Київ, Україна',
  preferred_style text default 'Quiet Luxury',
  currency text default 'UAH (₴)',
  size_system text default 'EUR / International',
  streak_days int default 14,
  created_at timestamptz default timezone('utc'::text, now()) not null,
  updated_at timestamptz default timezone('utc'::text, now()) not null
);

alter table public.profiles enable row level security;
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);
create policy "Users can delete own profile" on public.profiles for delete using (auth.uid() = id);

-- 2. Clothing Items Table
create table if not exists public.clothing_items (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  brand text not null,
  category text not null,
  season text not null,
  color text not null,
  price numeric(12, 2) default 0.00,
  currency text default 'UAH',
  image_url text not null,
  gallery_images text[] default array[]::text[],
  source_url text,
  store_name text,
  fabric_composition text,
  size text,
  country_of_origin text,
  care_instructions text,
  label_photo_url text,
  receipt_photo_url text,
  wear_count int default 0,
  purchase_date timestamptz default timezone('utc'::text, now()),
  notes text,
  updated_at timestamptz default timezone('utc'::text, now()) not null
);

alter table public.clothing_items enable row level security;
create policy "Users can view own clothes" on public.clothing_items for select using (auth.uid() = user_id);
create policy "Users can insert own clothes" on public.clothing_items for insert with check (auth.uid() = user_id);
create policy "Users can update own clothes" on public.clothing_items for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own clothes" on public.clothing_items for delete using (auth.uid() = user_id);

create index if not exists idx_clothing_items_user_id on public.clothing_items(user_id);
create index if not exists idx_clothing_items_category on public.clothing_items(category);
create index if not exists idx_clothing_items_season on public.clothing_items(season);

-- 3. Outfits Table
create table if not exists public.outfits (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  planned_date date,
  occasion text,
  weather_temp int,
  weather_condition text,
  aesthetic_vibe text,
  is_favorite boolean default false,
  is_worn boolean default false,
  comfort_score int default 95,
  item_ids text[] default array[]::text[],
  notes text,
  created_at timestamptz default timezone('utc'::text, now()) not null,
  updated_at timestamptz default timezone('utc'::text, now()) not null
);

alter table public.outfits enable row level security;
create policy "Users can manage own outfits" on public.outfits for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create index if not exists idx_outfits_user_id on public.outfits(user_id);

-- 4. Wear Logs Table
create table if not exists public.wear_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  item_id text references public.clothing_items(id) on delete cascade not null,
  worn_on date default current_date not null,
  created_at timestamptz default timezone('utc'::text, now()) not null
);

alter table public.wear_logs enable row level security;
create policy "Users can manage own wear logs" on public.wear_logs for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create index if not exists idx_wear_logs_user_id on public.wear_logs(user_id);

-- 5. Storage Bucket (Per-User Folder Isolation + 5 MB / Image MIME Guardrails)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('vestora-wardrobe', 'vestora-wardrobe', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

create policy "Public can view wardrobe photos" on storage.objects for select using (bucket_id = 'vestora-wardrobe');
create policy "Authenticated users can upload own wardrobe photos" on storage.objects for insert with check (bucket_id = 'vestora-wardrobe' and auth.role() = 'authenticated' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Authenticated users can update own wardrobe photos" on storage.objects for update using (bucket_id = 'vestora-wardrobe' and auth.role() = 'authenticated' and (storage.foldername(name))[1] = auth.uid()::text) with check (bucket_id = 'vestora-wardrobe' and auth.role() = 'authenticated' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Authenticated users can delete own wardrobe photos" on storage.objects for delete using (bucket_id = 'vestora-wardrobe' and auth.role() = 'authenticated' and (storage.foldername(name))[1] = auth.uid()::text);

-- 6. Self-Service Account Deletion RPC (App Store Guideline 5.1.1(v) & Google Play Compliance)
create or replace function public.delete_own_user()
returns void
language plpgsql
security definer
set search_path = public
as \$\$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  delete from auth.users where id = auth.uid();
end;
\$\$;

revoke all on function public.delete_own_user() from public, anon;
grant execute on function public.delete_own_user() to authenticated;
''';
  }
}
