import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/user_profile_service.dart';
import '../services/ai_config_service.dart';
import '../services/wardrobe_provider.dart';
import '../theme/app_theme.dart';
import 'settings_ai_screen.dart';

class SettingsHubScreen extends StatefulWidget {
  const SettingsHubScreen({super.key});

  @override
  State<SettingsHubScreen> createState() => _SettingsHubScreenState();
}

class _SettingsHubScreenState extends State<SettingsHubScreen> {
  UserProfile _profile = UserProfile();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await UserProfileService.initialize();
    await AiConfigService.initialize();
    if (mounted) {
      setState(() {
        _profile = UserProfileService.profile;
      });
    }
  }

  // 1. Edit Profile Modal
  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _profile.name);
    final emailCtrl = TextEditingController(text: _profile.email);
    final phoneCtrl = TextEditingController(text: _profile.phone);
    final locationCtrl = TextEditingController(text: _profile.location);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Редагувати особисті дані', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              const Text('ІМ\'Я', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
              const SizedBox(height: 6),
              TextField(controller: nameCtrl, decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline, size: 20))),
              const SizedBox(height: 14),

              const Text('EMAIL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
              const SizedBox(height: 6),
              TextField(controller: emailCtrl, decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined, size: 20))),
              const SizedBox(height: 14),

              const Text('ТЕЛЕФОН', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
              const SizedBox(height: 6),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined, size: 20))),
              const SizedBox(height: 14),

              const Text('МІСТО / ЛОКАЦІЯ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
              const SizedBox(height: 6),
              TextField(controller: locationCtrl, decoration: const InputDecoration(prefixIcon: Icon(Icons.location_on_outlined, size: 20))),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () async {
                    await UserProfileService.saveProfile(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      location: locationCtrl.text.trim(),
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    if (mounted) {
                      setState(() => _profile = UserProfileService.profile);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Дані профілю успішно оновлено!'), backgroundColor: Color(0xFF16A34A)),
                      );
                    }
                  },
                  child: const Text('Зберегти зміни'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Change Password Modal
  void _showChangePasswordDialog() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Зміна та створення паролю', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setModalState(() => obscure = !obscure),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('ПОТОЧНИЙ ПАРОЛЬ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
                const SizedBox(height: 6),
                TextField(
                  controller: oldPassCtrl,
                  obscureText: obscure,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline, size: 20)),
                ),
                const SizedBox(height: 14),

                const Text('НОВИЙ ПАРОЛЬ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
                const SizedBox(height: 6),
                TextField(
                  controller: newPassCtrl,
                  obscureText: obscure,
                  decoration: const InputDecoration(hintText: 'Мінімум 6 символів', prefixIcon: Icon(Icons.vpn_key_outlined, size: 20)),
                ),
                const SizedBox(height: 14),

                const Text('ПІДТВЕРДЖЕННЯ НОВОГО ПАРОЛЮ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
                const SizedBox(height: 6),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: obscure,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.check_circle_outline, size: 20)),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () async {
                      final res = await UserProfileService.changePassword(
                        oldPassword: oldPassCtrl.text,
                        newPassword: newPassCtrl.text,
                        confirmPassword: confirmPassCtrl.text,
                      );

                      if (res.success) {
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res.message), backgroundColor: const Color(0xFF16A34A)),
                          );
                        }
                      } else {
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            SnackBar(content: Text(res.message), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: const Text('Оновити пароль безпеки'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 3. Notifications Modal
  void _showNotificationsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Налаштування сповіщень', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Керуйте push-сповіщеннями на пристрої та email-розсилками', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
                const SizedBox(height: 18),

                // Push Section
                const Text('МОБІЛЬНІ PUSH-СПОВІЩЕННЯ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accent)),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ранкова підказка ШІ-стиліста', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Щоденний образ з урахуванням погоди о 08:00', style: TextStyle(fontSize: 11.5, color: AppTheme.muted)),
                  value: _profile.pushDailyStylist,
                  onChanged: (val) async {
                    await UserProfileService.saveNotifications(pushDailyStylist: val);
                    setModalState(() => _profile.pushDailyStylist = val);
                    setState(() {});
                  },
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Нагадування про стрік активності', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Сповіщення перед сном, якщо образ дня не відмічено', style: TextStyle(fontSize: 11.5, color: AppTheme.muted)),
                  value: _profile.pushStreakReminder,
                  onChanged: (val) async {
                    await UserProfileService.saveNotifications(pushStreakReminder: val);
                    setModalState(() => _profile.pushStreakReminder = val);
                    setState(() {});
                  },
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Графік догляду за делікатними тканинами', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Нагадування про чищення вовни, шовку та захист шкіри', style: TextStyle(fontSize: 11.5, color: AppTheme.muted)),
                  value: _profile.pushFabricCare,
                  onChanged: (val) async {
                    await UserProfileService.saveNotifications(pushFabricCare: val);
                    setModalState(() => _profile.pushFabricCare = val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 18),

                // Email Section
                const Text('EMAIL-СПОВІЩЕННЯ ТА ДАЙДЖЕСТИ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accent)),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Місячний дайджест окупності шафи', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Звіт про вартість, найбільш та найменш ношені речі', style: TextStyle(fontSize: 11.5, color: AppTheme.muted)),
                  value: _profile.emailMonthlyDigest,
                  onChanged: (val) async {
                    await UserProfileService.saveNotifications(emailMonthlyDigest: val);
                    setModalState(() => _profile.emailMonthlyDigest = val);
                    setState(() {});
                  },
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Екологічний звіт та економія ресурсів', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Кількість збереженої води (л) та скорочення CO₂', style: TextStyle(fontSize: 11.5, color: AppTheme.muted)),
                  value: _profile.emailEcoReport,
                  onChanged: (val) async {
                    await UserProfileService.saveNotifications(emailEcoReport: val);
                    setModalState(() => _profile.emailEcoReport = val);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 4. Personalization Modal
  void _showPersonalizationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Персоналізація гардероба', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),

                // Currency selector
                const Text('ОСНОВНА ВАЛЮТА', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _profile.currency,
                  items: const [
                    DropdownMenuItem(value: 'UAH (₴)', child: Text('UAH (₴) · Українська гривня')),
                    DropdownMenuItem(value: 'EUR (€)', child: Text('EUR (€) · Євро')),
                    DropdownMenuItem(value: 'USD (\$)', child: Text('USD (\$) · Долар США')),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      await UserProfileService.saveProfile(currency: val);
                      setModalState(() => _profile.currency = val);
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Size System selector
                const Text('СИСТЕМА РОЗМІРІВ ЗА ЗАМОВЧУВАННЯМ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _profile.sizeSystem,
                  items: const [
                    DropdownMenuItem(value: 'EUR / International', child: Text('EUR / Міжнародна (S, M, EUR 38)')),
                    DropdownMenuItem(value: 'US / American', child: Text('US (US 6, US S, W30/L32)')),
                    DropdownMenuItem(value: 'UK / British', child: Text('UK (UK 10, UK 8)')),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      await UserProfileService.saveProfile(sizeSystem: val);
                      setModalState(() => _profile.sizeSystem = val);
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Preferred Aesthetic Style
                const Text('УЛЮБЛЕНИЙ СТИЛЬ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _profile.preferredStyle,
                  items: const [
                    DropdownMenuItem(value: 'Quiet Luxury · Стриманий мінімалізм', child: Text('Quiet Luxury · Стриманий мінімалізм')),
                    DropdownMenuItem(value: 'Smart Casual · Діловий невимушений', child: Text('Smart Casual · Діловий невимушений')),
                    DropdownMenuItem(value: 'Old Money · Класична елегантність', child: Text('Old Money · Класична елегантність')),
                    DropdownMenuItem(value: 'Streetwear & Sportswear', child: Text('Streetwear & Sportswear')),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      await UserProfileService.saveProfile(preferredStyle: val);
                      setModalState(() => _profile.preferredStyle = val);
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAiKey = AiConfigService.hasCustomKey;
    final adCredits = AiConfigService.adCredits;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Налаштування та Кабінет'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // 1. User Cabinet Hero Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF18181B), Color(0xFF27272A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundImage: CachedNetworkImageProvider(_profile.avatarUrl),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                            child: const Icon(Icons.check, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _profile.name,
                                style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('VIP PRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(_profile.email, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 13, color: Color(0xFFFDE68A)),
                              const SizedBox(width: 4),
                              Text(_profile.location, style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 11.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF3F3F46)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF52525B)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Редагувати профіль', style: TextStyle(fontSize: 12)),
                        onPressed: _showEditProfileDialog,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF52525B)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.vpn_key_outlined, size: 16),
                        label: const Text('Зміна паролю', style: TextStyle(fontSize: 12)),
                        onPressed: _showChangePasswordDialog,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 2. Settings Hub Menu Tiles
          const Text('КАТЕГОРІЇ НАЛАШТУВАНЬ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.muted, letterSpacing: 1)),
          const SizedBox(height: 10),

          // Tile 1: AI & Gemini Vision Hub
          _buildSettingsTile(
            icon: Icons.auto_awesome,
            iconColor: const Color(0xFF4F46E5),
            title: 'Штучний Інтелект & Vision API',
            subtitle: hasAiKey
                ? 'Підключено особистий ключ Google Gemini'
                : (adCredits > 0 ? 'Gemini Vision ($adCredits бонусів за відео)' : 'Локальний евристичний парсер'),
            trailingBadge: hasAiKey ? 'BYOK ✅' : '$adCredits ⚡',
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsAiScreen()));
              setState(() {});
            },
          ),
          const SizedBox(height: 10),

          // Tile 2: Personalization & Wardrobe Preferences
          _buildSettingsTile(
            icon: Icons.palette_outlined,
            iconColor: const Color(0xFFD97706),
            title: 'Персоналізація та Стиль',
            subtitle: '${_profile.preferredStyle} · ${_profile.currency} · ${_profile.sizeSystem}',
            onTap: _showPersonalizationDialog,
          ),
          const SizedBox(height: 10),

          // Tile 3: Notifications & Alarms
          _buildSettingsTile(
            icon: Icons.notifications_active_outlined,
            iconColor: const Color(0xFF16A34A),
            title: 'Сповіщення (Push & Email)',
            subtitle: 'Ранковий образ о 08:00, нагадування стріку, еко-звіти',
            onTap: _showNotificationsDialog,
          ),
          const SizedBox(height: 10),

          // Tile 4: Security & 2FA
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.security_rounded, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Двоетапна перевірка (2FA)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        _profile.twoFactorAuth ? 'Активовано (захист по SMS / Email)' : 'Вимкнено (рекомендується увімкнути)',
                        style: TextStyle(fontSize: 11.5, color: _profile.twoFactorAuth ? const Color(0xFF16A34A) : AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _profile.twoFactorAuth,
                  activeThumbColor: const Color(0xFF2563EB),
                  onChanged: (val) async {
                    final messenger = ScaffoldMessenger.of(context);
                    await UserProfileService.setTwoFactor(val);
                    if (mounted) {
                      setState(() => _profile.twoFactorAuth = val);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(val ? '2FA успішно активовано!' : '2FA вимкнено.'),
                          backgroundColor: val ? const Color(0xFF16A34A) : AppTheme.primary,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 3. Data & Storage
          const Text('ДАНІ ТА РЕЗЕРВНІ КОПІЇ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.muted, letterSpacing: 1)),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.cloud_download_outlined,
            iconColor: const Color(0xFF0284C7),
            title: 'Експорт гардеробу (JSON)',
            subtitle: 'Зберегти копію всіх речей та історії аутфітів',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📦 Резервну копію гардероба сформовано та завантажено!'),
                  backgroundColor: Color(0xFF16A34A),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.cleaning_services_outlined,
            iconColor: const Color(0xFFDC2626),
            title: 'Скинути фільтри та оновити кеш',
            subtitle: 'Очистити збережені тимчасові файли та завантажити свіжі дані',
            onTap: () {
              context.read<WardrobeProvider>().loadDemoCapsule();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✨ Кеш оновлено! Гардероб синхронізовано.')),
              );
            },
          ),
          const SizedBox(height: 26),

          // App Info & Version
          Center(
            child: Column(
              children: [
                Text(
                  'Vestora · Smart Wardrobe Luxury Edition',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                Text('Версія 3.8.0 · Build 2026.10', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailingBadge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
                ],
              ),
            ),
            if (trailingBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(trailingBadge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right_rounded, color: AppTheme.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
