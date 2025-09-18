import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class GreenAnimatedButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool toggled;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool enableColorTransition;
  final bool enableScaleOnPress;
  final bool showRipple;

  const GreenAnimatedButton({
    super.key,
    required this.label,
    this.icon,
    this.toggled = false,
    this.onPressed,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.enableColorTransition = true,
    this.enableScaleOnPress = true,
    this.showRipple = true,
  });

  @override
  State<GreenAnimatedButton> createState() => _GreenAnimatedButtonState();
}

class _GreenAnimatedButtonState extends State<GreenAnimatedButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color startColor = AppTheme.primaryGreen;
    final Color endColor = AppTheme.accentGreen;

    final Color backgroundColor = widget.enableColorTransition
        ? (widget.toggled ? endColor : startColor)
        : startColor;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
          child: Icon(
            widget.toggled ? Icons.check_rounded : (widget.icon ?? Icons.eco_rounded),
            key: ValueKey<bool>(widget.toggled),
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );

    Widget buttonCore = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.25),
            blurRadius: _pressed ? 10 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: content,
    );

    if (widget.enableScaleOnPress) {
      buttonCore = AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.96 : 1.0,
        curve: Curves.easeOut,
        child: buttonCore,
      );
    }

    final Widget tappable = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: buttonCore,
    );

    if (!widget.showRipple) return tappable;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        splashColor: Colors.white.withOpacity(0.12),
        highlightColor: Colors.white.withOpacity(0.06),
        onTap: widget.onPressed,
        child: tappable,
      ),
    );
  }
}


