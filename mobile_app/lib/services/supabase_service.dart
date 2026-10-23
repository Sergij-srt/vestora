import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clothing_item.dart';
import 'wardrobe_provider.dart';

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

  /// Loads saved configuration and initializes Supabase client safely
  static Future<bool> initialize({String? customUrl, String? customAnonKey}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _configuredUrl = customUrl ?? prefs.getString(_keySupabaseUrl);
      _configuredAnonKey = customAnonKey ?? prefs.getString(_keySupabaseAnonKey);
      _autoSyncEnabled = prefs.getBool(_keyAutoSync) ?? true;

      if (!isConfigured) {
        _isInitialized = false;
        return false;
      }

      // Check if already initialized with the same URL
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

  /// Saves Supabase credentials and re-initializes
  static Future<bool> saveCredentials({
    required String url,
    required String anonKey,
    bool autoSync = true,
  }) async {
    final cleanUrl = url.trim();
    final cleanKey = anonKey.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySupabaseUrl, cleanUrl);
      await prefs.setString(_keySupabaseAnonKey, cleanKey);
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

  /// Full bidirectional synchronization (Local ⇄ Supabase Cloud)
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

    final userId = currentUserId!;
    int pushedCount = 0;
    int pulledCount = 0;

    try {
      // 1. Push local items to Supabase PostgreSQL
      if (pushLocal && wardrobe.items.isNotEmpty) {
        final payload = wardrobe.items.map((item) {
          final map = item.toMap();
          map['user_id'] = userId;
          map['updated_at'] = DateTime.now().toUtc().toIso8601String();
          return map;
        }).toList();

        await cli.from('clothing_items').upsert(payload);
        pushedCount = payload.length;
      }

      // 2. Pull cloud items from Supabase PostgreSQL
      if (pullCloud) {
        final response = await cli
            .from('clothing_items')
            .select()
            .eq('user_id', userId);

        final cloudList = (response as List).cast<Map<String, dynamic>>();
        final localIds = wardrobe.items.map((e) => e.id).toSet();
        final newItemsToMerge = <ClothingItem>[];

        for (final row in cloudList) {
          final id = row['id'] as String?;
          if (id != null && !localIds.contains(id)) {
            newItemsToMerge.add(ClothingItem.fromMap(row));
          }
        }

        if (newItemsToMerge.isNotEmpty) {
          await wardrobe.addMultipleItems(newItemsToMerge);
          pulledCount = newItemsToMerge.length;
        }
      }

      return (
        success: true,
        pushed: pushedCount,
        pulled: pulledCount,
        message: 'Синхронізація успішна! Вивантажено: $pushedCount, отримано: $pulledCount.',
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
  preferred_style text default 'Quiet Luxury',
  currency text default 'UAH (₴)',
  size_system text default 'EUR / International',
  streak_days int default 14,
  created_at timestamptz default timezone('utc'::text, now()) not null,
  updated_at timestamptz default timezone('utc'::text, now()) not null
);

alter table public.profiles enable row level security;
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);

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
  wear_count int default 0,
  purchase_date timestamptz default timezone('utc'::text, now()),
  notes text,
  updated_at timestamptz default timezone('utc'::text, now()) not null
);

alter table public.clothing_items enable row level security;
create policy "Users can view own clothes" on public.clothing_items for select using (auth.uid() = user_id);
create policy "Users can insert own clothes" on public.clothing_items for insert with check (auth.uid() = user_id);
create policy "Users can update own clothes" on public.clothing_items for update using (auth.uid() = user_id);
create policy "Users can delete own clothes" on public.clothing_items for delete using (auth.uid() = user_id);

create index if not exists idx_clothing_items_user_id on public.clothing_items(user_id);
create index if not exists idx_clothing_items_category on public.clothing_items(category);
create index if not exists idx_clothing_items_season on public.clothing_items(season);

-- 3. Outfits Table
create table if not exists public.outfits (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  aesthetic_vibe text,
  is_favorite boolean default false,
  comfort_score int default 95,
  item_ids text[] default array[]::text[],
  created_at timestamptz default timezone('utc'::text, now()) not null
);

alter table public.outfits enable row level security;
create policy "Users can manage own outfits" on public.outfits for all using (auth.uid() = user_id);

-- 4. Wear Logs Table
create table if not exists public.wear_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  item_id text references public.clothing_items(id) on delete cascade not null,
  worn_on date default current_date not null,
  created_at timestamptz default timezone('utc'::text, now()) not null
);

alter table public.wear_logs enable row level security;
create policy "Users can manage own wear logs" on public.wear_logs for all using (auth.uid() = user_id);

-- 5. Storage Bucket
insert into storage.buckets (id, name, public) values ('vestora-wardrobe', 'vestora-wardrobe', true) on conflict (id) do nothing;
create policy "Public can view wardrobe photos" on storage.objects for select using (bucket_id = 'vestora-wardrobe');
create policy "Authenticated users can upload wardrobe photos" on storage.objects for insert with check (bucket_id = 'vestora-wardrobe' and auth.role() = 'authenticated');
''';
  }
}
