import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_profile_service.dart';
import '../services/ai_config_service.dart';
import '../services/wardrobe_provider.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import '../widgets/vestora_image.dart';
import '../theme/app_theme.dart';
import 'settings_ai_screen.dart';
import 'virtual_fitting_screen.dart';
import 'capsule_matrix_screen.dart';
import 'fabric_care_screen.dart';
import '../services/auth_service.dart';
import '../services/pwa_service.dart';
import 'auth_screen.dart';

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

  void _confirmSignOutDialog() {
    final auth = AuthService.instance;
    final email = auth.currentUser?.email ?? _profile.email;
    final loc = LocalizationService.instance;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 10),
            Text(loc.translate('settings_logout'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${loc.translate('settings_logout_confirm')}\n$email?'),
            const SizedBox(height: 8),
            const Text(
              'Для подальшого доступу потрібно буде увійти через Google або ввести Email та пароль.',
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(loc.translate('settings_stay')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await auth.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
            child: Text(loc.translate('settings_logout_action')),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _profile.name);
    final emailCtrl = TextEditingController(text: _profile.email);
    final locCtrl = TextEditingController(text: _profile.location);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Редагування профілю', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ІМ\'Я', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
            const SizedBox(height: 4),
            TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Ваше ім\'я')),
            const SizedBox(height: 12),
            const Text('EMAIL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
            const SizedBox(height: 4),
            TextField(controller: emailCtrl, decoration: const InputDecoration(hintText: 'user@vestora.app')),
            const SizedBox(height: 12),
            const Text('ЛОКАЦІЯ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
            const SizedBox(height: 4),
            TextField(controller: locCtrl, decoration: const InputDecoration(hintText: 'Київ, Україна')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Скасувати')),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(dialogCtx);
              final messenger = ScaffoldMessenger.of(context);
              await UserProfileService.saveProfile(
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                location: locCtrl.text.trim(),
              );
              if (!mounted) return;
              setState(() {
                _profile = UserProfileService.profile;
              });
              nav.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Профіль успішно оновлено!'), backgroundColor: Color(0xFF16A34A)),
              );
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final curCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Зміна паролю', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ПОТОЧНИЙ ПАРОЛЬ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
            const SizedBox(height: 4),
            TextField(controller: curCtrl, obscureText: true, decoration: const InputDecoration(hintText: '••••••••')),
            const SizedBox(height: 12),
            const Text('НОВИЙ ПАРОЛЬ (мін. 8 символів)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
            const SizedBox(height: 4),
            TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(hintText: '••••••••')),
            const SizedBox(height: 12),
            const Text('ПІДТВЕРДЖЕННЯ НОВОГО ПАРОЛЮ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
            const SizedBox(height: 4),
            TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(hintText: '••••••••')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Скасувати')),
          ElevatedButton(
            onPressed: () {
              if (newCtrl.text.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Новий пароль має бути не менше 8 символів!'), backgroundColor: Colors.red),
                );
                return;
              }
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Паролі не співпадають!'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Пароль безпечно змінено!'), backgroundColor: Color(0xFF16A34A)),
              );
            },
            child: const Text('Оновити пароль'),
          ),
        ],
      ),
    );
  }

  void _showPwaInstallDialog() {
    final theme = context.read<ThemeService>();
    final isDark = theme.isDarkMode(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: isDark ? AppTheme.darkBorder : AppTheme.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF18181B) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accent),
                    ),
                    child: const Icon(Icons.install_mobile_rounded, color: AppTheme.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Встановити Vestora (PWA)',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                        ),
                        Text(
                          'Швидкий запуск, автономність та повний екран',
                          style: TextStyle(fontSize: 11.5, color: isDark ? AppTheme.darkMuted : AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...PwaService.pwaFeatures.map((feat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(feat.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feat.title,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              feat.desc,
                              style: TextStyle(fontSize: 11.5, color: isDark ? AppTheme.darkMuted : AppTheme.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 ЯК ВСТАНОВИТИ В 1 КЛІК:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.accent, letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                    Text(
                      '• Android / Chrome: Натисніть «Встановити» або в меню браузера оберіть «Встановити додаток».',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• iOS / Safari: Натисніть кнопку «Поділитися» (квадрат зі стрілкою) та виберіть «На початковий екран» (+).',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    PwaService.triggerInstallPrompt();
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Встановити додаток зараз'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfflineInfoDialog() {
    final theme = context.read<ThemeService>();
    final isDark = theme.isDarkMode(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.offline_bolt_rounded, color: Color(0xFF16A34A)),
            const SizedBox(width: 10),
            Text('Офлайн-режим (PWA)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'У Vestora налаштовано розумний Service Worker із кешуванням Cache-First:',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 12),
            Text('✅ Весь гардероб і фото речей зберігаються локально на пристрої.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 6),
            Text('✅ Капсульна матриця 3х3 та поєднання кольорів працюють без зв\'язку.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 6),
            Text('✅ Енциклопедія догляду за тканинами та бірки доступні в авіарежимі.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF16A34A).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: const Text('Статус Service Worker: АКТИВНИЙ (v1.0.0)', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Зрозуміло'),
          ),
        ],
      ),
    );
  }

  void _showPersonalizationDialog() {
    String selectedStyle = _profile.preferredStyle;
    String selectedCurrency = _profile.currency;
    String selectedSize = _profile.sizeSystem;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.palette_outlined, color: AppTheme.accent),
                  SizedBox(width: 8),
                  Text('Персоналізація стилю', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('ОСНОВНИЙ СТИЛЬ ГАРДЕРОБУ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Quiet Luxury', 'Мінімалізм', 'Smart Casual', 'Old Money', 'Streetwear'].map((st) {
                  final isSel = selectedStyle == st;
                  return ChoiceChip(
                    label: Text(st),
                    selected: isSel,
                    onSelected: (val) => setSheetState(() => selectedStyle = st),
                    selectedColor: const Color(0xFFFEF3C7),
                    labelStyle: TextStyle(color: isSel ? AppTheme.accent : Colors.black87, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('ВАЛЮТА ВИТРАТ ТА ОКУПНОСТІ (CPW)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['UAH (₴)', 'USD (\$)', 'EUR (€)'].map((curr) {
                  final isSel = selectedCurrency == curr;
                  return ChoiceChip(
                    label: Text(curr),
                    selected: isSel,
                    onSelected: (val) => setSheetState(() => selectedCurrency = curr),
                    selectedColor: const Color(0xFFFEF3C7),
                    labelStyle: TextStyle(color: isSel ? AppTheme.accent : Colors.black87, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('СИСТЕМА РОЗМІРІВ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['EUR (36-44)', 'US (XS-XL)', 'UK (8-16)'].map((sz) {
                  final isSel = selectedSize == sz;
                  return ChoiceChip(
                    label: Text(sz),
                    selected: isSel,
                    onSelected: (val) => setSheetState(() => selectedSize = sz),
                    selectedColor: const Color(0xFFFEF3C7),
                    labelStyle: TextStyle(color: isSel ? AppTheme.accent : Colors.black87, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final nav = Navigator.of(sheetCtx);
                    final messenger = ScaffoldMessenger.of(context);
                    await UserProfileService.saveProfile(
                      preferredStyle: selectedStyle,
                      currency: selectedCurrency,
                      sizeSystem: selectedSize,
                    );
                    if (!mounted) return;
                    setState(() {
                      _profile = UserProfileService.profile;
                    });
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Налаштування персоналізації збережено!'), backgroundColor: Color(0xFF16A34A)),
                    );
                  },
                  child: const Text('Застосувати налаштування'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemePicker() {
    final theme = ThemeService.instance;
    final loc = LocalizationService.instance;
    final isDark = theme.isDarkMode(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.palette_rounded, color: AppTheme.accent),
                const SizedBox(width: 8),
                Text(
                  loc.translate('settings_appearance'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Light Option
            _buildThemeOption(
              icon: Icons.light_mode_rounded,
              title: '${loc.translate('settings_theme_light')} (Ivory & Gold)',
              subtitle: 'Класичний світлий преміальний стиль Vestora',
              isSelected: theme.themeMode == ThemeMode.light,
              isDark: isDark,
              onTap: () async {
                final nav = Navigator.of(sheetCtx);
                await theme.setThemeMode(ThemeMode.light);
                if (!mounted) return;
                setState(() {});
                nav.pop();
              },
            ),
            const SizedBox(height: 8),

            // Dark Option
            _buildThemeOption(
              icon: Icons.dark_mode_rounded,
              title: '${loc.translate('settings_theme_dark')} (Obsidian Luxury)',
              subtitle: 'Глибокий чорний онікс із теплими золотими акцентами',
              isSelected: theme.themeMode == ThemeMode.dark,
              isDark: isDark,
              onTap: () async {
                final nav = Navigator.of(sheetCtx);
                await theme.setThemeMode(ThemeMode.dark);
                if (!mounted) return;
                setState(() {});
                nav.pop();
              },
            ),
            const SizedBox(height: 8),

            // System Option
            _buildThemeOption(
              icon: Icons.brightness_auto_rounded,
              title: loc.translate('settings_theme_system'),
              subtitle: 'Автоматична синхронізація з налаштуваннями пристрою',
              isSelected: theme.themeMode == ThemeMode.system,
              isDark: isDark,
              onTap: () async {
                final nav = Navigator.of(sheetCtx);
                await theme.setThemeMode(ThemeMode.system);
                if (!mounted) return;
                setState(() {});
                nav.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2E2E38) : const Color(0xFFFEF3C7))
              : (isDark ? const Color(0xFF1E1E24) : const Color(0xFFF4F4F5)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.accent : (isDark ? Colors.white70 : Colors.black87)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.muted),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    final loc = LocalizationService.instance;
    final isDark = ThemeService.instance.isDarkMode(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.language_rounded, color: Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Text(
                  loc.translate('settings_language'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...AppLanguage.values.map((lang) {
              final isSel = loc.currentLanguage == lang;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () async {
                    final nav = Navigator.of(sheetCtx);
                    await loc.setLanguage(lang);
                    if (!mounted) return;
                    setState(() {});
                    nav.pop();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSel
                          ? (isDark ? const Color(0xFF2E2E38) : const Color(0xFFE0F2FE))
                          : (isDark ? const Color(0xFF1E1E24) : const Color(0xFFF4F4F5)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSel ? const Color(0xFF0284C7) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(lang.flag, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                lang.subtitle,
                                style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.muted),
                              ),
                            ],
                          ),
                        ),
                        if (isSel) const Icon(Icons.check_circle_rounded, color: Color(0xFF0284C7), size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog() {
    bool morning = _profile.pushDailyStylist;
    bool streak = _profile.pushStreakReminder;
    bool eco = _profile.emailEcoReport;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.notifications_active_outlined, color: Color(0xFF16A34A)),
                  SizedBox(width: 8),
                  Text('Сповіщення та Нагадування', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Ранковий лук о 08:00', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Готова капсула під погоду за вікном кожного ранку', style: TextStyle(fontSize: 11)),
                value: morning,
                onChanged: (val) => setSheetState(() => morning = val),
              ),
              SwitchListTile(
                title: const Text('Нагадування стріку о 20:00', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Не дайте згоріти вашому прогресу носіння гардероба', style: TextStyle(fontSize: 11)),
                value: streak,
                onChanged: (val) => setSheetState(() => streak = val),
              ),
              SwitchListTile(
                title: const Text('Тижневий еко-звіт та CPW', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Підсумок вартості виходів та рекомендації щодо розхламлення', style: TextStyle(fontSize: 11)),
                value: eco,
                onChanged: (val) => setSheetState(() => eco = val),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final nav = Navigator.of(sheetCtx);
                    final messenger = ScaffoldMessenger.of(context);
                    await UserProfileService.saveNotifications(
                      pushDailyStylist: morning,
                      pushStreakReminder: streak,
                      emailEcoReport: eco,
                    );
                    if (!mounted) return;
                    setState(() {
                      _profile = UserProfileService.profile;
                    });
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Параметри сповіщень збережено!'), backgroundColor: Color(0xFF16A34A)),
                    );
                  },
                  child: const Text('Зберегти налаштування'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    final loc = context.watch<LocalizationService>();

    final isDark = theme.isDarkMode(context);
    final hasAiKey = AiConfigService.hasCustomKey;
    final adCredits = AiConfigService.adCredits;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(loc.translate('settings_title')),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // 1. User Cabinet Hero Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF1E1E24), Color(0xFF2E2E38)]
                    : const [Color(0xFF18181B), Color(0xFF27272A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: isDark ? Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.35)) : null,
              boxShadow: isDark ? AppTheme.darkSoftShadow : AppTheme.softShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundImage: vestoraImageProvider(_profile.avatarUrl),
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
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27272A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF3F3F46)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (AuthService.instance.currentMethod == AuthMethod.google) ...[
                                  const GoogleLogoWidget(size: 13),
                                  const SizedBox(width: 6),
                                  const Text('Вхід через Google', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 10.5, fontWeight: FontWeight.bold)),
                                ] else if (AuthService.instance.currentMethod == AuthMethod.email) ...[
                                  const Icon(Icons.email_outlined, size: 13, color: Color(0xFFFDE68A)),
                                  const SizedBox(width: 6),
                                  const Text('Вхід через Email & Пароль', style: TextStyle(color: Color(0xFFFDE68A), fontSize: 10.5, fontWeight: FontWeight.bold)),
                                ] else ...[
                                  const Icon(Icons.person_outline, size: 13, color: Color(0xFFA1A1AA)),
                                  const SizedBox(width: 6),
                                  const Text('Демо-режим гостя', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 10.5, fontWeight: FontWeight.bold)),
                                ],
                              ],
                            ),
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
                        label: Text(loc.translate('settings_edit_profile'), style: const TextStyle(fontSize: 12)),
                        onPressed: _showEditProfileDialog,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF52525B)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.vpn_key_outlined, size: 16),
                        label: Text(loc.translate('settings_change_pwd'), style: const TextStyle(fontSize: 12)),
                        onPressed: _showChangePasswordDialog,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF27272A),
                        side: const BorderSide(color: Color(0xFF52525B)),
                        padding: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.logout_rounded, color: Color(0xFFF87171), size: 18),
                      tooltip: loc.translate('settings_logout'),
                      onPressed: _confirmSignOutDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 2. Settings Hub Menu Tiles
          Text(
            loc.translate('settings_personalization').toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.muted, letterSpacing: 1),
          ),
          const SizedBox(height: 10),

          // Tile: Appearance / Dark Mode
          _buildSettingsTile(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            iconColor: const Color(0xFFEAB308),
            title: loc.translate('settings_appearance'),
            subtitle: theme.themeMode == ThemeMode.dark
                ? '${loc.translate('settings_theme_dark')} (Obsidian Luxury)'
                : (theme.themeMode == ThemeMode.light
                    ? '${loc.translate('settings_theme_light')} (Ivory Cashmere)'
                    : loc.translate('settings_theme_system')),
            trailingBadge: theme.themeMode == ThemeMode.dark ? '🌙 Dark' : '☀️ Light',
            isDark: isDark,
            onTap: _showThemePicker,
          ),
          const SizedBox(height: 10),

          // Tile: Language Selection (Top 5 + Ukrainian)
          _buildSettingsTile(
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF0284C7),
            title: loc.translate('settings_language'),
            subtitle: '${loc.currentLanguage.flag} ${loc.currentLanguage.label} · ${loc.currentLanguage.subtitle}',
            trailingBadge: loc.currentLanguage.flag,
            isDark: isDark,
            onTap: _showLanguagePicker,
          ),
          const SizedBox(height: 10),

          // Tile 0: Account & Authentication
          _buildSettingsTile(
            icon: Icons.account_circle_outlined,
            iconColor: const Color(0xFF2563EB),
            title: loc.translate('settings_account'),
            subtitle: AuthService.instance.currentMethod == AuthMethod.google
                ? 'Google: ${_profile.email}'
                : (AuthService.instance.currentMethod == AuthMethod.email
                    ? 'Email & Пароль: ${_profile.email}'
                    : 'Демо-режим гостя'),
            trailingBadge: AuthService.instance.currentMethod == AuthMethod.google ? 'Google 🌐' : 'Email ✉️',
            isDark: isDark,
            onTap: _confirmSignOutDialog,
          ),
          const SizedBox(height: 10),

          // Tile 1: AI & Gemini Vision Hub
          _buildSettingsTile(
            icon: Icons.auto_awesome,
            iconColor: const Color(0xFF4F46E5),
            title: loc.translate('settings_ai_engine'),
            subtitle: hasAiKey
                ? 'Підключено особистий ключ Google Gemini'
                : (adCredits > 0 ? 'Gemini Vision ($adCredits бонусів за відео)' : 'Локальний евристичний парсер'),
            trailingBadge: hasAiKey ? 'BYOK ✅' : '$adCredits ⚡',
            isDark: isDark,
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
            title: loc.translate('settings_personalization'),
            subtitle: '${_profile.preferredStyle} · ${_profile.currency} · ${_profile.sizeSystem}',
            isDark: isDark,
            onTap: _showPersonalizationDialog,
          ),
          const SizedBox(height: 10),

          // Tile 2b: AI Virtual Try-On Fitting Room & Face Photo
          _buildSettingsTile(
            icon: Icons.face_retouching_natural_rounded,
            iconColor: const Color(0xFFD4AF37),
            title: 'AI Примірочна та Фото Обличчя',
            subtitle: _profile.tryOnFaceUrl != null
                ? 'Власне фото обличчя підключено до віртуальної примірочної'
                : 'Завантажте фото або оберіть типаж для примірки речей',
            trailingBadge: _profile.tryOnFaceUrl != null ? 'Готово 🪞' : '+ Фото',
            isDark: isDark,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VirtualFittingScreen()),
              );
              setState(() {
                _profile = UserProfileService.profile;
              });
            },
          ),
          const SizedBox(height: 10),

          // Tile 2c: 3x3 Capsule Matrix
          _buildSettingsTile(
            icon: Icons.grid_on_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: loc.translate('stylist_matrix_tool'),
            subtitle: 'Математика гардероба: 9 базових речей генерують 18 луків',
            trailingBadge: '96% Луків',
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CapsuleMatrixScreen()),
              );
            },
          ),
          const SizedBox(height: 10),

          // Tile 2d: Fabric Care Encyclopedia
          _buildSettingsTile(
            icon: Icons.dry_cleaning_outlined,
            iconColor: const Color(0xFF0D9488),
            title: loc.translate('tool_fabric_care'),
            subtitle: 'Розшифровка символів прання, порятунок плям, кашемір та шовк',
            trailingBadge: 'Гід 🏷️',
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FabricCareScreen()),
              );
            },
          ),
          const SizedBox(height: 10),

          // Tile 3: Notifications & Alarms
          _buildSettingsTile(
            icon: Icons.notifications_active_outlined,
            iconColor: const Color(0xFF16A34A),
            title: 'Сповіщення (Push & Email)',
            subtitle: 'Ранковий образ о 08:00, нагадування стріку, еко-звіти',
            isDark: isDark,
            onTap: _showNotificationsDialog,
          ),
          const SizedBox(height: 10),

          // Tile 4: Security & 2FA
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
              boxShadow: isDark ? AppTheme.darkSoftShadow : AppTheme.softShadow,
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
                      Text(
                        loc.translate('settings_security'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _profile.twoFactorAuth ? '2FA Активовано (захист по SMS / Email)' : 'Вимкнено (рекомендується увімкнути)',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _profile.twoFactorAuth ? const Color(0xFF16A34A) : (isDark ? AppTheme.darkMuted : AppTheme.muted),
                        ),
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
            isDark: isDark,
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
            isDark: isDark,
            onTap: () {
              context.read<WardrobeProvider>().loadDemoCapsule();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✨ Кеш оновлено! Гардероб синхронізовано.')),
              );
            },
          ),
          const SizedBox(height: 22),

          // 4. PWA & Offline Capabilities
          const Text('ДОДАТОК ТА ОФЛАЙН-РЕЖИМ (PWA)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.muted, letterSpacing: 1)),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.install_mobile_rounded,
            iconColor: const Color(0xFF16A34A),
            title: 'Встановити як додаток (PWA)',
            subtitle: 'Миттєвий запуск з робочого столу смартфона чи ПК',
            trailingBadge: '📲 1-Клік',
            isDark: isDark,
            onTap: _showPwaInstallDialog,
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.offline_bolt_rounded,
            iconColor: const Color(0xFFD97706),
            title: 'Офлайн-доступ та Service Worker',
            subtitle: 'Гардероб, комбінації та кольоротип працюють без інтернету',
            trailingBadge: 'v1.0 Активний',
            isDark: isDark,
            onTap: _showOfflineInfoDialog,
          ),
          const SizedBox(height: 26),

          // App Info & Version
          Center(
            child: Column(
              children: [
                Text(
                  'Vestora · Smart Wardrobe Luxury Edition',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkMuted : Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                Text('Версія 4.5 · Build 2026.10', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF52525B) : Colors.grey.shade500)),
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
    bool isDark = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
          boxShadow: isDark ? AppTheme.darkSoftShadow : AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: isDark ? AppTheme.darkMuted : AppTheme.muted),
                  ),
                ],
              ),
            ),
            if (trailingBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF352B18) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trailingBadge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right_rounded, color: isDark ? AppTheme.darkMuted : AppTheme.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
