import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../config/app_config.dart';
import '../providers/report_provider.dart';

class MaintenanceDialog extends StatefulWidget {
  const MaintenanceDialog({super.key});

  @override
  State<MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends State<MaintenanceDialog> {
  String _startTime = '';
  String _endTime = '';
  final _commentController = TextEditingController();
  final List<String> _photos = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppConfig.warningColor,
            surface: AppConfig.cardColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _startTime = formatted;
        } else {
          _endTime = formatted;
        }
      });
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
      );
      if (photo != null) {
        setState(() => _photos.add(photo.path));
      }
    } catch (_) {}
  }

  void _save() {
    if (_startTime.isEmpty || _endTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('開始・終了時間を選択してください')),
      );
      return;
    }
    context.read<ReportProvider>().addMaintenanceRecord(
          _startTime,
          _endTime,
          _commentController.text.trim(),
          _photos,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppConfig.cardColor,
      shape: RoundedRectangleBorder(borderRadius: AppConfig.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConfig.warningColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.build_rounded,
                      color: AppConfig.warningColor, size: 22),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'トラブル記録\nMaintenance Record',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppConfig.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: AppConfig.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: 20),
            Divider(color: AppConfig.borderSecondary),
            SizedBox(height: 20),

            // Time Pickers
            Row(
              children: [
                Expanded(child: _buildTimeTile(
                  label: '開始 / Start',
                  value: _startTime,
                  onTap: () => _pickTime(true),
                )),
                SizedBox(width: 12),
                Expanded(child: _buildTimeTile(
                  label: '終了 / End',
                  value: _endTime,
                  onTap: () => _pickTime(false),
                )),
              ],
            ),

            // Duration preview
            if (_startTime.isNotEmpty && _endTime.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildDurationBadge(),
              ),
            SizedBox(height: 16),

            // Comment
            TextField(
              controller: _commentController,
              maxLines: 3,
              style: GoogleFonts.outfit(
                  fontSize: 14, color: AppConfig.textPrimary),
              decoration: InputDecoration(
                labelText: 'コメント / Comment',
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppConfig.inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: AppConfig.borderRadius,
                  borderSide: BorderSide(color: AppConfig.inputBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppConfig.borderRadius,
                  borderSide: BorderSide(color: AppConfig.inputBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppConfig.borderRadius,
                  borderSide:
                      BorderSide(color: AppConfig.warningColor, width: 2),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Photos section
            Row(
              children: [
                Text(
                  '写真 / Photos (${_photos.length})',
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppConfig.textSecondary),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _capturePhoto,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppConfig.warningColor.withOpacity(0.12),
                      borderRadius: AppConfig.radiusMd,
                      border: Border.all(
                          color: AppConfig.warningColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo_rounded,
                            size: 14, color: AppConfig.warningColor),
                        SizedBox(width: 6),
                        Text(
                          '撮影',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppConfig.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_photos.isNotEmpty) ...[
              SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_photos[i]),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _photos.removeAt(i)),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close_rounded,
                                size: 14, color: AppConfig.onAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.warningColor,
                  foregroundColor: AppConfig.onAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: AppConfig.borderRadius),
                ),
                child: Text(
                  '保存 / Save',
                  style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppConfig.backgroundColor,
          borderRadius: AppConfig.borderRadius,
          border: Border.all(
            color: value.isNotEmpty
                ? AppConfig.warningColor.withOpacity(0.5)
                : AppConfig.borderSecondary,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppConfig.textMuted,
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Text(
                  value.isEmpty ? '--:--' : value,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: value.isEmpty
                        ? AppConfig.textMuted
                        : AppConfig.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time_rounded,
                    size: 16, color: AppConfig.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationBadge() {
    try {
      final sP = _startTime.split(':');
      final eP = _endTime.split(':');
      final sMin = int.parse(sP[0]) * 60 + int.parse(sP[1]);
      final eMin = int.parse(eP[0]) * 60 + int.parse(eP[1]);
      final diff = eMin >= sMin ? eMin - sMin : (24 * 60 - sMin) + eMin;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppConfig.warningColor.withOpacity(0.12),
          borderRadius: AppConfig.radiusMd,
          border:
              Border.all(color: AppConfig.warningColor.withOpacity(0.4)),
        ),
        child: Text(
          '⏱  $diff分 / $diff min',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppConfig.warningColor,
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
