import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/controller_scope.dart';
import '../widgets/vestora_image.dart';
import '../theme/app_theme.dart';

class GoogleLogoWidget extends StatelessWidget {
  final double size;
  const GoogleLogoWidget({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Paints with official Google brand colors
    final bluePaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    final redPaint = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill;
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill;
    final greenPaint = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill;

    final pathRed = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), -2.6, 1.8, false)
      ..close();
    canvas.drawPath(pathRed, redPaint);

    final pathBlue = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), -0.8, 1.6, false)
      ..close();
    canvas.drawPath(pathBlue, bluePaint);

    final pathGreen = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), 0.8, 1.3, false)
      ..close();
    canvas.drawPath(pathGreen, greenPaint);

    final pathYellow = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), 2.1, 1.6, false)
      ..close();
    canvas.drawPath(pathYellow, yellowPaint);

    // Inner cutout to create the 'G' geometry
    final innerPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.60, innerPaint);

    // Horizontal blue bar of 'G'
    final barRect = Rect.fromLTRB(center.dx, center.dy - radius * 0.20, center.dx + radius * 0.95, center.dy + radius * 0.20);
    canvas.drawRect(barRect, bluePaint);

    // Small cutout in the upper right
    final cutoutRect = Rect.fromLTRB(center.dx, center.dy - radius * 0.6, center.dx + radius * 0.95, center.dy - radius * 0.20);
    canvas.drawRect(cutoutRect, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(text: 'olena.fashion@gmail.com');
  final _passwordCtrl = TextEditingController(text: 'password123');
  final _confirmPassCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // --- 1. Google Sign-In Flow ---
  void _handleGoogleSignIn() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      isScrollControlled: true,
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
                  decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  GoogleLogoWidget(size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Увійти через Google', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Оберіть Google-акаунт для входу у Vestora', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.border),

              // Presets
              ...AuthService.googlePresetAccounts.map((account) {
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    _executeGoogleLogin(
                      email: account.email,
                      name: account.displayName,
                      avatar: account.avatarUrl,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFF4F4F5),
                          backgroundImage: vestoraImageProvider(account.avatarUrl),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(account.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(account.email, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.muted),
                      ],
                    ),
                  ),
                );
              }),

              const Divider(color: AppTheme.border),
              // Custom Google email option
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Color(0xFF2563EB), size: 20),
                ),
                title: const Text('Використати інший акаунт Google', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Введіть будь-яку Gmail адресу',
                  style: TextStyle(fontSize: 11.5, color: isDark ? AppTheme.darkMuted : AppTheme.muted),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showCustomGoogleEmailDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomGoogleEmailDialog() {
    showDialog(
      context: context,
      builder: (_) => ControllerScope(
        create: () => [
          TextEditingController(text: 'my.fashion@gmail.com'),
          TextEditingController(text: 'Моє Ім\'я'),
        ],
        builder: (dialogCtx, ctrls) {
          final customEmailCtrl = ctrls[0];
          final customNameCtrl = ctrls[1];
          final dialogDark = Theme.of(dialogCtx).brightness == Brightness.dark;
          final mutedColor = dialogDark ? AppTheme.darkMuted : AppTheme.muted;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                GoogleLogoWidget(size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Вхід через Gmail', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ІМ\'Я', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                const SizedBox(height: 4),
                TextField(controller: customNameCtrl, decoration: const InputDecoration(hintText: 'Олена або Сергій')),
                const SizedBox(height: 12),
                Text('GMAIL ПОШТА', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                const SizedBox(height: 4),
                TextField(controller: customEmailCtrl, decoration: const InputDecoration(hintText: 'example@gmail.com')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Скасувати')),
              ElevatedButton(
                onPressed: () {
                  final emailVal = customEmailCtrl.text.trim();
                  final nameVal = customNameCtrl.text.trim();
                  Navigator.pop(dialogCtx);
                  _executeGoogleLogin(
                    email: emailVal,
                    name: nameVal,
                  );
                },
                child: const Text('Увійти через Google'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _executeGoogleLogin({String? email, String? name, String? avatar}) async {
    setState(() => _isLoading = true);
    final result = await AuthService.instance.signInWithGoogle(
      email: email,
      displayName: name,
      avatarUrl: avatar,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Вітаємо, ${result.user?.displayName}! Вхід через Google успішний.'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Помилка входу'), backgroundColor: Colors.red),
      );
    }
  }

  // --- 2. Email & Password Sign-In / Register ---
  Future<void> _handleEmailSubmit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (_isSignUp) {
      final name = _nameCtrl.text.trim();
      final confirm = _confirmPassCtrl.text.trim();
      if (password != confirm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Паролі не співпадають'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);
      final result = await AuthService.instance.registerWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Акаунт успішно створено! Ласкаво просимо, ${result.user?.displayName}!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Помилка реєстрації'), backgroundColor: Colors.red),
        );
      }
    } else {
      setState(() => _isLoading = true);
      final result = await AuthService.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Вхід виконано успішно! Раді бачити, ${result.user?.displayName}!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Помилка входу'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- 3. Password Reset Dialog ---
  void _showForgotPasswordDialog() {
    final initialEmail = _emailCtrl.text;

    showDialog(
      context: context,
      builder: (_) => ControllerScope(
        create: () => [TextEditingController(text: initialEmail)],
        builder: (dialogCtx, ctrls) {
          final resetCtrl = ctrls[0];
          final dialogDark = Theme.of(dialogCtx).brightness == Brightness.dark;
          final mutedColor = dialogDark ? AppTheme.darkMuted : AppTheme.muted;
          final accentColor = dialogDark ? AppTheme.darkAccent : AppTheme.accent;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: accentColor),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Відновлення паролю', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Введіть адресу електронної пошти, на яку зареєстровано акаунт Vestora. Ми надішлемо вам посилання для зміни паролю.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                Text('EMAIL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                const SizedBox(height: 6),
                TextField(
                  controller: resetCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                    hintText: 'ваша_пошта@vestora.app',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Скасувати')),
              ElevatedButton(
                onPressed: () async {
                  final emailText = resetCtrl.text;
                  Navigator.pop(dialogCtx);
                  final res = await AuthService.instance.sendPasswordResetEmail(emailText);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res.message),
                        backgroundColor: res.success ? AppTheme.success : Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Надіслати лінк'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 4. Guest / Demo Mode ---
  void _handleGuestSignIn() async {
    setState(() => _isLoading = true);
    await AuthService.instance.signInAsGuest();
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Вхід виконано у демонстраційному режимі гостя.'),
        backgroundColor: Color(0xFF4B5563),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Haute Branding Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.checkroom_rounded, color: Color(0xFFD4AF37), size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'VESTORA',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: isDark ? Colors.white : const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SMART DIGITAL CLOSET & HAUTE CAPSULE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: isDark ? AppTheme.darkMuted : AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 2. Mode Toggle (Sign In vs Sign Up)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : const Color(0xFFE4E4E7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _isSignUp = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isSignUp ? cardColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: !_isSignUp && !isDark
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Вхід у кабінет',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: !_isSignUp ? FontWeight.w800 : FontWeight.w600,
                                  color: !_isSignUp
                                      ? (isDark ? Colors.white : const Color(0xFF18181B))
                                      : (isDark ? AppTheme.darkMuted : AppTheme.muted),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _isSignUp = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isSignUp ? cardColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _isSignUp && !isDark
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Реєстрація',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _isSignUp ? FontWeight.w800 : FontWeight.w600,
                                  color: _isSignUp
                                      ? (isDark ? Colors.white : const Color(0xFF18181B))
                                      : (isDark ? AppTheme.darkMuted : AppTheme.muted),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 3. Google Sign-In Primary Button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark
                          ? const []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: cardColor,
                        foregroundColor: isDark ? Colors.white : const Color(0xFF18181B),
                        side: BorderSide(color: borderColor, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GoogleLogoWidget(size: 22),
                          SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Продовжити через Google',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Subtle Or Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: borderColor)),
                      Flexible(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'або за допомогою Email',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppTheme.darkMuted : AppTheme.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: borderColor)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. Form Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                      boxShadow: isDark ? const [] : AppTheme.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isSignUp) ...[
                          const Text('ВАШЕ ІМ\'Я', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person_outline, size: 20),
                              hintText: 'Олена або Сергій',
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        const Text('ЕЛЕКТРОННА ПОШТА (EMAIL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.email_outlined, size: 20),
                            hintText: 'ваша_пошта@vestora.app',
                          ),
                        ),
                        const SizedBox(height: 14),

                        const Text('ПАРОЛЬ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            hintText: 'Мінімум 6 символів',
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword ? 'Показати пароль' : 'Приховати пароль',
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),

                        if (_isSignUp) ...[
                          const SizedBox(height: 14),
                          const Text('ПІДТВЕРДЖЕННЯ ПАРОЛЮ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _confirmPassCtrl,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20),
                              hintText: 'Повторіть пароль',
                              suffixIcon: IconButton(
                                tooltip: _obscureConfirm ? 'Показати пароль' : 'Приховати пароль',
                                icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                          ),
                        ],

                        if (!_isSignUp) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              child: Text(
                                'Забули пароль?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppTheme.darkAccent : AppTheme.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.primary,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _isLoading ? null : _handleEmailSubmit,
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(
                                    _isSignUp ? 'Створити акаунт' : 'Увійти з Email та паролем',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 6. Guest / Skip Button
                  Center(
                    child: TextButton.icon(
                      onPressed: _isLoading ? null : _handleGuestSignIn,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.muted),
                      label: const Text(
                        'Продовжити як гість (Демо-режим)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.muted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 7. Security footer
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF16A34A)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '256-бітне шифрування даних · Vestora Security',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
