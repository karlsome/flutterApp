import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../config/app_config.dart';
import '../providers/report_provider.dart';
import '../widgets/counter_box.dart';
import '../widgets/product_details_sheet.dart';
import '../widgets/qr_scanner_dialog.dart';
import '../widgets/worker_select_sheet.dart';
import '../widgets/maintenance_dialog.dart';
import '../widgets/break_time_section.dart';
import '../widgets/setup_wizard_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final _processQtyController = TextEditingController();
  final _shotController = TextEditingController();
  final _dcpCommentController = TextEditingController();
  final _kensaCommentController = TextEditingController();
  final _labelExtController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late AnimationController _headerAnimController;
  late Animation<double> _headerFade;

  bool _isHeaderCollapsed = false;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _headerFade = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );
    _headerAnimController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _processQtyController.dispose();
    _shotController.dispose();
    _dcpCommentController.dispose();
    _kensaCommentController.dispose();
    _labelExtController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> _pickTime(BuildContext ctx, String label,
      Future<void> Function(String) onSet) async {
    final TimeOfDay? picked = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.now(),
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
      await onSet(formatted);
    }
  }

  Future<void> _pickDate(BuildContext ctx) async {
    final provider = ctx.read<ReportProvider>();
    final picked = await showDatePicker(
      context: ctx,
      initialDate: provider.workDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
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
      provider.setWorkDate(picked);
    }
  }

  Future<void> _capturePhoto(BuildContext ctx, bool isHatsumono) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo != null && ctx.mounted) {
        final provider = ctx.read<ReportProvider>();
        if (isHatsumono) {
          provider.setHatsumonoPhoto(photo.path, true);
        } else {
          provider.setAtomonoPhoto(photo.path, true);
        }
      }
    } catch (e) {
      if (ctx.mounted) {
        _showSnack(ctx, 'カメラへのアクセスに失敗しました / Camera access failed', isError: true);
      }
    }
  }

  Future<void> _captureMaterialLabelPhoto(BuildContext ctx) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
      );
      if (photo != null && ctx.mounted) {
        ctx.read<ReportProvider>().addMaterialLabelPhoto(photo.path);
      }
    } catch (_) {}
  }

  void _showSnack(BuildContext ctx, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppConfig.ngColor : AppConfig.okColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitForm(BuildContext ctx) async {
    final provider = ctx.read<ReportProvider>();
    try {
      final success = await provider.submitReport();
      if (success && ctx.mounted) {
        _processQtyController.clear();
        _shotController.clear();
        _dcpCommentController.clear();
        _kensaCommentController.clear();
        _labelExtController.clear();
        _showSnack(ctx, '提出完了！/ Submission successful!');
      }
    } catch (e) {
      if (ctx.mounted) {
        _showSnack(ctx, e.toString().replaceFirst('Exception: ', ''),
            isError: true);
      }
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            _buildProductHeader(context),
            const Divider(color: AppConfig.borderSecondary, height: 1),
            Expanded(
              child: Consumer<ReportProvider>(
                builder: (_, p, __) {
                  final isWizardActive = p.setupStep != 0;
                  return Stack(
                    children: [
                      AbsorbPointer(
                        absorbing: isWizardActive,
                        child: Opacity(
                          opacity: isWizardActive ? 0.35 : 1.0,
                          child: ListView(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                            children: [
                              _buildDcpSection(context),
                              const SizedBox(height: 16),
                              _buildCycleCheckSection(context),
                              const SizedBox(height: 16),
                              _buildBreakSection(context),
                              const SizedBox(height: 16),
                              _buildMaintenanceSection(context),
                              const SizedBox(height: 16),
                              _buildKensaSection(context),
                            ],
                          ),
                        ),
                      ),
                      if (isWizardActive)
                        _buildSetupWizardOverlay(context, p),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Floating action submit button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildSubmitBar(context),
    );
  }

  Widget _buildSetupWizardOverlay(BuildContext context, ReportProvider p) {
    return Container(
      color: Colors.black.withOpacity(0.04),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: AppConfig.cardColor,
          borderRadius: AppConfig.cardRadius,
          border: Border.all(color: AppConfig.borderSecondary, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConfig.warningColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppConfig.warningColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '段取りスキャン検証未完了\nSetup Validation Incomplete',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConfig.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '作業を開始するには、背番号・材料ロットの照合段取りスキャン（STEP 1〜3）を完了させてください。',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppConfig.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => SetupWizardDialog.show(context),
                icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
                label: const Text(
                  '段取り検証を開始する / Start Setup',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // TOP BAR
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Consumer<ReportProvider>(builder: (_, p, __) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppConfig.backgroundColor,
        child: Row(
          children: [
            // Factory / Machine badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppConfig.primaryAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppConfig.primaryAccent.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.factory_rounded,
                      size: 14, color: AppConfig.primaryAccent),
                  const SizedBox(width: 6),
                  Text(
                    '${p.selectedFactory}  ·  ${p.selectedMachine}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppConfig.primaryAccent,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Sync indicator
            if (p.logQueue.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConfig.warningColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppConfig.warningColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 12, color: AppConfig.warningColor),
                    const SizedBox(width: 4),
                    Text(
                      '${p.logQueue.length}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppConfig.warningColor,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            // Settings button
            IconButton(
              icon: const Icon(Icons.settings_rounded,
                  color: AppConfig.textSecondary, size: 22),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: '設定 / Settings',
            ),
          ],
        ),
      );
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  // PRODUCT HEADER (collapsed / expanded)
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildProductHeader(BuildContext context) {
    return Consumer<ReportProvider>(builder: (_, p, __) {
      final product = p.activeProduct;
      final hasProduct = product.productNumber.isNotEmpty;

      return GestureDetector(
        onTap: hasProduct
            ? () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ProductDetailsSheet(product: product),
                )
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: const BoxDecoration(color: AppConfig.backgroundColor),
          child: Row(
            children: [
              // Scan / Barcode trigger
              _buildSebanggoScanner(context, p),
              const SizedBox(width: 16),
              // Product preview (image + 背番号 + 品番)
              Expanded(child: _buildProductPreview(p, hasProduct)),
              // Expand arrow when product loaded
              if (hasProduct)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: AppConfig.primaryAccent,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSebanggoScanner(BuildContext ctx, ReportProvider p) {
    return GestureDetector(
      onTap: () => SetupWizardDialog.show(ctx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          gradient: p.sebanggo.isNotEmpty
              ? AppConfig.primaryGradient
              : null,
          color: p.sebanggo.isEmpty ? AppConfig.cardColor : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: p.sebanggo.isNotEmpty
                ? AppConfig.primaryAccent
                : AppConfig.borderSecondary,
            width: 1.5,
          ),
          boxShadow: p.sebanggo.isNotEmpty
              ? [
                  BoxShadow(
                    color: AppConfig.primaryAccent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: p.isLoading
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    p.sebanggo.isNotEmpty
                        ? Icons.qr_code_scanner_rounded
                        : Icons.qr_code_rounded,
                    color: p.sebanggo.isNotEmpty
                        ? Colors.white
                        : AppConfig.textMuted,
                    size: 32,
                  ),
                  if (p.sebanggo.isEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'SCAN',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppConfig.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildProductPreview(ReportProvider p, bool hasProduct) {
    if (!hasProduct && p.sebanggo.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '背番号をスキャンしてください',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: AppConfig.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scan product kanban to start',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppConfig.textMuted,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 背番号
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppConfig.primaryAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '背番号',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppConfig.primaryAccent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                p.sebanggo,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppConfig.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (hasProduct) ...[
          const SizedBox(height: 4),
          // 品番
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppConfig.textMuted.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '品番',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppConfig.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  p.activeProduct.productNumber,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConfig.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '↑ 詳細',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppConfig.primaryAccent,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // DCP SECTION
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildDcpSection(BuildContext context) {
    return _SectionCard(
      title: '加工記録 / DCP Process Record',
      icon: Icons.precision_manufacturing_rounded,
      child: Consumer<ReportProvider>(builder: (_, p, __) {
        return Column(
          children: [
            // Row 1: Worker + Date
            Row(children: [
              Expanded(child: _buildWorkerField(context, p, false)),
              const SizedBox(width: 12),
              Expanded(child: _buildDateField(context, p)),
            ]),
            const SizedBox(height: 12),

            // Row 2: Start + End time
            Row(children: [
              Expanded(
                child: _buildTimeField(
                  context,
                  label: '開始 / Start',
                  value: p.startTime,
                  onTap: () => _pickTime(
                    context,
                    'Start',
                    (t) async => p.setStartTime(t),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeField(
                  context,
                  label: '終了 / End',
                  value: p.endTime,
                  onTap: () => _pickTime(
                    context,
                    'End',
                    (t) async => p.setEndTime(t),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // Row 3: Process Qty + Shot count
            Row(children: [
              Expanded(
                child: _buildNumberField(
                  label: '加工数 / Qty',
                  controller: _processQtyController,
                  hint: '0',
                  onChanged: (v) {
                    final val = int.tryParse(v) ?? 0;
                    p.setProcessQuantity(val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  label: 'ショット数 / Shots',
                  controller: _shotController,
                  hint: '0',
                  onChanged: (v) {
                    final val = int.tryParse(v) ?? 0;
                    p.setShotCount(val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  label: 'ラベル拡張 / Label Ext.',
                  controller: _labelExtController,
                  hint: '',
                  isNumericOnly: false,
                  onChanged: (v) => p.setLabelExtension(v),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Material Lots
            _buildMaterialLotSection(context, p),
            const SizedBox(height: 16),

            // NG Defect Counters
            _buildDefectCounters(p),
            const SizedBox(height: 16),

            // Totals summary
            _buildDcpSummaryRow(p),
            const SizedBox(height: 12),

            // Comment field
            _buildCommentField(
              controller: _dcpCommentController,
              label: 'コメント / Comment (DCP)',
              onChanged: p.setCommentsDcp,
            ),
            const SizedBox(height: 16),

            // Send to Machine button
            _buildSendToMachineButton(context),
            const SizedBox(height: 12),

            // Print button
            _buildPrintButton(context),
          ],
        );
      }),
    );
  }

  Widget _buildWorkerField(BuildContext ctx, ReportProvider p, bool isKensa) {
    final name = isKensa ? p.kensaName : p.workerName;
    return GestureDetector(
      onTap: () => WorkerSelectSheet.show(
        context: ctx,
        allWorkers: p.workers,
        role: isKensa ? 'kensa' : 'worker',
        factory: p.selectedFactory,
        onSelected: (selected) {
          if (isKensa) {
            p.setKensaName(selected);
          } else {
            p.setWorkerName(selected);
          }
        },
      ),
      child: _FieldContainer(
        label: isKensa ? '検査者 / Inspector' : '作業者 / Worker',
        child: Row(
          children: [
            Expanded(
              child: Text(
                name.isEmpty ? 'タップして選択' : name,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: name.isEmpty
                      ? AppConfig.textMuted
                      : AppConfig.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.person_search_rounded,
                size: 18, color: AppConfig.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext ctx, ReportProvider p) {
    final dateStr =
        '${p.workDate.year}/${p.workDate.month.toString().padLeft(2, '0')}/${p.workDate.day.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () => _pickDate(ctx),
      child: _FieldContainer(
        label: '日付 / Date',
        child: Row(
          children: [
            Expanded(
              child: Text(
                dateStr,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppConfig.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.calendar_month_rounded,
                size: 18, color: AppConfig.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField(BuildContext ctx,
      {required String label,
      required String value,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: _FieldContainer(
        label: label,
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? '--:--' : value,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: value.isEmpty ? AppConfig.textMuted : AppConfig.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const Icon(Icons.access_time_rounded,
                size: 18, color: AppConfig.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
    bool isNumericOnly = true,
  }) {
    return _FieldContainer(
      label: label,
      child: TextField(
        controller: controller,
        keyboardType: isNumericOnly
            ? const TextInputType.numberWithOptions(signed: false)
            : TextInputType.text,
        inputFormatters:
            isNumericOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppConfig.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: AppConfig.textMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMaterialLotSection(BuildContext ctx, ReportProvider p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConfig.backgroundColor,
        borderRadius: AppConfig.borderRadius,
        border: Border.all(color: AppConfig.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded,
                  size: 16, color: AppConfig.textSecondary),
              const SizedBox(width: 8),
              Text(
                '材料ロット / Material Lots',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppConfig.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _openScanner(ctx, 'lot'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppConfig.primaryAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded,
                          size: 14, color: AppConfig.primaryAccent),
                      const SizedBox(width: 6),
                      Text(
                        'スキャン',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppConfig.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (p.materialLots.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '材料ロットをスキャンしてください / Scan material lot',
                style: GoogleFonts.outfit(
                    fontSize: 13, color: AppConfig.textMuted),
              ),
            )
          else ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.materialLots.map((lot) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppConfig.primaryAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lot,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppConfig.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => p.removeMaterialLot(lot),
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: AppConfig.textMuted),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefectCounters(ReportProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '不良カウンター / Defect Counters',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppConfig.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CounterBox(
                label: '疵引不良',
                subLabel: 'Pull Defect',
                value: p.defectPull,
                color: AppConfig.ngColor,
                onIncrement: () => p.incrementDcpCounter(18),
                onDecrement: () => p.decrementDcpCounter(18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CounterBox(
                label: '加工不良',
                subLabel: 'Process Defect',
                value: p.processingDefect,
                color: AppConfig.ngColor,
                onIncrement: () => p.incrementDcpCounter(19),
                onDecrement: () => p.decrementDcpCounter(19),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CounterBox(
                label: 'その他',
                subLabel: 'Other',
                value: p.otherDefect,
                color: AppConfig.warningColor,
                onIncrement: () => p.incrementDcpCounter(20),
                onDecrement: () => p.decrementDcpCounter(20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDcpSummaryRow(ReportProvider p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF1E3A2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppConfig.borderRadius,
        border: Border.all(color: AppConfig.okColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _SummaryCell(
            label: '加工数\nQty',
            value: p.processQuantity.toString(),
            color: AppConfig.textPrimary,
          ),
          _summaryDivider(),
          _SummaryCell(
            label: 'NG合計\nTotal NG',
            value: p.totalNG.toString(),
            color: p.totalNG > 0 ? AppConfig.ngColor : AppConfig.textPrimary,
          ),
          _summaryDivider(),
          _SummaryCell(
            label: '良品合計\nGood Total',
            value: p.finalGoodQuantity.toString(),
            color: p.finalGoodQuantity > 0 ? AppConfig.okColor : AppConfig.textSecondary,
          ),
          _summaryDivider(),
          _SummaryCell(
            label: '正味時間\nWork Hours',
            value: p.totalWorkHours.toStringAsFixed(1) + 'h',
            color: AppConfig.primaryAccent,
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() =>
      Container(width: 1, height: 36, color: AppConfig.borderSecondary,
          margin: const EdgeInsets.symmetric(horizontal: 12));

  Widget _buildCommentField({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: 3,
      style: GoogleFonts.outfit(fontSize: 14, color: AppConfig.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        filled: true,
        fillColor: AppConfig.cardColor,
        border: OutlineInputBorder(
          borderRadius: AppConfig.borderRadius,
          borderSide: const BorderSide(color: AppConfig.borderSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppConfig.borderRadius,
          borderSide: const BorderSide(color: AppConfig.borderSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppConfig.borderRadius,
          borderSide: const BorderSide(color: AppConfig.primaryAccent, width: 2),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildSendToMachineButton(BuildContext ctx) {
    return Consumer<ReportProvider>(builder: (_, p, __) {
      final isEnabled = p.sebanggo.isNotEmpty && !p.isSendingToNC;
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: isEnabled ? AppConfig.primaryGradient : null,
            color: isEnabled ? null : AppConfig.cardColor,
            borderRadius: AppConfig.borderRadius,
            border: Border.all(
              color: isEnabled ? Colors.transparent : AppConfig.borderSecondary,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppConfig.borderRadius,
              onTap: isEnabled
                  ? () async {
                      try {
                        await p.sendToNC(ctx);
                        if (ctx.mounted) {
                          _showSnack(ctx, 'マシンにデータを送信しました / Data sent to machine successfully!');
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          _showSnack(ctx, e.toString().replaceFirst('Exception: ', ''),
                              isError: true);
                        }
                      }
                    }
                  : null,
              child: Center(
                child: p.isSendingToNC
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.precision_manufacturing_rounded,
                            color: isEnabled ? Colors.white : AppConfig.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '機械に送信 / Send to Machine',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isEnabled ? Colors.white : AppConfig.textMuted,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPrintButton(BuildContext ctx) {
    return Consumer<ReportProvider>(builder: (_, p, __) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: p.sebanggo.isEmpty
              ? null
              : () async {
                  try {
                    await p.triggerPrint(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      _showSnack(ctx, e.toString().replaceFirst('Exception: ', ''),
                          isError: true);
                    }
                  }
                },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppConfig.primaryAccent),
            foregroundColor: AppConfig.primaryAccent,
            shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
          ),
          icon: const Icon(Icons.print_rounded, size: 20),
          label: Text(
            'ラベル印刷 / Print Label',
            style: GoogleFonts.outfit(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      );
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  // CYCLE CHECK (Hatsumono / Atomono photos)
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildCycleCheckSection(BuildContext context) {
    return _SectionCard(
      title: '初物・後物チェック / Cycle Check Photos',
      icon: Icons.camera_alt_rounded,
      child: Consumer<ReportProvider>(builder: (_, p, __) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildPhotoCard(
                    context: context,
                    label: '初物 / Hatsumono',
                    isFirst: true,
                    photoPath: p.hatsumonoPhotoPath,
                    checked: p.hatsumonoChecked,
                    onTap: () => _capturePhoto(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPhotoCard(
                    context: context,
                    label: '後物 / Atomono',
                    isFirst: false,
                    photoPath: p.atomonoPhotoPath,
                    checked: p.atomonoChecked,
                    onTap: () => _capturePhoto(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Material label photos
            _buildMaterialLabelPhotos(context, p),
          ],
        );
      }),
    );
  }

  Widget _buildPhotoCard({
    required BuildContext context,
    required String label,
    required bool isFirst,
    required String photoPath,
    required bool checked,
    required VoidCallback onTap,
  }) {
    final hasPic = photoPath.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 140,
        decoration: BoxDecoration(
          color: hasPic ? Colors.transparent : AppConfig.cardColor,
          borderRadius: AppConfig.borderRadius,
          border: Border.all(
            color: checked
                ? AppConfig.okColor
                : (hasPic ? AppConfig.primaryAccent : AppConfig.borderSecondary),
            width: checked ? 2 : 1,
          ),
          boxShadow: checked
              ? [
                  BoxShadow(
                    color: AppConfig.okColor.withOpacity(0.2),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: AppConfig.borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPic)
                Image.file(
                  File(photoPath),
                  fit: BoxFit.cover,
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_rounded,
                      size: 32,
                      color: AppConfig.textMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppConfig.textSecondary,
                      ),
                    ),
                  ],
                ),
              // Overlay label bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (checked)
                        const Icon(Icons.check_circle_rounded,
                            color: AppConfig.okColor, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialLabelPhotos(BuildContext ctx, ReportProvider p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConfig.backgroundColor,
        borderRadius: AppConfig.borderRadius,
        border: Border.all(color: AppConfig.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.label_rounded,
                size: 16, color: AppConfig.textSecondary),
            const SizedBox(width: 8),
            Text(
              '材料ラベル写真 / Material Label Photos',
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppConfig.textSecondary),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _captureMaterialLabelPhoto(ctx),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppConfig.primaryAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_a_photo_rounded,
                    size: 16, color: AppConfig.primaryAccent),
              ),
            ),
          ]),
          if (p.materialLabelPhotos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: p.materialLabelPhotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(p.materialLabelPhotos[i]),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => p.removeMaterialLabelPhoto(i),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // BREAK TIME SECTION
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildBreakSection(BuildContext context) {
    return _SectionCard(
      title: '休憩時間 / Break Times',
      icon: Icons.coffee_rounded,
      child: const BreakTimeSection(),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // MAINTENANCE SECTION
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildMaintenanceSection(BuildContext context) {
    return _SectionCard(
      title: 'トラブル・保全 / Maintenance',
      icon: Icons.build_rounded,
      child: Consumer<ReportProvider>(builder: (_, p, __) {
        return Column(
          children: [
            ...p.maintenanceRecords.asMap().entries.map((entry) {
              final i = entry.key;
              final rec = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConfig.warningColor.withOpacity(0.08),
                  borderRadius: AppConfig.borderRadius,
                  border: Border.all(
                      color: AppConfig.warningColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppConfig.warningColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${rec.startTime} → ${rec.endTime}  (${rec.durationMinutes}min)',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppConfig.textPrimary,
                            ),
                          ),
                          if (rec.comment.isNotEmpty)
                            Text(
                              rec.comment,
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppConfig.textSecondary),
                            ),
                          if (rec.photos.isNotEmpty)
                            Text(
                              '📷 ${rec.photos.length}枚',
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppConfig.textMuted),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppConfig.ngColor, size: 20),
                      onPressed: () => p.deleteMaintenanceRecord(i),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const MaintenanceDialog(),
                ),
                style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: AppConfig.warningColor),
                  foregroundColor: AppConfig.warningColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: AppConfig.borderRadius),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  'トラブル記録を追加 / Add Maintenance',
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // KENSA SECTION
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildKensaSection(BuildContext context) {
    return Consumer<ReportProvider>(builder: (_, p, __) {
      return _SectionCard(
        title: '検査記録 / Inspection (Kensa)',
        icon: Icons.verified_rounded,
        trailing: Switch(
          value: p.isKensaEnabled,
          onChanged: p.toggleKensaMode,
          activeThumbColor: AppConfig.primaryAccent,
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: p.isKensaEnabled
              ? Column(
                  children: [
                    // Kensa worker + dates
                    Row(children: [
                      Expanded(
                          child: _buildWorkerField(context, p, true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDateField(context, p)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: _buildTimeField(
                          context,
                          label: '検査開始 / Start',
                          value: p.kensaStartTime,
                          onTap: () => _pickTime(context, 'KensaStart',
                              (t) async => p.setKensaStartTime(t)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeField(
                          context,
                          label: '検査終了 / End',
                          value: p.kensaEndTime,
                          onTap: () => _pickTime(context, 'KensaEnd',
                              (t) async => p.setKensaEndTime(t)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // Kensa counters 1–12
                    Text(
                      '検査カウンター / Inspection Counters',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConfig.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.6,
                      ),
                      itemCount: 12,
                      itemBuilder: (_, i) => CounterBox(
                        label: 'C${i + 1}',
                        subLabel: 'Counter ${i + 1}',
                        value: p.kensaCounters[i],
                        color: p.kensaCounters[i] > 0
                            ? AppConfig.ngColor
                            : AppConfig.textSecondary,
                        onIncrement: () => p.incrementKensaCounter(i),
                        onDecrement: () => p.decrementKensaCounter(i),
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCommentField(
                      controller: _kensaCommentController,
                      label: 'コメント / Comment (Kensa)',
                      onChanged: p.setCommentsKensa,
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      );
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  // SUBMIT BAR (floating)
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildSubmitBar(BuildContext context) {
    return Consumer<ReportProvider>(builder: (_, p, __) {
      if (p.setupStep != 0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: p.isSubmitting ? null : AppConfig.primaryGradient,
            color: p.isSubmitting ? AppConfig.cardColor : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppConfig.primaryAccent.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap:
                  p.isSubmitting ? null : () => _submitForm(context),
              child: Center(
                child: p.isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '送信中... / Submitting...',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppConfig.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded,
                              color: Colors.white, size: 22),
                          const SizedBox(width: 12),
                          Text(
                            '記録を提出 / Submit Report',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  // QR SCANNER helper
  // ────────────────────────────────────────────────────────────────────────────

  void _openScanner(BuildContext ctx, String mode) {
    QrScannerDialog.show(
      context: ctx,
      title: mode == 'sebanggo' ? '背番号スキャン / Scan Kanban' : '材料ロットスキャン / Scan Lot',
      instruction: mode == 'sebanggo'
          ? 'カンバンのバーコードをスキャンしてください\nScan the kanban barcode'
          : '材料ラベルをスキャンしてください\nScan the material lot barcode',
      onScanSuccess: (value) {
        final p = ctx.read<ReportProvider>();
        if (mode == 'sebanggo') {
          p.setSebanggo(value.trim().toUpperCase());
        } else if (mode == 'lot') {
          p.addMaterialLot(value.trim());
        }
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// SHARED REUSABLE WIDGETS
// ────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: AppConfig.cardRadius,
        border: Border.all(color: AppConfig.borderSecondary),
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: widget.trailing == null
                ? () => setState(() => _expanded = !_expanded)
                : null,
            borderRadius: AppConfig.cardRadius,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConfig.primaryAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon,
                        color: AppConfig.primaryAccent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppConfig.textPrimary,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!
                  else
                    AnimatedRotation(
                      turns: _expanded ? 0 : -0.25,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppConfig.textMuted, size: 22),
                    ),
                ],
              ),
            ),
          ),
          // Content
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: widget.child,
                  )
                : const SizedBox(height: 0),
          ),
        ],
      ),
    );
  }
}

class _FieldContainer extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldContainer({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppConfig.backgroundColor,
        borderRadius: AppConfig.borderRadius,
        border: Border.all(color: AppConfig.borderSecondary),
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
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCell(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: AppConfig.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
