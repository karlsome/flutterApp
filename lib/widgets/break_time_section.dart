import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/report_provider.dart';
import 'active_break_dialog.dart';

class BreakTimeSection extends StatelessWidget {
  const BreakTimeSection({super.key});

  int _calculateDuration(String start, String end) {
    if (start.isEmpty || end.isEmpty) return 0;
    try {
      final startParts = start.split(':');
      final endParts = end.split(':');
      final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      if (endMin >= startMin) {
        return endMin - startMin;
      } else {
        return (24 * 60 - startMin) + endMin;
      }
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(builder: (context, p, child) {
      final totalMin = p.totalBreakMinutes;
      final completedBreaks = p.breaks;
      final onBreak = p.isCurrentlyOnBreak;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Break Action Card/Button
          if (onBreak)
            _buildActiveBreakStatusCard(context, p)
          else
            _buildStartBreakButton(context, p),

          SizedBox(height: 16),

          // 2. Completed Breaks List
          if (completedBreaks.isNotEmpty) ...[
            Text(
              '休憩履歴 / Completed Breaks',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppConfig.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completedBreaks.length,
              itemBuilder: (context, i) {
                final b = completedBreaks[i];
                final start = b['start'] ?? '';
                final end = b['end'] ?? '';
                final duration = _calculateDuration(start, end);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppConfig.backgroundColor,
                    borderRadius: AppConfig.radiusMd,
                    border: Border.all(color: AppConfig.borderSecondary),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppConfig.borderSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppConfig.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$start 〜 $end',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppConfig.textPrimary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '休憩時間: $duration 分 / Duration: $duration mins',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppConfig.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: AppConfig.ngColor, size: 20),
                        onPressed: () {
                          p.removeBreak(i);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          // 3. Summary Container
          if (totalMin > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppConfig.primaryAccent.withOpacity(0.08),
                  borderRadius: AppConfig.borderRadius,
                  border: Border.all(color: AppConfig.primaryAccent.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_rounded, color: AppConfig.primaryAccent, size: 18),
                    SizedBox(width: 10),
                    Text(
                      '合計休憩時間 / Total Break',
                      style: GoogleFonts.outfit(fontSize: 13, color: AppConfig.textSecondary),
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

  Widget _buildStartBreakButton(BuildContext context, ReportProvider p) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          p.startBreak();
          ActiveBreakDialog.show(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConfig.primaryAccent,
          foregroundColor: AppConfig.onAccent,
          shape: RoundedRectangleBorder(
            borderRadius: AppConfig.borderRadius,
          ),
          elevation: 2,
        ),
        icon: Icon(Icons.play_circle_outline_rounded, size: 22),
        label: Text(
          '休憩を開始 / Start Break',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveBreakStatusCard(BuildContext context, ReportProvider p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.warningColor.withOpacity(0.08),
        borderRadius: AppConfig.borderRadius,
        border: Border.all(color: AppConfig.warningColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConfig.warningColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.coffee_rounded, color: AppConfig.onAccent, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '現在休憩中 / Currently on Break',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppConfig.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'タイマーがバックグラウンドで動作しています。',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppConfig.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            height: AppConfig.touchTarget,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ActiveBreakDialog.show(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConfig.warningColor,
                side: BorderSide(color: AppConfig.warningColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: AppConfig.borderRadius,
                ),
              ),
              icon: Icon(Icons.timer_rounded, size: 18),
              label: Text(
                'タイマーを表示 / Show Timer',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
