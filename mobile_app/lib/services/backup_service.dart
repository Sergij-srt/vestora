import 'dart:convert';
import '../models/clothing_item.dart';
import 'wardrobe_provider.dart';
import 'user_profile_service.dart';
import 'web_platform_stub.dart'
    if (dart.library.js_interop) 'web_platform_web.dart' as platform;

class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<ClothingItem> items;
  final int streakDays;
  final String? preferredStyle;
  final String? currency;
  final String? sizeSystem;
  final DateTime? exportedAt;

  const BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.items = const [],
    this.streakDays = 14,
    this.preferredStyle,
    this.currency,
    this.sizeSystem,
    this.exportedAt,
  });
}

class BackupService {
  static const String currentFormat = 'VESTORA_BACKUP';
  static const String currentVersion = '1.0';

  /// Generates structured JSON backup payload of the entire digital wardrobe
  static String generateBackupJson({
    required WardrobeProvider wardrobe,
    required UserProfile profile,
  }) {
    final now = DateTime.now();
    final Map<String, dynamic> payload = {
      'format': currentFormat,
      'version': currentVersion,
      'exportedAt': now.toIso8601String(),
      'appName': 'Vestora · Smart Wardrobe',
      'user': {
        'name': profile.name,
        'email': profile.email,
        'preferredStyle': profile.preferredStyle,
        'currency': profile.currency,
        'sizeSystem': profile.sizeSystem,
      },
      'streakDays': wardrobe.streakDays,
      'stats': {
        'totalItems': wardrobe.items.length,
        'totalWardrobeValue': wardrobe.totalWardrobeValue,
        'healthScore': wardrobe.healthReport.healthScore,
      },
      'items': wardrobe.items.map((item) => item.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Triggers client file download of the `.vestora` backup
  static void exportBackupFile({
    required WardrobeProvider wardrobe,
    required UserProfile profile,
  }) {
    final jsonContent = generateBackupJson(wardrobe: wardrobe, profile: profile);
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final filename = 'vestora_wardrobe_backup_$dateStr.vestora';

    platform.triggerFileDownload(filename, jsonContent);
  }

  /// Validates a raw backup JSON payload before restoring
  static BackupValidationResult validateBackup(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return const BackupValidationResult(
        isValid: false,
        errorMessage: 'Файл бекапу порожній.',
      );
    }

    try {
      final decoded = json.decode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: 'Некоректний формат JSON-структури.',
        );
      }

      final itemsRaw = decoded['items'];
      if (itemsRaw is! List) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: 'У файлі резервної копії відсутній список речей (items).',
        );
      }

      final List<ClothingItem> parsedItems = [];
      for (final it in itemsRaw) {
        if (it is Map<String, dynamic>) {
          parsedItems.add(ClothingItem.fromMap(it));
        }
      }

      final userMap = decoded['user'] as Map<String, dynamic>?;
      final streak = decoded['streakDays'] is int ? decoded['streakDays'] as int : 14;
      final exportedAtStr = decoded['exportedAt'] as String?;
      final exportedAt = exportedAtStr != null ? DateTime.tryParse(exportedAtStr) : null;

      return BackupValidationResult(
        isValid: true,
        items: parsedItems,
        streakDays: streak,
        preferredStyle: userMap?['preferredStyle'] as String?,
        currency: userMap?['currency'] as String?,
        sizeSystem: userMap?['sizeSystem'] as String?,
        exportedAt: exportedAt,
      );
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        errorMessage: 'Помилка читання резервної копії: $e',
      );
    }
  }

  /// Restores wardrobe and profile from a valid backup string
  static Future<({bool success, String message, int count})> restoreBackup({
    required WardrobeProvider wardrobe,
    required String rawJson,
    bool replaceAll = true,
  }) async {
    final validation = validateBackup(rawJson);
    if (!validation.isValid) {
      return (
        success: false,
        message: validation.errorMessage ?? 'Невідома помилка валідації.',
        count: 0,
      );
    }

    if (replaceAll) {
      await wardrobe.clearWardrobe();
      await wardrobe.addMultipleItems(validation.items);
    } else {
      // Merge only items with non-colliding IDs
      final existingIds = wardrobe.items.map((i) => i.id).toSet();
      final toAdd = validation.items.where((i) => !existingIds.contains(i.id)).toList();
      await wardrobe.addMultipleItems(toAdd);
    }

    // Restore profile settings if present
    if (validation.preferredStyle != null ||
        validation.currency != null ||
        validation.sizeSystem != null) {
      await UserProfileService.saveProfile(
        preferredStyle: validation.preferredStyle,
        currency: validation.currency,
        sizeSystem: validation.sizeSystem,
      );
    }

    return (
      success: true,
      message: 'Успішно відновлено ${validation.items.length} речей гардероба!',
      count: validation.items.length,
    );
  }
}
