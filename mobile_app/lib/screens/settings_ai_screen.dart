import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_config_service.dart';
import '../theme/app_theme.dart';

class SettingsAiScreen extends StatefulWidget {
  const SettingsAiScreen({super.key});

  @override
  State<SettingsAiScreen> createState() => _SettingsAiScreenState();
}

class _SettingsAiScreenState extends State<SettingsAiScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _isTestingKey = false;
  String? _testStatusMessage;
  bool? _isKeyValid;
  int _adCredits = 3;
  String _selectedModel = 'gemini-2.5-flash';
  bool _isWatchingAd = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    await AiConfigService.initialize();
    if (!mounted) return;
    setState(() {
      _apiKeyController.text = AiConfigService.apiKey ?? '';
      _adCredits = AiConfigService.adCredits;
      _selectedModel = AiConfigService.preferredModel;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _isKeyValid = false;
        _testStatusMessage = 'Будь ласка, введіть API-ключ для перевірки.';
      });
      return;
    }

    setState(() {
      _isTestingKey = true;
      _testStatusMessage = null;
      _isKeyValid = null;
    });

    final res = await AiConfigService.testApiKey(key);

    if (!mounted) return;
    setState(() {
      _isTestingKey = false;
      _isKeyValid = res.isValid;
      _testStatusMessage = res.message;
    });

    if (res.isValid) {
      await AiConfigService.setApiKey(key);
    }
  }

  Future<void> _saveKey() async {
    final key = _apiKeyController.text.trim();
    await AiConfigService.setApiKey(key.isNotEmpty ? key : null);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(key.isNotEmpty
            ? 'API-ключ Google Gemini успішно збережено!'
            : 'Ключ видалено. Активовано локальний парсер / бонуси за рекламу.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: key.isNotEmpty ? AppTheme.success : AppTheme.primary,
      ),
    );
    setState(() {});
  }

  void _simulateWatchRewardedAd() {
    setState(() => _isWatchingAd = true);
    Timer? countdownTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        int secondsLeft = 4;
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
              if (!dialogCtx.mounted) {
                timer.cancel();
                return;
              }
              if (secondsLeft > 1) {
                setModalState(() => secondsLeft--);
              } else {
                setModalState(() => secondsLeft = 0);
                timer.cancel();
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.play_circle_filled_rounded, color: AppTheme.accent, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Спонсорське відео',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.movie_filter_rounded, color: Colors.white70, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'Vestora Luxury Partners',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            secondsLeft > 0 ? 'Винагорода через: $secondsLeft сек' : '🎉 Відео переглянуто!',
                            style: TextStyle(
                              color: secondsLeft > 0 ? const Color(0xFFFDE68A) : const Color(0xFF86EFAC),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                if (secondsLeft == 0)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      final updated = await AiConfigService.addRewardedAdCredits(3);
                      if (mounted) {
                        setState(() {
                          _isWatchingAd = false;
                          _adCredits = updated;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 Вам нараховано +3 повноцінних Vision ШІ-сканування!'),
                            backgroundColor: AppTheme.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Text('Забрати +3 ШІ-сканування ✨'),
                  )
                else
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      if (mounted) {
                        setState(() => _isWatchingAd = false);
                      }
                    },
                    child: Text(
                      'Закрити без винагороди',
                      style: TextStyle(
                        color: Theme.of(dialogCtx).brightness == Brightness.dark
                            ? AppTheme.darkMuted
                            : AppTheme.muted,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      countdownTimer?.cancel();
      if (mounted && _isWatchingAd) {
        setState(() => _isWatchingAd = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = AiConfigService.hasCustomKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;
    final mutedColor = isDark ? AppTheme.darkMuted : AppTheme.muted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ШІ-Двигун та Gemini Vision'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Status Hero Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasKey
                    ? [const Color(0xFF064E3B), const Color(0xFF047857)]
                    : (_adCredits > 0
                        ? [const Color(0xFF78350F), const Color(0xFFB45309)]
                        : [const Color(0xFF18181B), const Color(0xFF27272A)]),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          hasKey ? 'АКТИВНИЙ ШІ: ВЛАСНИЙ КЛЮЧ' : (_adCredits > 0 ? 'БОНУСНИЙ ШІ' : 'ЛОКАЛЬНИЙ РЕЖИМ'),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      hasKey ? Icons.verified_rounded : (_adCredits > 0 ? Icons.stars_rounded : Icons.offline_bolt_rounded),
                      color: Colors.white,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  hasKey
                      ? 'Google Gemini 2.5 Flash Vision'
                      : (_adCredits > 0
                          ? 'Gemini Vision (Залишилося: $_adCredits)'
                          : 'Локальний евристичний парсер'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasKey
                      ? 'Підключено особистий ключ Google AI Studio. Доступно до 1 500 безкоштовних Vision-аналізів на добу.'
                      : (_adCredits > 0
                          ? 'У вас є безкоштовні сканування за перегляд реклами. Ви можете поповнити їх або додати власний ключ.'
                          : 'Працює без інтернету за правилами регулярних виразів. Додайте ключ Gemini або подивіться спонсорське відео для переходу на нейромережу.'),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Bring Your Own Key (BYOK) Card
          Text(
            'ВЛАСНИЙ КЛЮЧ GOOGLE GEMINI (БЕЗКОШТОВНО)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: mutedColor),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: isDark ? const [] : AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.vpn_key_rounded, color: AppTheme.accent, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gemini API Key',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureKey,
                  decoration: InputDecoration(
                    hintText: 'AIzaSy...',
                    prefixIcon: Icon(Icons.key_rounded, size: 20, color: mutedColor),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: _obscureKey ? 'Показати ключ' : 'Приховати ключ',
                          icon: Icon(_obscureKey ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                          onPressed: () => setState(() => _obscureKey = !_obscureKey),
                        ),
                        if (_apiKeyController.text.isNotEmpty)
                          IconButton(
                            tooltip: 'Очистити ключ',
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _apiKeyController.clear();
                              _saveKey();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Model Selection
                Row(
                  children: [
                    const Text('Модель:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedModel,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'gemini-2.5-flash',
                            child: Text(
                              'Gemini 2.5 Flash (Рекомендовано)',
                              style: TextStyle(fontSize: 12.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'gemini-2.5-flash-lite',
                            child: Text(
                              'Gemini 2.5 Flash-Lite (Швидкісний)',
                              style: TextStyle(fontSize: 12.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedModel = val);
                            AiConfigService.setPreferredModel(val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons: Test & Save
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 150,
                      child: OutlinedButton.icon(
                        onPressed: _isTestingKey ? null : _testKey,
                        icon: _isTestingKey
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_tethering_rounded, size: 18),
                        label: Text(
                          _isTestingKey ? 'Тестування...' : 'Перевірити',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: ElevatedButton.icon(
                        onPressed: _saveKey,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Зберегти'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.primary,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                // Test Feedback message
                if (_testStatusMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isKeyValid == true
                          ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4))
                          : (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isKeyValid == true
                            ? (isDark ? const Color(0xFF059669) : const Color(0xFFBBF7D0))
                            : (isDark ? const Color(0xFFDC2626) : const Color(0xFFFECACA)),
                      ),
                    ),
                    child: Text(
                      _testStatusMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _isKeyValid == true
                            ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534))
                            : (isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B)),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. How to get free API key guide
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF27272A) : const Color(0xFFFEF3C7).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      color: isDark ? AppTheme.darkAccent : const Color(0xFFB45309),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Як отримати безкоштовний ключ за 30 секунд:',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isDark ? AppTheme.darkAccent : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Перейдіть на aistudio.google.com з будь-якого Google-акаунта.\n'
                  '2. Натисніть кнопку "Get API key" → "Create API key".\n'
                  '3. Скопіюйте створений ключ (починається з AIzaSy...) та вставте його вище.\n'
                  '💳 Картка не потрібна. 100% безкоштовно (1 500 запитів/день).',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFFE4E4E7) : const Color(0xFF78350F),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: 'https://aistudio.google.com/'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Посилання скопійовано: aistudio.google.com'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: isDark ? AppTheme.darkAccent : const Color(0xFFB45309),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Скопіювати лінк на Google AI Studio',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.darkAccent : const Color(0xFFB45309),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Alternative: Rewarded Ad Scans (Free via Ads)
          Text(
            'БЕЗКОШТОВНІ СКАНУВАННЯ ЗА РЕКЛАМУ (REWARDED ADS)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: mutedColor),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: isDark ? const [] : AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Бонусний баланс Vision ШІ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('Залишилося: $_adCredits повноцінних сканувань', style: TextStyle(fontSize: 12, color: mutedColor)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_adCredits ⚡',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isWatchingAd ? null : _simulateWatchRewardedAd,
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                    label: const Text(
                      'Переглянути коротке відео (+3 сканування)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. Vestora Cloud VIP Tier Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF27272A), Color(0xFF09090B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('💎', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vestora VIP Cloud (Незабаром)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Автоматичний доступ до Gemini Vision без введення ключів та без перегляду реклами.',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
