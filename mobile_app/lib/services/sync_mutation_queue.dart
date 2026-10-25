import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SyncMutationAction {
  upsertItem,
  deleteItem,
  insertWearLog,
  upsertOutfit,
  deleteOutfit,
}

class SyncMutation {
  final String id;
  final SyncMutationAction action;
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retryCount;

  SyncMutation({
    required this.id,
    required this.action,
    required this.entityId,
    required this.payload,
    DateTime? createdAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  Map<String, dynamic> toMap() => {
        'id': id,
        'action': action.name,
        'entityId': entityId,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory SyncMutation.fromMap(Map<String, dynamic> map) => SyncMutation(
        id: map['id']?.toString() ?? '',
        action: SyncMutationAction.values.firstWhere(
          (e) => e.name == map['action'],
          orElse: () => SyncMutationAction.upsertItem,
        ),
        entityId: map['entityId']?.toString() ?? '',
        payload: Map<String, dynamic>.from(map['payload'] ?? {}),
        createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
            DateTime.now().toUtc(),
        retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      );
}

class SyncMutationQueue {
  static const String _storageKey = 'vestora_sync_mutation_queue';
  static final List<SyncMutation> _mutations = [];
  static bool _isLoaded = false;

  /// Loads queued offline mutations from SharedPreferences into memory.
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      _mutations.clear();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        for (final item in decoded) {
          if (item is Map) {
            _mutations.add(SyncMutation.fromMap(Map<String, dynamic>.from(item)));
          }
        }
      }
      _isLoaded = true;
    } catch (_) {
      _mutations.clear();
      _isLoaded = true;
    }
  }

  /// Number of mutations currently awaiting sync.
  static int get pendingCount => _mutations.length;

  /// Immutable list of pending mutations.
  static List<SyncMutation> get pendingMutations =>
      List<SyncMutation>.unmodifiable(_mutations);

  /// Enqueues a new mutation with conflict-coalescing.
  static Future<void> enqueue(SyncMutation mutation) async {
    if (!_isLoaded) await initialize();

    // Coalesce mutations for the same entity to keep the queue minimal
    if (mutation.action == SyncMutationAction.deleteItem) {
      _mutations.removeWhere((m) =>
          m.entityId == mutation.entityId &&
          (m.action == SyncMutationAction.upsertItem ||
              m.action == SyncMutationAction.deleteItem));
      _mutations.add(mutation);
    } else if (mutation.action == SyncMutationAction.upsertItem) {
      final existingIdx = _mutations.indexWhere(
          (m) => m.entityId == mutation.entityId && m.action == SyncMutationAction.upsertItem);
      if (existingIdx >= 0) {
        _mutations[existingIdx] = mutation;
      } else {
        _mutations.removeWhere((m) =>
            m.entityId == mutation.entityId && m.action == SyncMutationAction.deleteItem);
        _mutations.add(mutation);
      }
    } else {
      _mutations.add(mutation);
    }

    await _persist();
  }

  /// Removes a mutation by ID upon successful execution.
  static Future<void> remove(String mutationId) async {
    _mutations.removeWhere((m) => m.id == mutationId);
    await _persist();
  }

  /// Clears all queued mutations.
  static Future<void> clear() async {
    _mutations.clear();
    await _persist();
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_mutations.isEmpty) {
        await prefs.remove(_storageKey);
      } else {
        final encoded = jsonEncode(_mutations.map((m) => m.toMap()).toList());
        await prefs.setString(_storageKey, encoded);
      }
    } catch (_) {}
  }

  /// Flushes pending mutations in FIFO order against Supabase.
  /// Halts and retains remaining queue if a network failure occurs.
  static Future<({int executed, int failed, String? lastError})> flush({
    required SupabaseClient client,
    required String userId,
  }) async {
    if (!_isLoaded) await initialize();
    if (_mutations.isEmpty) {
      return (executed: 0, failed: 0, lastError: null);
    }

    int executedCount = 0;
    final toRemove = <String>[];

    for (final mutation in List<SyncMutation>.from(_mutations)) {
      try {
        switch (mutation.action) {
          case SyncMutationAction.upsertItem:
            await client.from('clothing_items').upsert(mutation.payload);
            break;
          case SyncMutationAction.deleteItem:
            await client
                .from('clothing_items')
                .delete()
                .eq('user_id', userId)
                .eq('id', mutation.entityId);
            break;
          case SyncMutationAction.insertWearLog:
            await client.from('wear_logs').insert(mutation.payload);
            break;
          case SyncMutationAction.upsertOutfit:
            await client.from('outfits').upsert(mutation.payload);
            break;
          case SyncMutationAction.deleteOutfit:
            await client
                .from('outfits')
                .delete()
                .eq('user_id', userId)
                .eq('id', mutation.entityId);
            break;
        }

        toRemove.add(mutation.id);
        executedCount++;
      } catch (e) {
        mutation.retryCount++;
        await _persist();
        if (kDebugMode) {
          debugPrint('SyncMutationQueue flush halted on error: $e');
        }
        // Remove successfully executed mutations before returning error
        for (final id in toRemove) {
          _mutations.removeWhere((m) => m.id == id);
        }
        await _persist();
        return (
          executed: executedCount,
          failed: _mutations.length,
          lastError: e.toString(),
        );
      }
    }

    for (final id in toRemove) {
      _mutations.removeWhere((m) => m.id == id);
    }
    await _persist();

    return (executed: executedCount, failed: 0, lastError: null);
  }
}
