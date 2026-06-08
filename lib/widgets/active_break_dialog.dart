import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/report_provider.dart';

class ActiveBreakDialog extends StatefulWidget {
  const ActiveBreakDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // Force them to use the finish button
      builder: (context) => const ActiveBreakDialog(),
    );
  }

  @override
  State<ActiveBreakDialog> createState() => _ActiveBreakDialogState();
}

class _ActiveBreakDialogState extends State<ActiveBreakDialog> {
  Timer? _timer;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    final p = Provider.of<ReportProvider>(context, listen: false);
    _startTime = p.activeBreakStartTime ?? DateTime.now();

    // Tick every second to update elapsed time UI
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, p, child) {
        // Fallback safety if active break is stopped elsewhere
        if (!p.isCurrentlyOnBreak) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
          return const SizedBox.shrink();
        }

        final startTimeStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
        final elapsed = DateTime.now().difference(_startTime);

        return PopScope(
          canPop: false, // Prevent dismissing with android back button
          child: Dialog.fullscreen(
            backgroundColor: Colors.black.withOpacity(0.95),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header / Context
                    Column(
                      children: [
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppConfig.primaryAccent.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.coffee_rounded,
                            color: AppConfig.primaryAccent,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '休憩中 / On Break',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '開始時刻: $startTimeStr (Started at $startTimeStr)',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppConfig.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Huge Digital Timer
                    Column(
                      children: [
                        Text(
                          _formatDuration(elapsed),
                          style: GoogleFonts.outfit(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            color: AppConfig.primaryAccent,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '経過時間 / Elapsed Time',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppConfig.textMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),

                    // Stop button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 64,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                p.stopBreak();
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('休憩を終了し、記録しました / Break finished & logged'),
                                    backgroundColor: AppConfig.okColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConfig.ngColor,
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: AppConfig.ngColor.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: const Icon(Icons.stop_circle_rounded, size: 28),
                              label: Text(
                                '休憩終了 / Finish Break',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
        );
      },
    );
  }
}
