import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final String? semanticLabel;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius = 20,
    this.backgroundColor,
    this.border,
    this.semanticLabel,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedBg = widget.backgroundColor ?? (isDark ? AppTheme.darkCard : Colors.white);

    Widget card = AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutBack,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: GestureDetector(
            onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
            onTapUp: widget.onTap != null
                ? (_) {
                    setState(() => _isPressed = false);
                    widget.onTap!();
                  }
                : null,
            onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: resolvedBg.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: widget.border ??
                    Border.all(
                      color: isDark
                          ? AppTheme.darkBorder
                          : Colors.white.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                boxShadow: isDark ? AppTheme.darkSoftShadow : AppTheme.softShadow,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.semanticLabel != null || widget.onTap != null) {
      card = Semantics(
        button: widget.onTap != null,
        label: widget.semanticLabel,
        child: card,
      );
    }
    return card;
  }
}
