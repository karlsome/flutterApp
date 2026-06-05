import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/report_provider.dart';

class BreakTimeSection extends StatelessWidget {
  const BreakTimeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(builder: (_, p, __) {
      final totalMin = p.totalBreakMinutes;

      return Column(
        children: [
          ...List.generate(4, (i) => _BreakRow(index: i)),
          if (totalMin > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppConfig.primaryAccent.withOpacity(0.08),
                  borderRadius: AppConfig.borderRadius,
                  border: Border.all(
                      color: AppConfig.primaryAccent.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded,
                        color: AppConfig.primaryAccent, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '合計休憩 / Total Break',
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: AppConfig.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      '$totalMin 分 / ${(totalMin / 60.0).toStringAsFixed(1)} h',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppConfig.primaryAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _BreakRow extends StatelessWidget {
  final int index;
  const _BreakRow({required this.index});

  Future<void> _pick(BuildContext ctx, bool isStart) async {
    final p = ctx.read<ReportProvider>();
    final current = p.breaks[index][isStart ? 'start' : 'end'] ?? '';
    TimeOfDay initial = TimeOfDay.now();
    if (current.isNotEmpty) {
      final parts = current.split(':');
      initial =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    final picked = await showTimePicker(
      context: ctx,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppConfig.primaryAccent,
            surface: AppConfig.cardColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      p.updateBreak(index, isStart ? 'start' : 'end', formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(builder: (_, p, __) {
      final start = p.breaks[index]['start'] ?? '';
      final end = p.breaks[index]['end'] ?? '';
      final hasData = start.isNotEmpty || end.isNotEmpty;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: hasData
                    ? AppConfig.primaryAccent.withOpacity(0.15)
                    : AppConfig.backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasData
                      ? AppConfig.primaryAccent.withOpacity(0.4)
                      : AppConfig.borderSecondary,
                ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: hasData
                        ? AppConfig.primaryAccent
                        : AppConfig.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _pick(context, true),
                child: _TimeChip(
                  label: '開始',
                  value: start,
                  active: start.isNotEmpty,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                size: 16, color: AppConfig.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => _pick(context, false),
                child: _TimeChip(
                  label: '終了',
                  value: end,
                  active: end.isNotEmpty,
                ),
              ),
            ),
            if (hasData)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () {
                    p.updateBreak(index, 'start', '');
                    p.updateBreak(index, 'end', '');
                  },
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AppConfig.textMuted),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  const _TimeChip(
      {required this.label, required this.value, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? AppConfig.primaryAccent.withOpacity(0.1)
            : AppConfig.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? AppConfig.primaryAccent.withOpacity(0.4)
              : AppConfig.borderSecondary,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value.isEmpty ? '$label --:--' : value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: active ? AppConfig.textPrimary : AppConfig.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const Icon(Icons.access_time_rounded,
              size: 14, color: AppConfig.textMuted),
        ],
      ),
    );
  }
}
