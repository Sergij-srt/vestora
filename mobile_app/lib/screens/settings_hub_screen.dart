import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_profile_service.dart';
import '../services/ai_config_service.dart';
import '../services/wardrobe_provider.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import '../widgets/controller_scope.dart';
import '../widgets/vestora_image.dart';
import '../theme/app_theme.dart';
import 'settings_ai_screen.dart';
import 'virtual_fitting_screen.dart';
import 'capsule_matrix_screen.dart';
import 'fabric_care_screen.dart';
import '../services/auth_service.dart';
import '../services/pwa_service.dart';
import '../services/backup_service.dart';
import '../services/supabase_service.dart';
import 'package:flutter/services.dart';
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

  /// Preserves SmartWardrobeApp's reactive root `/` route (`Consumer3<AuthService>`)
  /// when pushed inside the main app, while supporting standalone widget mounting in tests.
  void _returnToAuthRoot() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    } else {
      nav.pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  void _confirmSignOutDialog() {
    final auth = AuthService.instance;
    final email = auth.currentUser?.email ?? _profile.email;
    final loc = LocalizationService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.translate('settings_logout'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${loc.translate('settings_logout_confirm')}\n$email?'),
            const SizedBox(height: 8),
            Text(
              loc.translate('settings_logout_note'),
              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkMuted : AppTheme.muted),
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
              _returnToAuthRoot();
            },
            child: Text(loc.translate('settings_logout_action')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccountDialog() {
    final loc = LocalizationService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: AppTheme.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.translate('settings_delete_confirm_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          loc.translate('settings_delete_confirm_body'),
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: isDark ? AppTheme.darkText : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(loc.translate('settings_delete_cancel')),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: Text(loc.translate('settings_delete_confirm_btn')),
            onPressed: () async {
              final wardrobe = context.read<WardrobeProvider>();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogCtx);
              final res = await AuthService.instance.deleteAccount(wardrobe: wardrobe);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    res.success ? loc.translate('settings_delete_success') : res.message,
                  ),
                  backgroundColor: res.success ? AppTheme.primary : AppTheme.danger,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              if (res.success) {
                _returnToAuthRoot();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    final loc = LocalizationService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.verified_user_outlined, color: isDark ? AppTheme.darkAccent : AppTheme.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                loc.translate('settings_privacy_policy'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            loc.translate('settings_privacy_body'),
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: isDark ? AppTheme.darkText : Colors.black87,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text(loc.translate('common_close')),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final loc = LocalizationService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppTheme.darkMuted : AppTheme.muted;

    showDialog(
      context: context,
      builder: (dialogCtx) => ControllerScope(
        create: () => [
          TextEditingController(text: _profile.name),
          TextEditingController(text: _profile.email),
          TextEditingController(text: _profile.location),
        ],
        builder: (scopeCtx, controllers) {
          final nameCtrl = controllers[0];
          final emailCtrl = controllers[1];
          final locCtrl = controllers[2];
          return AlertDialog(
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              loc.translate('settings_edit_profile_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.translate('settings_field_name'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                  const SizedBox(height: 4),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Vestora')),
                  const SizedBox(height: 12),
                  Text('EMAIL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                  const SizedBox(height: 4),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(hintText: 'user@vestora.app')),
                  const SizedBox(height: 12),
                  Text(loc.translate('settings_field_location'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                  const SizedBox(height: 4),
                  TextField(controller: locCtrl, decoration: const InputDecoration(hintText: 'Kyiv / Paris')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(context.tr('common_cancel'))),
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
                    SnackBar(content: Text(loc.translate('settings_profile_saved')), backgroundColor: AppTheme.success),
                  );
                },
                child: Text(context.tr('common_save')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    final loc = LocalizationService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppTheme.darkMuted : AppTheme.muted;

    showDialog(
      context: context,
      builder: (dialogCtx) => ControllerScope(
        create: () => [
          TextEditingController(),
          TextEditingController(),
          TextEditingController(),
        ],
        builder: (scopeCtx, controllers) {
          final curCtrl = controllers[0];
          final newCtrl = controllers[1];
          final confirmCtrl = controllers[2];
          return AlertDialog(
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              loc.translate('settings_change_pwd_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.translate('settings_pwd_current'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                  const SizedBox(height: 4),
                  TextField(controller: curCtrl, obscureText: true, decoration: const InputDecoration(hintText: '••••••••')),
                  const SizedBox(height: 12),
                  Text(loc.translate('settings_pwd_new'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                  const SizedBox(height: 4),
                  TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(hintText: '••••••••')),
                  const SizedBox(height: 12),
                  Text(loc.translate('settings_pwd_confirm'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                  const SizedBox(height: 4),
                  TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(hintText: '••••••••')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(context.tr('common_cancel'))),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(dialogCtx);
                  final res = await UserProfileService.changePassword(
                    oldPassword: curCtrl.text,
                    newPassword: newCtrl.text,
                    confirmPassword: confirmCtrl.text,
                  );
                  if (!mounted) return;
                  if (!res.success) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(res.message), backgroundColor: AppTheme.danger),
                    );
                    return;
                  }
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text(res.message), backgroundColor: AppTheme.success),
                  );
                },
                child: Text(loc.translate('settings_pwd_update_btn')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPwaInstallDialog() {
    final theme = context.read<ThemeService>();
    final loc = LocalizationService.instance;
    final isDark = theme.isDarkMode(context);
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.accent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
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
                        border: Border.all(color: accentColor),
                      ),
                      child: Icon(Icons.install_mobile_rounded, color: accentColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.translate('settings_pwa_install'),
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                          ),
                          Text(
                            loc.translate('settings_pwa_install_sub'),
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
                      Text('💡 PWA:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: accentColor, letterSpacing: 0.8)),
                      const SizedBox(height: 6),
                      Text(
                        '• Android / Chrome: Натисніть «Встановити» або в меню браузера оберіть «Встановити додаток».',
                        style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkText : Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• iOS / Safari: Натисніть кнопку «Поділитися» та виберіть «На початковий екран» (+).',
                        style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkText : Colors.black87),
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
                    label: Text(loc.translate('settings_pwa_install')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOfflineInfoDialog() {
    final theme = context.read<ThemeService>();
    final loc = LocalizationService.instance;
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
            Expanded(
              child: Text(
                loc.translate('settings_pwa_offline'),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.translate('settings_offline_body'),
                style: TextStyle(fontSize: 12.5, height: 1.45, color: isDark ? AppTheme.darkText : Colors.black87),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF16A34A).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'Service Worker: ACTIVE (v1.2.0)',
                  style: TextStyle(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(loc.translate('common_close')),
          ),
        ],
      ),
    );
  }

  void _showImportBackupDialog() {
    final theme = context.read<ThemeService>();
    final isDark = theme.isDarkMode(context);
    final chipSelectedBg = isDark ? AppTheme.darkAccentLight : const Color(0xFFFEF3C7);
    final chipSelectedText = isDark ? AppTheme.darkAccent : AppTheme.accent;
    BackupValidationResult? validation;
    bool replaceAll = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => ControllerScope(
        create: () => [TextEditingController()],
        builder: (scopeCtx, controllers) {
          final textCtrl = controllers[0];
          return StatefulBuilder(
            builder: (ctx, setSheetState) {
              return Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
                child: SingleChildScrollView(
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
                          const Icon(Icons.restore_page_outlined, color: Color(0xFF0284C7), size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${context.tr('settings_import_btn')} (.vestora)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Вставте вміст файлу резервної копії .vestora або JSON-код нижче:',
                        style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkMuted : AppTheme.muted),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: textCtrl,
                        maxLines: 5,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: isDark ? AppTheme.darkText : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: '{\n  "format": "VESTORA_BACKUP",\n  "version": "1.0",\n  "items": [...]\n}',
                          hintStyle: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: isDark ? AppTheme.darkMuted : Colors.grey.shade500,
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF4F4F5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                        onChanged: (val) {
                          if (validation != null) {
                            setSheetState(() => validation = null);
                          }
                        },
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.paste_rounded, size: 16),
                            label: const Text('Вставити зразок'),
                            onPressed: () {
                              final sampleJson = BackupService.generateBackupJson(
                                wardrobe: context.read<WardrobeProvider>(),
                                profile: _profile,
                              );
                              textCtrl.text = sampleJson;
                              setSheetState(() {
                                validation = BackupService.validateBackup(sampleJson);
                              });
                            },
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.fact_check_outlined, size: 16),
                            label: const Text('Перевірити файл'),
                            onPressed: () {
                              setSheetState(() {
                                validation = BackupService.validateBackup(textCtrl.text);
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (validation != null) ...[
                        if (validation!.isValid) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Резервна копія валідна!',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '👗 Речей у файлі: ${validation!.items.length}\n'
                                  '🔥 Стрік активності: ${validation!.streakDays} днів\n'
                                  '✨ Стиль: ${validation!.preferredStyle ?? _profile.preferredStyle} · ${validation!.currency ?? _profile.currency}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? AppTheme.darkText : Colors.black87,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Replace or Merge options
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Замінити гардероб'),
                                selected: replaceAll,
                                onSelected: (val) => setSheetState(() => replaceAll = true),
                                selectedColor: chipSelectedBg,
                                labelStyle: TextStyle(
                                  color: replaceAll ? chipSelectedText : (isDark ? AppTheme.darkText : Colors.black87),
                                  fontWeight: replaceAll ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 11,
                                ),
                              ),
                              ChoiceChip(
                                label: const Text('Об\'єднати речі'),
                                selected: !replaceAll,
                                onSelected: (val) => setSheetState(() => replaceAll = false),
                                selectedColor: chipSelectedBg,
                                labelStyle: TextStyle(
                                  color: !replaceAll ? chipSelectedText : (isDark ? AppTheme.darkText : Colors.black87),
                                  fontWeight: !replaceAll ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.cloud_upload_rounded),
                              label: Text(
                                replaceAll ? 'Відновити та перезаписати' : 'Об\'єднати з поточним гардеробом',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () async {
                                final wardrobeProvider = context.read<WardrobeProvider>();
                                final messenger = ScaffoldMessenger.of(context);
                                final nav = Navigator.of(sheetCtx);
                                final res = await BackupService.restoreBackup(
                                  wardrobe: wardrobeProvider,
                                  rawJson: textCtrl.text,
                                  replaceAll: replaceAll,
                                );

                                if (mounted) {
                                  nav.pop();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(res.message),
                                      backgroundColor: res.success ? const Color(0xFF16A34A) : Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded, color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    validation!.errorMessage ?? 'Помилка валідації резервної копії.',
                                    style: TextStyle(color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626), fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showSupabaseConfigDialog() {
    final theme = context.read<ThemeService>();
    final isDark = theme.isDarkMode(context);
    bool autoSync = SupabaseService.autoSyncEnabled;
    bool isSubmitting = false;
    String? statusMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => ControllerScope(
        create: () => [
          TextEditingController(text: SupabaseService.configuredUrl ?? ''),
          TextEditingController(text: SupabaseService.configuredAnonKey ?? ''),
          TextEditingController(),
          TextEditingController(),
        ],
        builder: (scopeCtx, controllers) {
          final urlCtrl = controllers[0];
          final keyCtrl = controllers[1];
          final emailCtrl = controllers[2];
          final passCtrl = controllers[3];
          return StatefulBuilder(
            builder: (ctx, setSheetState) {
              final isConfigured = SupabaseService.isConfigured;
              final isAuth = SupabaseService.isAuthenticated;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                  left: 20,
                  right: 20,
                  top: 20,
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
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkBorder : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3ECF8E).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.storage_rounded, color: Color(0xFF3ECF8E), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Supabase PostgreSQL Cloud',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Хмарна синхронізація, автентифікація та резервне копіювання',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppTheme.darkMuted : AppTheme.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isConfigured
                                  ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                                  : const Color(0xFF71717A).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isConfigured ? '🟢 Активно' : '⚪ Офлайн',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isConfigured ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A)) : const Color(0xFFA1A1AA),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      if (isConfigured) ...[
                        // Configured State
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
                              Row(
                                children: [
                                  const Icon(Icons.link_rounded, size: 16, color: Color(0xFF3ECF8E)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      SupabaseService.configuredUrl ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isAuth
                                    ? '👤 Увійшли як: ${SupabaseService.currentUser?.email}'
                                    : '🔒 База підключена, але сесія відсутня (увійдіть нижче)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isAuth ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A)) : (isDark ? AppTheme.darkAccent : const Color(0xFFD97706)),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (!isAuth) ...[
                          // Login / Signup inputs
                          TextField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Email для Supabase Auth',
                              prefixIcon: const Icon(Icons.email_outlined, size: 18),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: passCtrl,
                            obscureText: true,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Пароль',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3ECF8E),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          setSheetState(() => isSubmitting = true);
                                          final res = await SupabaseService.signInWithPassword(
                                            email: emailCtrl.text,
                                            password: passCtrl.text,
                                          );
                                          setSheetState(() {
                                            isSubmitting = false;
                                            statusMessage = res.success
                                                ? '✅ Успішний вхід!'
                                                : '❌ ${res.error ?? 'Помилка входу'}';
                                          });
                                        },
                                  child: const Text('Увійти', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? const Color(0xFF3ECF8E) : const Color(0xFF047857),
                                    side: const BorderSide(color: Color(0xFF3ECF8E)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          setSheetState(() => isSubmitting = true);
                                          final res = await SupabaseService.signUp(
                                            email: emailCtrl.text,
                                            password: passCtrl.text,
                                          );
                                          setSheetState(() {
                                            isSubmitting = false;
                                            statusMessage = res.success
                                                ? '✅ Реєстрація успішна! Перевірте пошту для підтвердження.'
                                                : '❌ ${res.error ?? 'Помилка реєстрації'}';
                                          });
                                        },
                                  child: const Text('Реєстрація', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                          if (statusMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              statusMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusMessage!.startsWith('✅') ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A)) : Colors.redAccent,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                        ] else ...[
                          // Logged In Actions
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.logout_rounded, size: 16),
                              label: const Text('Вийти з акаунту Supabase'),
                              onPressed: () async {
                                await SupabaseService.signOut();
                                setSheetState(() {});
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                            icon: const Icon(Icons.link_off_rounded, size: 16),
                            label: const Text('Відключити Supabase (Offline Mode)'),
                            onPressed: () async {
                              await SupabaseService.disconnect();
                              if (!ctx.mounted) return;
                              if (mounted) setState(() {});
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                      ] else ...[
                        // Not Configured State: Setup Inputs
                        TextField(
                          controller: urlCtrl,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Supabase Project URL',
                            hintText: 'https://xxxxxx.supabase.co',
                            prefixIcon: const Icon(Icons.public_rounded, size: 18),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: keyCtrl,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Supabase Anon Public Key',
                            hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                            prefixIcon: const Icon(Icons.key_rounded, size: 18),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: autoSync,
                          title: const Text('Автоматична синхронізація', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: const Text('Фонова реплікація речей при наявності зв\'язку', style: TextStyle(fontSize: 11)),
                          activeTrackColor: const Color(0xFF3ECF8E),
                          onChanged: (val) => setSheetState(() => autoSync = val),
                        ),
                        const SizedBox(height: 12),

                        // Setup guide box
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
                              Row(
                                children: [
                                  Icon(Icons.help_outline_rounded, size: 15, color: isDark ? const Color(0xFF3ECF8E) : const Color(0xFF047857)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'ЯК НАЛАШТУВАТИ ЗА 2 ХВИЛИНИ:',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? const Color(0xFF3ECF8E) : const Color(0xFF047857),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '1. Створіть безкоштовний проект на supabase.com\n'
                                '2. Відкрийте Project Settings -> API\n'
                                '3. Скопіюйте Project URL та anon public key сюди\n'
                                '4. У SQL Editor проекту виконайте готову SQL-схему Vestora.',
                                style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkText : Colors.black87, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3ECF8E),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Зберегти та підключити', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () async {
                              final url = urlCtrl.text.trim();
                              final key = keyCtrl.text.trim();
                              if (url.isEmpty || key.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Вкажіть Project URL та Anon Key')),
                                );
                                return;
                              }

                              final ok = await SupabaseService.saveCredentials(url: url, anonKey: key, autoSync: autoSync);
                              if (mounted && ctx.mounted) {
                                setState(() {});
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok ? '⚡ Supabase підключено успішно!' : '⚠️ Помилка з\'єднання. Перевірте правильність URL та ключа.'),
                                    backgroundColor: ok ? const Color(0xFF16A34A) : Colors.redAccent,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _syncWithSupabase() async {
    if (!SupabaseService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Спочатку підключіть проект Supabase у налаштуваннях.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _showSupabaseConfigDialog();
      return;
    }

    if (!SupabaseService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Для синхронізації увійдіть у свій обліковий запис Supabase.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _showSupabaseConfigDialog();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Виконується синхронізація з хмарою PostgreSQL...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );

    final wardrobe = context.read<WardrobeProvider>();
    final result = await SupabaseService.syncWardrobe(wardrobe: wardrobe);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Синхронізація завершена.'),
          backgroundColor: result.success ? const Color(0xFF16A34A) : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSqlSchemaDialog() {
    final theme = context.read<ThemeService>();
    final isDark = theme.isDarkMode(context);
    final schema = SupabaseService.getSqlSchema();

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.terminal_rounded, color: Color(0xFF3ECF8E), size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text('SQL-схема для Supabase', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Цей SQL-скрипт створить необхідні таблиці (profiles, clothing_items, outfits, wear_logs) із політиками Row Level Security (RLS) та S3-бакетом.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    schema,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: isDark ? const Color(0xFF3ECF8E) : const Color(0xFF047857),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Закрити'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3ECF8E),
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Скопіювати SQL'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: schema));
              Navigator.pop(dlgCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 SQL-схему скопійовано! Вставте її в Supabase SQL Editor.'),
                  backgroundColor: Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPersonalizationDialog() {
    String selectedStyle = _profile.preferredStyle;
    String selectedCurrency = _profile.currency;
    String selectedSize = _profile.sizeSystem;
    final loc = LocalizationService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppTheme.darkMuted : AppTheme.muted;
    final chipSelectedBg = isDark ? AppTheme.darkAccentLight : const Color(0xFFFEF3C7);
    final chipSelectedText = isDark ? AppTheme.darkAccent : AppTheme.accent;
    final chipUnselectedText = isDark ? AppTheme.darkText : Colors.black87;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBorder : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.palette_outlined, color: chipSelectedText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('settings_personalization'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkText : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(loc.translate('settings_style_label'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: ['Quiet Luxury', 'Мінімалізм', 'Smart Casual', 'Old Money', 'Streetwear'].map((st) {
                    final isSel = selectedStyle == st;
                    return ChoiceChip(
                      label: Text(st),
                      selected: isSel,
                      onSelected: (val) => setSheetState(() => selectedStyle = st),
                      selectedColor: chipSelectedBg,
                      labelStyle: TextStyle(color: isSel ? chipSelectedText : chipUnselectedText, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(loc.translate('settings_currency_label'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: ['UAH (₴)', 'USD (\$)', 'EUR (€)'].map((curr) {
                    final isSel = selectedCurrency == curr;
                    return ChoiceChip(
                      label: Text(curr),
                      selected: isSel,
                      onSelected: (val) => setSheetState(() => selectedCurrency = curr),
                      selectedColor: chipSelectedBg,
                      labelStyle: TextStyle(color: isSel ? chipSelectedText : chipUnselectedText, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(loc.translate('settings_size_label'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: ['EUR (36-44)', 'US (XS-XL)', 'UK (8-16)'].map((sz) {
                    final isSel = selectedSize == sz;
                    return ChoiceChip(
                      label: Text(sz),
                      selected: isSel,
                      onSelected: (val) => setSheetState(() => selectedSize = sz),
                      selectedColor: chipSelectedBg,
                      labelStyle: TextStyle(color: isSel ? chipSelectedText : chipUnselectedText, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
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
                        SnackBar(content: Text(loc.translate('settings_profile_saved')), backgroundColor: AppTheme.success),
                      );
                    },
                    child: Text(loc.translate('settings_apply_btn')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showThemePicker() {
    final theme = ThemeService.instance;
    final loc = LocalizationService.instance;
    final isDark = theme.isDarkMode(context);
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.accent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: SingleChildScrollView(
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
                  Icon(Icons.palette_rounded, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.translate('settings_appearance'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Light Option
              _buildThemeOption(
                icon: Icons.light_mode_rounded,
                title: '${loc.translate('settings_theme_light')} (Ivory & Gold)',
                subtitle: 'Ivory Cashmere · Vestora Editorial',
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
                subtitle: 'Obsidian Onyx · Warm Champagne Gold',
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
                subtitle: 'Auto OS Appearance',
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
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.accent;
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
            color: isSelected ? accentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? accentColor : (isDark ? AppTheme.darkText : Colors.black87)),
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
            if (isSelected) Icon(Icons.check_circle_rounded, color: accentColor, size: 20),
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
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: SingleChildScrollView(
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
                  Expanded(
                    child: Text(
                      loc.translate('settings_language'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
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
                          if (isSel) Icon(Icons.check_circle_rounded, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsDialog() {
    bool morning = _profile.pushDailyStylist;
    bool streak = _profile.pushStreakReminder;
    bool eco = _profile.emailEcoReport;
    final loc = LocalizationService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBorder : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, color: isDark ? const Color(0xFF4ADE80) : AppTheme.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('settings_notifications'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkText : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(loc.translate('settings_notif_morning'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(loc.translate('settings_notif_morning_sub'), style: const TextStyle(fontSize: 11)),
                  value: morning,
                  onChanged: (val) => setSheetState(() => morning = val),
                ),
                SwitchListTile(
                  title: Text(loc.translate('settings_notif_streak'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(loc.translate('settings_notif_streak_sub'), style: const TextStyle(fontSize: 11)),
                  value: streak,
                  onChanged: (val) => setSheetState(() => streak = val),
                ),
                SwitchListTile(
                  title: Text(loc.translate('settings_notif_eco'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(loc.translate('settings_notif_eco_sub'), style: const TextStyle(fontSize: 11)),
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
                        SnackBar(content: Text(loc.translate('settings_notif_saved')), backgroundColor: AppTheme.success),
                      );
                    },
                    child: Text(context.tr('common_save')),
                  ),
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
    final theme = context.watch<ThemeService>();
    final loc = context.watch<LocalizationService>();

    final isDark = theme.isDarkMode(context);
    final sectionHeaderColor = isDark ? AppTheme.darkMuted : AppTheme.muted;
    final hasAiKey = AiConfigService.hasCustomKey;
    final adCredits = AiConfigService.adCredits;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
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
                        Semantics(
                          image: true,
                          label: 'Аватар профілю ${_profile.name}',
                          child: CircleAvatar(
                            radius: 34,
                            backgroundImage: vestoraImageProvider(_profile.avatarUrl),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
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
                              Flexible(
                                child: Text(
                                  _profile.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'VIP PRO',
                                  style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _profile.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 13, color: Color(0xFFFDE68A)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _profile.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 11.5),
                                ),
                              ),
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
                                  const Flexible(
                                    child: Text(
                                      'Вхід через Google',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Color(0xFF93C5FD), fontSize: 10.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ] else if (AuthService.instance.currentMethod == AuthMethod.email) ...[
                                  const Icon(Icons.email_outlined, size: 13, color: Color(0xFFFDE68A)),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text(
                                      'Вхід через Email & Пароль',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Color(0xFFFDE68A), fontSize: 10.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ] else ...[
                                  const Icon(Icons.person_outline, size: 13, color: Color(0xFFA1A1AA)),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text(
                                      'Демо-режим гостя',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 10.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
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
                          minimumSize: const Size(48, 48),
                          side: const BorderSide(color: Color(0xFF52525B)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(
                          loc.translate('settings_edit_profile'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: _showEditProfileDialog,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 48),
                          side: const BorderSide(color: Color(0xFF52525B)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.vpn_key_outlined, size: 16),
                        label: Text(
                          loc.translate('settings_change_pwd'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: _showChangePasswordDialog,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF27272A),
                        minimumSize: const Size(48, 48),
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
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: sectionHeaderColor, letterSpacing: 1),
          ),
          const SizedBox(height: 10),

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

          _buildSettingsTile(
            icon: Icons.account_circle_outlined,
            iconColor: const Color(0xFF2563EB),
            title: loc.translate('settings_account'),
            subtitle: AuthService.instance.currentMethod == AuthMethod.google
                ? 'Google: ${_profile.email}'
                : (AuthService.instance.currentMethod == AuthMethod.email
                    ? 'Email: ${_profile.email}'
                    : _profile.email),
            trailingBadge: AuthService.instance.currentMethod == AuthMethod.google ? 'Google 🌐' : 'Email ✉️',
            isDark: isDark,
            onTap: _confirmSignOutDialog,
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.auto_awesome,
            iconColor: const Color(0xFF4F46E5),
            title: loc.translate('settings_ai_engine'),
            subtitle: hasAiKey
                ? 'Google Gemini (${AiConfigService.maskedApiKey ?? "BYOK"})'
                : (adCredits > 0 ? 'Gemini Vision ($adCredits ⚡)' : 'Local Heuristic Engine'),
            trailingBadge: hasAiKey ? 'BYOK ✅' : '$adCredits ⚡',
            isDark: isDark,
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsAiScreen()));
              setState(() {});
            },
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.palette_outlined,
            iconColor: isDark ? AppTheme.darkAccent : AppTheme.accent,
            title: loc.translate('settings_personalization'),
            subtitle: '${_profile.preferredStyle} · ${_profile.currency} · ${_profile.sizeSystem}',
            isDark: isDark,
            onTap: _showPersonalizationDialog,
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.face_retouching_natural_rounded,
            iconColor: const Color(0xFFD4AF37),
            title: loc.translate('fitting_title'),
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

          _buildSettingsTile(
            icon: Icons.grid_on_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: loc.translate('stylist_matrix_tool'),
            subtitle: '3x3 · 9 items → 18 outfits',
            trailingBadge: '96%',
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CapsuleMatrixScreen()),
              );
            },
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.dry_cleaning_outlined,
            iconColor: const Color(0xFF0D9488),
            title: loc.translate('tool_fabric_care'),
            subtitle: 'ISO 3758 · Cashmere · Silk · Wool',
            trailingBadge: '🏷️',
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FabricCareScreen()),
              );
            },
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.notifications_active_outlined,
            iconColor: AppTheme.success,
            title: loc.translate('settings_notifications'),
            subtitle: loc.translate('settings_notifications_sub'),
            isDark: isDark,
            onTap: _showNotificationsDialog,
          ),
          const SizedBox(height: 10),

          // Security & 2FA
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
                    color: isDark ? const Color(0xFF2563EB).withValues(alpha: 0.2) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.security_rounded, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
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
                        _profile.twoFactorAuth ? '2FA Active (SMS / Email)' : '2FA Off',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _profile.twoFactorAuth
                              ? (isDark ? const Color(0xFF4ADE80) : AppTheme.success)
                              : (isDark ? AppTheme.darkMuted : AppTheme.muted),
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
                          content: Text(val ? '2FA Active!' : '2FA Off.'),
                          backgroundColor: val ? AppTheme.success : AppTheme.primary,
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
          Text(
            loc.translate('settings_backup_hub').toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: sectionHeaderColor, letterSpacing: 1),
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.cloud_download_outlined,
            iconColor: const Color(0xFF0284C7),
            title: loc.translate('settings_export_btn'),
            subtitle: '.vestora JSON archive',
            trailingBadge: '⬇️ .vestora',
            isDark: isDark,
            onTap: () {
              final wardrobe = context.read<WardrobeProvider>();
              BackupService.exportBackupFile(wardrobe: wardrobe, profile: _profile);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📦 .vestora exported!'),
                  backgroundColor: AppTheme.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.restore_page_outlined,
            iconColor: AppTheme.success,
            title: loc.translate('settings_import_btn'),
            subtitle: '.vestora / JSON',
            trailingBadge: '⬆️ JSON',
            isDark: isDark,
            onTap: _showImportBackupDialog,
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.cleaning_services_outlined,
            iconColor: isDark ? AppTheme.darkAccent : AppTheme.accent,
            title: loc.translate('settings_reset_cache'),
            subtitle: loc.translate('settings_reset_cache_sub'),
            isDark: isDark,
            onTap: () {
              context.read<WardrobeProvider>().loadDemoCapsule();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.translate('settings_reset_cache'))),
              );
            },
          ),
          const SizedBox(height: 22),

          // 4. Supabase Cloud Sync & SQL Database
          Text(
            loc.translate('settings_cloud_sync').toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: sectionHeaderColor, letterSpacing: 1),
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.cloud_sync_outlined,
            iconColor: const Color(0xFF3ECF8E),
            title: 'Supabase Cloud (PostgreSQL)',
            subtitle: SupabaseService.isConfigured
                ? (SupabaseService.isAuthenticated
                    ? (SupabaseService.currentUserEmail ?? 'Active')
                    : 'Configured · Sign in required')
                : 'PostgreSQL + RLS + S3 Storage',
            trailingBadge: SupabaseService.isConfigured
                ? (SupabaseService.isAuthenticated ? '🟢 Cloud' : '🟡 Auth')
                : '⚙️ Setup',
            isDark: isDark,
            onTap: _showSupabaseConfigDialog,
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.sync_rounded,
            iconColor: const Color(0xFF0284C7),
            title: loc.translate('settings_sync_now'),
            subtitle: loc.translate('settings_sync_now_sub'),
            trailingBadge: '🔄 Sync',
            isDark: isDark,
            onTap: _syncWithSupabase,
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.terminal_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: loc.translate('settings_sql_schema'),
            subtitle: loc.translate('settings_sql_schema_sub'),
            trailingBadge: '📄 DDL',
            isDark: isDark,
            onTap: _showSqlSchemaDialog,
          ),
          const SizedBox(height: 22),

          // 5. PWA & Offline Capabilities
          Text(
            loc.translate('settings_pwa_section'),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: sectionHeaderColor, letterSpacing: 1),
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.install_mobile_rounded,
            iconColor: AppTheme.success,
            title: loc.translate('settings_pwa_install'),
            subtitle: loc.translate('settings_pwa_install_sub'),
            trailingBadge: '📲 PWA',
            isDark: isDark,
            onTap: _showPwaInstallDialog,
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.offline_bolt_rounded,
            iconColor: isDark ? AppTheme.darkAccent : AppTheme.accent,
            title: loc.translate('settings_pwa_offline'),
            subtitle: loc.translate('settings_pwa_offline_sub'),
            trailingBadge: 'v1.2 Wasm',
            isDark: isDark,
            onTap: _showOfflineInfoDialog,
          ),
          const SizedBox(height: 22),

          // 6. Legal, Open-Source Licenses & Mandatory 1-Click Account Deletion (App Store / Google Play)
          Text(
            loc.translate('settings_legal_section').toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: sectionHeaderColor, letterSpacing: 1),
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.verified_user_outlined,
            iconColor: const Color(0xFF0284C7),
            title: loc.translate('settings_privacy_policy'),
            subtitle: loc.translate('settings_privacy_sub'),
            isDark: isDark,
            onTap: _showPrivacyPolicyDialog,
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF8B5CF6),
            title: loc.translate('settings_licenses'),
            subtitle: loc.translate('settings_licenses_sub'),
            isDark: isDark,
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Vestora · Smart Wardrobe',
                applicationVersion: '1.0.0+1',
                applicationLegalese: '© 2026 Vestora Digital Closet. All rights reserved.',
              );
            },
          ),
          const SizedBox(height: 10),

          _buildSettingsTile(
            icon: Icons.delete_forever_rounded,
            iconColor: AppTheme.danger,
            title: loc.translate('settings_delete_account'),
            subtitle: loc.translate('settings_delete_account_sub'),
            trailingBadge: '⚠️ GDPR',
            isDark: isDark,
            onTap: _confirmDeleteAccountDialog,
          ),
          const SizedBox(height: 26),

          // App Info & Version
          Center(
            child: Column(
              children: [
                Text(
                  'Vestora · Smart Wardrobe Luxury Edition',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkText : AppTheme.secondary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Версія 1.0.0+1 · Build 2026.10 (Wasm Ready)',
                  style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.muted),
                ),
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
