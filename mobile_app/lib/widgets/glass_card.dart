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

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius = 20,
    this.backgroundColor,
    this.border,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
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
                color: (widget.backgroundColor ?? Colors.white).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: widget.border ??
                    Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                boxShadow: AppTheme.softShadow,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
