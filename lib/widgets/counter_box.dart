import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';

class CounterBox extends StatelessWidget {
  final String label;
  final String? subLabel;
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool enabled;
  final Color? color;
  final bool compact;

  const CounterBox({
    super.key,
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    this.subLabel,
    this.enabled = true,
    this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppConfig.primaryAccent;
    final hasValue = value > 0;

    if (compact) {
      return _CompactCounter(
        label: label,
        subLabel: subLabel,
        value: value,
        activeColor: activeColor,
        enabled: enabled,
        onIncrement: onIncrement,
        onDecrement: onDecrement,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasValue
            ? activeColor.withAlpha(25)
            : AppConfig.cardColor,
        borderRadius: AppConfig.borderRadius,
        border: Border.all(
          color: hasValue ? activeColor.withAlpha(100) : AppConfig.borderSecondary,
          width: hasValue ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: enabled
                  ? (hasValue ? activeColor : AppConfig.textSecondary)
                  : AppConfig.textMuted,
            ),
          ),
          if (subLabel != null) ...[
            SizedBox(height: 2),
            Text(
              subLabel!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: AppConfig.textMuted,
              ),
            ),
          ],
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CountBtn(
                icon: Icons.remove_rounded,
                onTap: (enabled && value > 0) ? onDecrement : null,
                color: activeColor,
              ),
              Text(
                value.toString(),
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: hasValue ? activeColor : AppConfig.textMuted,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              _CountBtn(
                icon: Icons.add_rounded,
                onTap: enabled ? onIncrement : null,
                color: activeColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactCounter extends StatelessWidget {
  final String label;
  final String? subLabel;
  final int value;
  final Color activeColor;
  final bool enabled;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CompactCounter({
    required this.label,
    this.subLabel,
    required this.value,
    required this.activeColor,
    required this.enabled,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: hasValue ? activeColor.withAlpha(20) : AppConfig.cardColor,
        borderRadius: AppConfig.borderRadius,
        border: Border.all(
          color: hasValue ? activeColor.withAlpha(80) : AppConfig.borderSecondary,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: hasValue ? activeColor : AppConfig.textMuted,
            ),
          ),
          if (subLabel != null)
            Text(
              subLabel!,
              style: GoogleFonts.outfit(fontSize: 10, color: AppConfig.textMuted),
            ),
          SizedBox(height: 4),
          Text(
            value.toString(),
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: hasValue ? activeColor : AppConfig.textMuted,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: (enabled && value > 0) ? onDecrement : null,
                child: Icon(
                  Icons.remove_circle_outline_rounded,
                  size: 20,
                  color: (enabled && value > 0) ? activeColor : AppConfig.textMuted,
                ),
              ),
              SizedBox(width: 12),
              GestureDetector(
                onTap: enabled ? onIncrement : null,
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  size: 20,
                  color: enabled ? activeColor : AppConfig.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _CountBtn({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withAlpha(30)
              : AppConfig.backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? color : AppConfig.textMuted,
        ),
      ),
    );
  }
}
