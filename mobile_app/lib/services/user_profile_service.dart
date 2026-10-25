import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class UserProfile {
  String name;
  String email;
  String phone;
  String location;
  String avatarUrl;
  String? tryOnFaceUrl;
  String currency;
  String sizeSystem;
  String preferredStyle;

  // Notification settings
  bool pushDailyStylist;
  bool pushStreakReminder;
  bool pushFabricCare;
  bool emailMonthlyDigest;
  bool emailEcoReport;

  // Security
  bool twoFactorAuth;
  String passwordHash;

  UserProfile({
    this.name = 'Сергій',
    this.email = 'sergij@vestora.app',
    this.phone = '+380 (50) 123-45-67',
    this.location = 'Київ, Україна',
    this.avatarUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
    this.tryOnFaceUrl,
    this.currency = 'UAH (₴)',
    this.sizeSystem = 'EUR / International',
    this.preferredStyle = 'Quiet Luxury · Стриманий мінімалізм',
    this.pushDailyStylist = true,
    this.pushStreakReminder = true,
    this.pushFabricCare = true,
    this.emailMonthlyDigest = true,
    this.emailEcoReport = true,
    this.twoFactorAuth = false,
    this.passwordHash = '',
  });
}

class UserProfileService {
  static const _keyName = 'vestora_profile_name';
  static const _keyEmail = 'vestora_profile_email';
  static const _keyPhone = 'vestora_profile_phone';
  static const _keyLocation = 'vestora_profile_location';
  static const _keyCurrency = 'vestora_profile_currency';
  static const _keySizeSystem = 'vestora_profile_size_system';
  static const _keyStyle = 'vestora_profile_style';
  static const _keyTryOnFace = 'vestora_profile_tryon_face';

  static const _keyPushDaily = 'vestora_notif_push_daily';
  static const _keyPushStreak = 'vestora_notif_push_streak';
  static const _keyPushCare = 'vestora_notif_push_care';
  static const _keyEmailDigest = 'vestora_notif_email_digest';
  static const _keyEmailEco = 'vestora_notif_email_eco';
  static const _key2FA = 'vestora_sec_2fa';

  static final UserProfile _current = UserProfile();

  static UserProfile get profile => _current;

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _current.name = prefs.getString(_keyName) ?? 'Сергій';
      _current.email = prefs.getString(_keyEmail) ?? 'sergij@vestora.app';
      _current.phone = prefs.getString(_keyPhone) ?? '+380 (50) 123-45-67';
      _current.location = prefs.getString(_keyLocation) ?? 'Київ, Україна';
      _current.currency = prefs.getString(_keyCurrency) ?? 'UAH (₴)';
      _current.sizeSystem = prefs.getString(_keySizeSystem) ?? 'EUR / International';
      _current.preferredStyle = prefs.getString(_keyStyle) ?? 'Quiet Luxury · Стриманий мінімалізм';
      _current.tryOnFaceUrl = prefs.getString(_keyTryOnFace);

      _current.pushDailyStylist = prefs.getBool(_keyPushDaily) ?? true;
      _current.pushStreakReminder = prefs.getBool(_keyPushStreak) ?? true;
      _current.pushFabricCare = prefs.getBool(_keyPushCare) ?? true;
      _current.emailMonthlyDigest = prefs.getBool(_keyEmailDigest) ?? true;
      _current.emailEcoReport = prefs.getBool(_keyEmailEco) ?? true;
      _current.twoFactorAuth = prefs.getBool(_key2FA) ?? false;
    } catch (_) {}
  }

  static Future<void> saveProfile({
    String? name,
    String? email,
    String? phone,
    String? location,
    String? currency,
    String? sizeSystem,
    String? preferredStyle,
  }) async {
    if (name != null) _current.name = name;
    if (email != null) _current.email = email;
    if (phone != null) _current.phone = phone;
    if (location != null) _current.location = location;
    if (currency != null) _current.currency = currency;
    if (sizeSystem != null) _current.sizeSystem = sizeSystem;
    if (preferredStyle != null) _current.preferredStyle = preferredStyle;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyName, _current.name);
      await prefs.setString(_keyEmail, _current.email);
      await prefs.setString(_keyPhone, _current.phone);
      await prefs.setString(_keyLocation, _current.location);
      await prefs.setString(_keyCurrency, _current.currency);
      await prefs.setString(_keySizeSystem, _current.sizeSystem);
      await prefs.setString(_keyStyle, _current.preferredStyle);
    } catch (_) {}
  }

  static Future<void> saveTryOnFace(String faceUrl) async {
    _current.tryOnFaceUrl = faceUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyTryOnFace, faceUrl);
    } catch (_) {}
  }

  static Future<void> saveNotifications({
    bool? pushDailyStylist,
    bool? pushStreakReminder,
    bool? pushFabricCare,
    bool? emailMonthlyDigest,
    bool? emailEcoReport,
  }) async {
    if (pushDailyStylist != null) _current.pushDailyStylist = pushDailyStylist;
    if (pushStreakReminder != null) _current.pushStreakReminder = pushStreakReminder;
    if (pushFabricCare != null) _current.pushFabricCare = pushFabricCare;
    if (emailMonthlyDigest != null) _current.emailMonthlyDigest = emailMonthlyDigest;
    if (emailEcoReport != null) _current.emailEcoReport = emailEcoReport;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPushDaily, _current.pushDailyStylist);
      await prefs.setBool(_keyPushStreak, _current.pushStreakReminder);
      await prefs.setBool(_keyPushCare, _current.pushFabricCare);
      await prefs.setBool(_keyEmailDigest, _current.emailMonthlyDigest);
      await prefs.setBool(_keyEmailEco, _current.emailEcoReport);
    } catch (_) {}
  }

  static Future<void> setTwoFactor(bool enabled) async {
    _current.twoFactorAuth = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key2FA, enabled);
    } catch (_) {}
  }

  static Future<({bool success, String message})> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return AuthService.instance.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  /// Reconciles cloud `public.profiles` fields into local profile without clobbering customized local fields
  /// unless `preferCloud` is true (e.g., pull-only restore on a new device).
  static Future<void> reconcileCloudProfile(
    Map<String, dynamic> row, {
    bool preferCloud = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cloudName = (row['full_name'] as String?)?.trim();
      final cloudEmail = (row['email'] as String?)?.trim();
      final cloudAvatar = (row['avatar_url'] as String?)?.trim();
      final cloudLocation = (row['location'] as String?)?.trim();
      final cloudStyle = (row['preferred_style'] as String?)?.trim();
      final cloudCurrency = (row['currency'] as String?)?.trim();
      final cloudSize = (row['size_system'] as String?)?.trim();

      var changed = false;
      if (cloudName != null &&
          cloudName.isNotEmpty &&
          (preferCloud || !prefs.containsKey(_keyName) || _current.name == 'Гість' || _current.name == 'Сергій')) {
        _current.name = cloudName;
        changed = true;
      }
      if (cloudEmail != null &&
          cloudEmail.isNotEmpty &&
          (preferCloud || !prefs.containsKey(_keyEmail) || _current.email.isEmpty)) {
        _current.email = cloudEmail;
        changed = true;
      }
      if (cloudAvatar != null && cloudAvatar.isNotEmpty && preferCloud) {
        _current.avatarUrl = cloudAvatar;
      }
      if (cloudLocation != null &&
          cloudLocation.isNotEmpty &&
          (preferCloud || !prefs.containsKey(_keyLocation))) {
        _current.location = cloudLocation;
        changed = true;
      }
      if (cloudStyle != null &&
          cloudStyle.isNotEmpty &&
          (preferCloud || !prefs.containsKey(_keyStyle))) {
        _current.preferredStyle = cloudStyle;
        changed = true;
      }
      if (cloudCurrency != null &&
          cloudCurrency.isNotEmpty &&
          (preferCloud || !prefs.containsKey(_keyCurrency))) {
        _current.currency = cloudCurrency;
        changed = true;
      }
      if (cloudSize != null &&
          cloudSize.isNotEmpty &&
          (preferCloud || !prefs.containsKey(_keySizeSystem))) {
        _current.sizeSystem = cloudSize;
        changed = true;
      }

      if (changed) {
        await saveProfile();
      }
    } catch (_) {}
  }

  /// Wipes all stored profile PII and preferences (for 1-click Account Deletion)
  static Future<void> clearAllData() async {
    _current.name = 'Гість';
    _current.email = '';
    _current.phone = '';
    _current.location = 'Київ, Україна';
    _current.tryOnFaceUrl = null;
    _current.currency = 'UAH (₴)';
    _current.sizeSystem = 'EUR / International';
    _current.preferredStyle = 'Quiet Luxury · Стриманий мінімалізм';
    _current.pushDailyStylist = false;
    _current.pushStreakReminder = false;
    _current.pushFabricCare = false;
    _current.emailMonthlyDigest = false;
    _current.emailEcoReport = false;
    _current.twoFactorAuth = false;
    _current.passwordHash = '';

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in [
        _keyName,
        _keyEmail,
        _keyPhone,
        _keyLocation,
        _keyCurrency,
        _keySizeSystem,
        _keyStyle,
        _keyTryOnFace,
        _keyPushDaily,
        _keyPushStreak,
        _keyPushCare,
        _keyEmailDigest,
        _keyEmailEco,
        _key2FA,
      ]) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}
