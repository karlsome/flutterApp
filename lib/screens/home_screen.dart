import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../providers/report_provider.dart';
import '../models/product_model.dart';
import '../models/equipment_model.dart';
import '../widgets/product_details_sheet.dart';
import '../widgets/qr_scanner_dialog.dart';
import '../widgets/worker_select_sheet.dart';
import '../widgets/maintenance_dialog.dart';
import '../widgets/break_time_section.dart';
import 'setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _processQtyController = TextEditingController();
  final TextEditingController _shotController = TextEditingController();
  final TextEditingController _dcpCommentController = TextEditingController();
  final TextEditingController _kensaCommentController = TextEditingController();
  final TextEditingController _labelExtController = TextEditingController();

  final FocusNode _processQtyFocus = FocusNode();
  final FocusNode _shotFocus = FocusNode();
  final FocusNode _dcpCommentFocus = FocusNode();
  final FocusNode _kensaCommentFocus = FocusNode();
  final FocusNode _labelExtFocus = FocusNode();

  String _scanError = '';
  bool _isScanProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ReportProvider>(context, listen: false);
      provider.addListener(_onProviderChange);
      
      // Initialize controller text values
      _processQtyController.text = provider.processQuantity > 0 ? provider.processQuantity.toString() : '';
      _shotController.text = provider.shotCount > 0 ? provider.shotCount.toString() : '';
      _dcpCommentController.text = provider.commentsDcp;
      _kensaCommentController.text = provider.commentsKensa;
      _labelExtController.text = provider.labelExtension;
    });
  }

  @override
  void dispose() {
    try {
      Provider.of<ReportProvider>(context, listen: false).removeListener(_onProviderChange);
    } catch (_) {}
    _processQtyController.dispose();
    _shotController.dispose();
    _dcpCommentController.dispose();
    _kensaCommentController.dispose();
    _labelExtController.dispose();

    _processQtyFocus.dispose();
    _shotFocus.dispose();
    _dcpCommentFocus.dispose();
    _kensaCommentFocus.dispose();
    _labelExtFocus.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    if (!mounted) return;
    final provider = Provider.of<ReportProvider>(context, listen: false);
    
    if (!_processQtyFocus.hasFocus) {
      final qtyStr = provider.processQuantity > 0 ? provider.processQuantity.toString() : '';
      if (_processQtyController.text != qtyStr) {
        _processQtyController.text = qtyStr;
      }
    }
    if (!_shotFocus.hasFocus) {
      final shotStr = provider.shotCount > 0 ? provider.shotCount.toString() : '';
      if (_shotController.text != shotStr) {
        _shotController.text = shotStr;
      }
    }
    if (!_dcpCommentFocus.hasFocus) {
      if (_dcpCommentController.text != provider.commentsDcp) {
        _dcpCommentController.text = provider.commentsDcp;
      }
    }
    if (!_kensaCommentFocus.hasFocus) {
      if (_kensaCommentController.text != provider.commentsKensa) {
        _kensaCommentController.text = provider.commentsKensa;
      }
    }
    if (!_labelExtFocus.hasFocus) {
      if (_labelExtController.text != provider.labelExtension) {
        _labelExtController.text = provider.labelExtension;
      }
    }

    if (provider.ncSendError != null) {
      final err = provider.ncSendError!;
      provider.clearNcSendStatus();
      _showNcSendErrorDialog(context, err);
    } else if (provider.ncSendSuccess) {
      provider.clearNcSendStatus();
      _showSnack(context, 'マシンにデータを送信しました / Data sent to machine successfully!');
    }

    setState(() {});
  }

  void _showNcSendErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConfig.cardColor,
          shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
          title: Row(
            children: const [
              Icon(Icons.error_outline_rounded, color: AppConfig.ngColor, size: 24),
              SizedBox(width: 8),
              Text(
                'マシン送信失敗 / Send Failed',
                style: TextStyle(color: AppConfig.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            'マシンへのデータ送信に失敗しました。\n\n詳細: $error\n\n再度「マシンへ送信」を実行してください。',
            style: const TextStyle(color: AppConfig.textSecondary, fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: AppConfig.primaryAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
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

  Future<void> _resetMachineSetting() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConfig.cardColor,
        title: Text('設定の初期化 / Reset Setup', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('登録された工場・設備設定をクリアして、初期セットアップに戻りますか？', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('キャンセル / Cancel', style: GoogleFonts.outfit(color: AppConfig.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('初期化 / Reset', style: GoogleFonts.outfit(color: AppConfig.ngColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('kurachi_selected_factory');
      await prefs.remove('kurachi_selected_machine');
      
      if (mounted) {
        context.read<ReportProvider>().resetForm();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SetupScreen()),
        );
      }
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

  Future<void> _pickTime(BuildContext ctx, Future<void> Function(String) onSet) async {
    final TimeOfDay? picked = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.now(),
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
    );
    if (picked != null) {
      provider.setWorkDate(picked);
    }
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
        provider.setAppStage(AppStage.scan); // return to scan stage
      }
    } catch (e) {
      if (ctx.mounted) {
        _showSnack(ctx, e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final activeStage = provider.appStage;

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      endDrawer: provider.activeProduct.productNumber.isNotEmpty
          ? Drawer(
              width: 380,
              backgroundColor: AppConfig.backgroundColor,
              child: ProductDetailsSheet(product: provider.activeProduct),
            )
          : null,
      appBar: AppBar(
        titleSpacing: 16,
        automaticallyImplyLeading: false,
        backgroundColor: AppConfig.cardColor,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppConfig.borderSecondary)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppConfig.primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${provider.selectedFactory} · ${provider.selectedMachine}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppConfig.primaryAccent,
                ),
              ),
            ),
            if (provider.logQueue.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConfig.warningColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '未同期: ${provider.logQueue.length}',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppConfig.warningColor),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Sidebar Toggle Thumbnail
          if (provider.activeProduct.productNumber.isNotEmpty)
            Builder(
              builder: (context) {
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Scaffold.of(context).openEndDrawer();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppConfig.borderSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppConfig.primaryAccent, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: provider.activeProduct.imageUrl.isNotEmpty
                          ? Image.network(
                              provider.activeProduct.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.info_outline, size: 20, color: AppConfig.primaryAccent),
                            )
                          : const Icon(Icons.info_outline, size: 20, color: AppConfig.primaryAccent),
                    ),
                  ),
                );
              },
            ),
          // Settings Reset Popup
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings_rounded, color: AppConfig.textSecondary),
            onSelected: (val) {
              if (val == 'reset') {
                _resetMachineSetting();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    const Icon(Icons.refresh_rounded, color: AppConfig.ngColor, size: 20),
                    const SizedBox(width: 8),
                    Text('環境再設定 / Reset Machine', style: GoogleFonts.outfit(color: AppConfig.ngColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Workflow timeline tracker
            const WorkflowTimeline(),

            // Background sending activity indicator
            if (provider.isSendingToNC)
              Container(
                color: AppConfig.warningColor.withOpacity(0.08),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppConfig.warningColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '切断データをマシンへ送信中... / Sending details to machine in background...',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppConfig.warningColor),
                      ),
                    ),
                  ],
                ),
              ),

            // Active Stage Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: _buildStageBody(provider),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: activeStage == AppStage.submit ? _buildSubmitFloatingBar(context) : null,
    );
  }

  Widget _buildStageBody(ReportProvider provider) {
    switch (provider.appStage) {
      case AppStage.scan:
        return _buildScanStage(provider);
      case AppStage.production:
        return _buildProductionStage(provider);
      case AppStage.quality:
        return _buildQualityStage(provider);
      case AppStage.submit:
        return _buildSubmitStage(provider);
      default:
        return _buildScanStage(provider);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // STAGE 1: SCAN BODY
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildScanStage(ReportProvider p) {
    final isOzmanas = p.selectedMachine.toUpperCase() == 'OZMANAS';

    if (p.isSetupComplete) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppConfig.cardColor,
          borderRadius: AppConfig.cardRadius,
          border: Border.all(color: AppConfig.okColor.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConfig.okColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: AppConfig.okColor, size: 56),
            ),
            const SizedBox(height: 20),
            Text(
              '段取りスキャン検証完了\nSetup Validation Complete',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConfig.backgroundColor,
                borderRadius: AppConfig.borderRadius,
              ),
              child: Column(
                children: [
                  _infoRow('背番号 / Sebanggo', p.sebanggo),
                  const Divider(color: AppConfig.borderSecondary),
                  _infoRow('品番 / Part Number', p.activeProduct.productNumber),
                  const Divider(color: AppConfig.borderSecondary),
                  _infoRow('材料コード / Material Code', p.activeProduct.materialCode),
                  const Divider(color: AppConfig.borderSecondary),
                  _infoRow('ロット番号 / Lot Numbers', p.materialLots.join(', ')),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  p.resetSetupWorkflow();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppConfig.ngColor),
                  foregroundColor: AppConfig.ngColor,
                  shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text('段取りをやり直す / Reset & Rescan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Stepper Visuals
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConfig.cardColor,
            borderRadius: AppConfig.cardRadius,
            border: Border.all(color: AppConfig.borderSecondary),
          ),
          child: Row(
            children: [
              _buildStepIndicator(1, p.setupStep, '背番号\nKanban'),
              _buildStepLine(1, p.setupStep),
              _buildStepIndicator(2, p.setupStep, '材料ロット\nMaterial Lot'),
              _buildStepLine(2, p.setupStep),
              _buildStepIndicator(3, p.setupStep, isOzmanas ? '型番検証\nThomson' : 'マシン連動\nNC Send'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stepper Core Content Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppConfig.cardColor,
            borderRadius: AppConfig.cardRadius,
            border: Border.all(color: AppConfig.borderSecondary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (p.setupStep == 1) ...[
                Text(
                  '1. カンバンの背番号をスキャンしてください\nScan product kanban to begin setup validation.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 14, color: AppConfig.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isScanProcessing ? null : () => _startStep1Scan(p),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 22, color: Colors.white),
                  label: Text('背番号スキャン / Scan Kanban', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
              if (p.setupStep == 2) ...[
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppConfig.warningColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '材料照合 / Material Validation',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '背番号: ${p.sebanggo}',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.primaryAccent),
                ),
                const SizedBox(height: 6),
                Text(
                  '指定材料コード / Expected Material Code:\n${p.activeProduct.materialCode.replaceAll(',', ' or ')}',
                  style: GoogleFonts.outfit(fontSize: 14, color: AppConfig.textSecondary, height: 1.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _startStep2Scan(p),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 22, color: Colors.white),
                  label: Text('材料ラベルをスキャン / Scan Material', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
              if (p.setupStep == 3) ...[
                if (isOzmanas) ...[
                  Row(
                    children: [
                      const Icon(Icons.grid_view_rounded, color: AppConfig.primaryAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'トムソンボード検証 / Thomson Board validation',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '指定型番 / Expected Board Code:\n${p.activeProduct.kataban}',
                    style: GoogleFonts.outfit(fontSize: 14, color: AppConfig.textSecondary, height: 1.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _startStep3BoardScan(p),
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 22, color: Colors.white),
                    label: Text('型番QRをスキャン / Scan Thomson Board', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(Icons.sensors_rounded, color: AppConfig.okColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'マシン送信 / Send Details to Machine',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '背番号「${p.sebanggo}」の切断プログラムデータをマシンへ送信します。\n'
                    'Ready to dispatch program to machine.',
                    style: GoogleFonts.outfit(fontSize: 13, color: AppConfig.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: p.isSendingToNC ? null : () => _sendToNCCommand(p),
                    icon: p.isSendingToNC
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                    label: Text(
                      p.isSendingToNC ? '送信中... / Sending...' : 'マシンへ送信 / Send to Machine',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: AppConfig.okColor),
                  ),
                ],
              ],
            ],
          ),
        ),

        if (_scanError.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConfig.ngColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConfig.ngColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppConfig.ngColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _scanError,
                    style: GoogleFonts.outfit(color: AppConfig.ngColor, fontSize: 13, height: 1.4, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Reset option
        if (p.setupStep > 1) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                p.resetSetupWorkflow();
                setState(() => _scanError = '');
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppConfig.borderSecondary),
                shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
              ),
              child: Text(
                '中止・やり直す / Cancel & Reset',
                style: GoogleFonts.outfit(color: AppConfig.textSecondary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepIndicator(int step, int currentStep, String label) {
    final isDone = step < currentStep;
    final isActive = step == currentStep;
    
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isDone
                ? AppConfig.okColor
                : (isActive ? AppConfig.primaryAccent : AppConfig.borderSecondary),
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$step',
                    style: GoogleFonts.outfit(
                      color: isActive || isDone ? Colors.white : AppConfig.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppConfig.textPrimary : AppConfig.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterStep, int currentStep) {
    final isDone = afterStep < currentStep;
    return Container(
      width: 30,
      height: 2,
      margin: const EdgeInsets.only(bottom: 22),
      color: isDone ? AppConfig.okColor : AppConfig.borderSecondary,
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: AppConfig.textSecondary, fontSize: 13)),
          Text(value, style: GoogleFonts.outfit(color: AppConfig.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  void _startStep1Scan(ReportProvider p) {
    setState(() => _scanError = '');
    QrScannerDialog.show(
      context: context,
      title: '背番号スキャン / Scan Kanban (Step 1)',
      instruction: 'カンバンのバーコードをスキャンしてください\nScan Kanban QR/Barcode',
      onScanSuccess: (value) async {
        final code = value.trim().toUpperCase();
        if (!p.sebanggoList.contains(code)) {
          setState(() {
            _scanError = '❌ 背番号が存在しません / Sebanggo does not exist\nScanned: $code';
          });
          return;
        }
        p.setSebanggo(code);
        p.setSetupStep(2);
      },
    );
  }

  void _startStep2Scan(ReportProvider p) {
    setState(() => _scanError = '');
    final expectedMat = p.activeProduct.materialCode;
    
    QrScannerDialog.show(
      context: context,
      title: '材料ロットスキャン / Scan Material Lot (Step 2)',
      instruction: '材料ラベルのQRコードをスキャンしてください\nScan Material Lot QR',
      onScanSuccess: (value) async {
        final parts = value.split(',');
        if (parts.length < 2) {
          setState(() {
            _scanError = '❌ QR形式不正 / Invalid QR code format\nScanned: $value\nFormat expected: Code,Lot,Qty';
          });
          return;
        }

        final scannedMatCode = parts[0].trim();
        final lotNumber = parts[1].trim();

        // Exact match validation
        final validCodes = expectedMat.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty);
        if (!validCodes.contains(scannedMatCode)) {
          setState(() {
            _scanError = '❌ 材料コード不一致 / Material code mismatch\nExpected: $expectedMat\nScanned: $scannedMatCode';
          });
          return;
        }

        p.addMaterialLot(lotNumber);
        p.setSetupStep(3);
      },
    );
  }

  void _startStep3BoardScan(ReportProvider p) {
    setState(() => _scanError = '');
    final expectedKataban = p.activeProduct.kataban;

    QrScannerDialog.show(
      context: context,
      title: 'トムソンボードスキャン / Scan Board (Step 3)',
      instruction: 'トムソンボードの型番QRコードをスキャンしてください\nScan Board QR code',
      onScanSuccess: (value) async {
        final boardCode = value.trim();
        if (boardCode != expectedKataban) {
          setState(() {
            _scanError = '❌ 型番不一致 / 型番 mismatch\nExpected: $expectedKataban\nScanned: $boardCode';
          });
          return;
        }

        p.logTabletAction('Scanned トムソンボード (Step 3)', 'Completed', {
          'sebanggo': p.sebanggo,
          'boardCode': boardCode,
          'source': 'Step 3 Page'
        });
        
        p.setSetupStep(0);
        p.setAppStage(AppStage.production); // Auto advance
      },
    );
  }

  void _sendToNCCommand(ReportProvider p) {
    p.setSetupStep(0); // Set complete immediately
    p.setAppStage(AppStage.production); // Auto advance to allow typing other inputs in parallel
    p.sendToNC(); // Start in background
  }

  // ────────────────────────────────────────────────────────────────────────────
  // STAGE 2: PRODUCTION BODY
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildProductionStage(ReportProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Product Thumbnail & Sebanggo/Hinban Header Card
        _buildProductThumbnailHeader(p),
        const SizedBox(height: 16),

        // 1. Process Core Inputs
        _buildProductionHeaderCard(p),
        const SizedBox(height: 16),

        // 2. Large Touch-based defect counters
        Text(
          '不良カウンター (タップでカウントアップ) / Defect Counters (Tap to increment)',
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppConfig.textSecondary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TouchCounterCard(
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
              child: TouchCounterCard(
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
              child: TouchCounterCard(
                label: 'その他',
                subLabel: 'Other Defect',
                value: p.otherDefect,
                color: AppConfig.warningColor,
                onIncrement: () => p.incrementDcpCounter(20),
                onDecrement: () => p.decrementDcpCounter(20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 3. Optional Kensa inspections (only if single machine)
        if (!p.isGroupedMachine) ...[
          _buildKensaSectionWidget(p),
          const SizedBox(height: 16),
        ],

        // 4. Breaks
        _buildSectionTitleCard(
          title: '休憩時間 / Break Times',
          icon: Icons.coffee_rounded,
          child: const BreakTimeSection(),
        ),
        const SizedBox(height: 16),

        // 5. Maintenance
        _buildSectionTitleCard(
          title: 'トラブル・保全 / Maintenance',
          icon: Icons.build_rounded,
          child: _buildMaintenanceWidget(p),
        ),
      ],
    );
  }

  Widget _buildProductionHeaderCard(ReportProvider p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: AppConfig.cardRadius,
        border: Border.all(color: AppConfig.borderSecondary),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildWorkerSelectBox(context, p, false)),
              const SizedBox(width: 12),
              Expanded(child: _buildDateSelectBox(context, p)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeSelectBox(
                  context,
                  label: '加工開始 / Start',
                  value: p.startTime,
                  onTap: () => _pickTime(context, (t) async => p.setStartTime(t)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeSelectBox(
                  context,
                  label: '加工終了 / End',
                  value: p.endTime,
                  onTap: () => _pickTime(context, (t) async => p.setEndTime(t)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNumberInputBox(
                  label: '加工数 / Process Qty',
                  controller: _processQtyController,
                  focusNode: _processQtyFocus,
                  onChanged: (v) => p.setProcessQuantity(int.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              if (p.isGroupedMachine)
                Expanded(child: _buildGroupedMachineShots(p))
              else
                Expanded(
                  child: _buildNumberInputBox(
                    label: 'ショット数 / Shots',
                    controller: _shotController,
                    focusNode: _shotFocus,
                    onChanged: (v) => p.setShotCount(int.tryParse(v) ?? 0),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNumberInputBox(
            label: 'ラベル拡張 / Label Ext.',
            controller: _labelExtController,
            focusNode: _labelExtFocus,
            isNumeric: false,
            onChanged: (v) => p.setLabelExtension(v),
          ),
          const SizedBox(height: 16),
          // Material Scanning Card
          _buildMaterialScanSection(p),
          const SizedBox(height: 16),
          // Print Label Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: p.isLoading
                  ? null
                  : () async {
                      try {
                        await p.triggerPrint(context);
                        if (mounted) {
                          _showSnack(context, '印刷指示を送信しました / Print instruction sent');
                        }
                      } catch (e) {
                        if (mounted) {
                          _showSnack(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: p.isLoading ? AppConfig.borderSecondary : AppConfig.okColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: p.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppConfig.textMuted,
                      ),
                    )
                  : const Icon(Icons.print_rounded, size: 20),
              label: Text(
                p.isLoading ? '印刷中... / Printing...' : '現品票ラベル印刷 / Print Label',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: p.isLoading ? AppConfig.textMuted : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerSelectBox(BuildContext ctx, ReportProvider p, bool isKensa) {
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
      child: _boxDecorationContainer(
        label: isKensa ? '検査者 / Inspector' : '作業者 / Worker',
        value: name.isEmpty ? 'タップして選択' : name,
        icon: Icons.person_search_rounded,
        placeholder: name.isEmpty,
      ),
    );
  }

  Widget _buildDateSelectBox(BuildContext ctx, ReportProvider p) {
    final dateStr = '${p.workDate.year}/${p.workDate.month.toString().padLeft(2, '0')}/${p.workDate.day.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () => _pickDate(ctx),
      child: _boxDecorationContainer(
        label: '日付 / Date',
        value: dateStr,
        icon: Icons.calendar_month_rounded,
      ),
    );
  }

  Widget _buildTimeSelectBox(BuildContext ctx, {required String label, required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: _boxDecorationContainer(
        label: label,
        value: value.isEmpty ? '--:--' : value,
        icon: Icons.access_time_rounded,
        placeholder: value.isEmpty,
      ),
    );
  }

  Widget _buildNumberInputBox({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required Function(String) onChanged,
    bool isNumeric = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppConfig.backgroundColor,
        borderRadius: AppConfig.borderRadius,
        border: Border.all(color: AppConfig.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 10, color: AppConfig.textMuted)),
          const SizedBox(height: 2),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null,
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedMachineShots(ReportProvider p) {
    final machines = p.selectedMachine.split(',');
    return Column(
      children: machines.map((m) {
        final mName = m.trim();
        if (mName.isEmpty) return const SizedBox.shrink();
        final val = p.groupedShots[mName] ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppConfig.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppConfig.borderSecondary),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(mName, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppConfig.textPrimary)),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: val > 0 ? val.toString() : '',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Shots',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (v) {
                    p.setGroupedShot(mName, int.tryParse(v) ?? 0);
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _boxDecorationContainer({required String label, required String value, required IconData icon, bool placeholder = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppConfig.backgroundColor,
        borderRadius: AppConfig.borderRadius,
        border: Border.all(color: AppConfig.borderSecondary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.outfit(fontSize: 10, color: AppConfig.textMuted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: placeholder ? AppConfig.textMuted : AppConfig.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(icon, size: 16, color: AppConfig.textMuted),
        ],
      ),
    );
  }

  Widget _buildKensaSectionWidget(ReportProvider p) {
    return _buildSectionTitleCard(
      title: '検査記録 / Inspection (Kensa)',
      icon: Icons.verified_rounded,
      trailing: Switch(
        value: p.isKensaEnabled,
        onChanged: p.toggleKensaMode,
        activeThumbColor: AppConfig.primaryAccent,
      ),
      child: p.isKensaEnabled
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildWorkerSelectBox(context, p, true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDateSelectBox(context, p)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeSelectBox(
                        context,
                        label: '検査開始 / Start',
                        value: p.kensaStartTime,
                        onTap: () => _pickTime(context, (t) async => p.setKensaStartTime(t)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeSelectBox(
                        context,
                        label: '検査終了 / End',
                        value: p.kensaEndTime,
                        onTap: () => _pickTime(context, (t) async => p.setKensaEndTime(t)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '検査カウンター (タップでカウントアップ) / Inspection Counters (Tap to increment)',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppConfig.textSecondary),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: 12,
                  itemBuilder: (_, i) => CompactTouchCounterCard(
                    label: 'C${i + 1}',
                    subLabel: 'Counter ${i + 1}',
                    value: p.kensaCounters[i],
                    color: AppConfig.ngColor,
                    onIncrement: () => p.incrementKensaCounter(i),
                    onDecrement: () => p.decrementKensaCounter(i),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildMaintenanceWidget(ReportProvider p) {
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
              border: Border.all(color: AppConfig.warningColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppConfig.warningColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${rec.startTime} → ${rec.endTime} (${rec.durationMinutes}min)',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
                      ),
                      if (rec.comment.isNotEmpty)
                        Text(rec.comment, style: GoogleFonts.outfit(fontSize: 12, color: AppConfig.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppConfig.ngColor, size: 20),
                  onPressed: () => p.deleteMaintenanceRecord(i),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const MaintenanceDialog(),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppConfig.warningColor),
              foregroundColor: AppConfig.warningColor,
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text('トラブル保全を追加 / Add Trouble Log', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitleCard({required String title, required IconData icon, required Widget child, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: AppConfig.cardRadius,
        border: Border.all(color: AppConfig.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppConfig.primaryAccent),
                  const SizedBox(width: 8),
                  Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.textPrimary)),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // STAGE 3: QUALITY BODY
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildQualityStage(ReportProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'サイクル品質確認 / Cycle Quality Verification',
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppConfig.textSecondary),
        ),
        const SizedBox(height: 12),
        _buildVisualCheckCard(
          context: context,
          title: '初物チェック / Hatsumono Check',
          subTitle: '稼働直後の初ロット製品の写真を撮影し、適合性を確認してください。',
          photoPath: p.hatsumonoPhotoPath,
          checked: p.hatsumonoChecked,
          onTap: () => _capturePhoto(context, true),
        ),
        const SizedBox(height: 14),
        _buildVisualCheckCard(
          context: context,
          title: '後物チェック / Atomono Check',
          subTitle: '稼働終了直前の製品の写真を撮影し、品質に異常がないことを確認してください。',
          photoPath: p.atomonoPhotoPath,
          checked: p.atomonoChecked,
          onTap: () => _capturePhoto(context, false),
        ),
        const SizedBox(height: 20),
        _buildMaterialLabelSection(p),
      ],
    );
  }

  Widget _buildVisualCheckCard({
    required BuildContext context,
    required String title,
    required String subTitle,
    required String photoPath,
    required bool checked,
    required VoidCallback onTap,
  }) {
    final hasPic = photoPath.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: AppConfig.cardRadius,
        border: Border.all(
          color: checked ? AppConfig.okColor : AppConfig.borderSecondary,
          width: checked ? 2.0 : 1.0,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppConfig.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConfig.borderSecondary),
              ),
              child: hasPic
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(photoPath),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.add_a_photo_rounded,
                      color: AppConfig.textMuted,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConfig.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppConfig.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: checked ? AppConfig.okColor.withOpacity(0.12) : AppConfig.ngColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: checked ? AppConfig.okColor : AppConfig.ngColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        checked ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: checked ? AppConfig.okColor : AppConfig.ngColor,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        checked ? '検証完了 / OK' : '検証未完了 / Pending',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: checked ? AppConfig.okColor : AppConfig.ngColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialLabelSection(ReportProvider p) {
    final int requiredPhotos = p.materialLots.length;
    final int currentPhotos = p.materialLabelPhotos.length;
    final bool isCorrect = currentPhotos >= requiredPhotos;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: AppConfig.cardRadius,
        border: Border.all(color: isCorrect ? AppConfig.okColor : AppConfig.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.label_rounded, size: 18, color: AppConfig.primaryAccent),
              const SizedBox(width: 8),
              Text(
                '材料ラベル写真撮影 / Material Label Photos',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'スキャンされたロット数: $requiredPhotos に対して、$currentPhotos 枚の写真が撮影されています。',
            style: GoogleFonts.outfit(fontSize: 12, color: AppConfig.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (p.materialLabelPhotos.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: p.materialLabelPhotos.length,
              itemBuilder: (context, i) => Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(p.materialLabelPhotos[i]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => p.removeMaterialLabelPhoto(i),
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _captureMaterialLabelPhoto(context),
              icon: const Icon(Icons.add_a_photo_rounded),
              label: Text('写真を撮影する / Capture Label', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // STAGE 4: SUBMIT BODY
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildSubmitStage(ReportProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Real-time recalculation card
        _buildRecalculationSummaryCard(p),
        const SizedBox(height: 16),

        // Read-only specs
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConfig.cardColor,
            borderRadius: AppConfig.cardRadius,
            border: Border.all(color: AppConfig.borderSecondary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '製品情報 (編集不可) / Product Info (Read-Only)',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppConfig.textMuted),
              ),
              const SizedBox(height: 12),
              _reviewInfoRow('背番号 / Sebanggo', p.sebanggo, isBold: true),
              const Divider(color: AppConfig.borderSecondary),
              _reviewInfoRow('品番 / Part Number', p.activeProduct.productNumber),
              const Divider(color: AppConfig.borderSecondary),
              _reviewInfoRow('車型 / Model', p.activeProduct.model),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Editable components summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConfig.cardColor,
            borderRadius: AppConfig.cardRadius,
            border: Border.all(color: AppConfig.borderSecondary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '記録情報の編集確認 / Review & Edit Quantities',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppConfig.textSecondary),
              ),
              const SizedBox(height: 16),
              // Worker name
              _buildReviewFieldContainer(
                label: '作業者名 / Worker Name',
                child: _buildWorkerSelectBox(context, p, false),
              ),
              const Divider(height: 24, color: AppConfig.borderSecondary),
              // Process Qty
              _buildReviewFieldContainer(
                label: '加工総数 / Total Qty',
                child: _buildNumberInputBox(
                  label: '数量',
                  controller: _processQtyController,
                  focusNode: _processQtyFocus,
                  onChanged: (v) => p.setProcessQuantity(int.tryParse(v) ?? 0),
                ),
              ),
              const Divider(height: 24, color: AppConfig.borderSecondary),
              // Shot count
              _buildReviewFieldContainer(
                label: '総ショット数 / Total Shots',
                child: p.isGroupedMachine
                    ? _buildGroupedMachineShots(p)
                    : _buildNumberInputBox(
                        label: 'ショット数',
                        controller: _shotController,
                        focusNode: _shotFocus,
                        onChanged: (v) => p.setShotCount(int.tryParse(v) ?? 0),
                      ),
              ),
              const Divider(height: 24, color: AppConfig.borderSecondary),
              // Defect counts
              _buildReviewFieldContainer(
                label: '不良品内訳 / Defect Breakdown',
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInlineCounter('疵引不良', p.defectPull, (val) {
                        final diff = val - p.defectPull;
                        if (diff > 0) p.incrementDcpCounter(18);
                        if (diff < 0) p.decrementDcpCounter(18);
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInlineCounter('加工不良', p.processingDefect, (val) {
                        final diff = val - p.processingDefect;
                        if (diff > 0) p.incrementDcpCounter(19);
                        if (diff < 0) p.decrementDcpCounter(19);
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInlineCounter('その他', p.otherDefect, (val) {
                        final diff = val - p.otherDefect;
                        if (diff > 0) p.incrementDcpCounter(20);
                        if (diff < 0) p.decrementDcpCounter(20);
                      }),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24, color: AppConfig.borderSecondary),
              // Comments
              _buildReviewFieldContainer(
                label: 'DCP コメント / DCP Comments',
                child: TextField(
                  controller: _dcpCommentController,
                  focusNode: _dcpCommentFocus,
                  maxLines: 2,
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'コメントを入力してください...',
                    contentPadding: EdgeInsets.all(12),
                  ),
                  onChanged: p.setCommentsDcp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecalculationSummaryCard(ReportProvider p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppConfig.cardRadius,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'リアルタイム集計 / Real-time Recalculations',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppConfig.textMuted),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppConfig.primaryAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: Text('LIVE', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: AppConfig.primaryAccent)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryCell('加工総数\nQty', p.processQuantity.toString(), Colors.white),
              _buildSummaryDivider(),
              _buildSummaryCell('NG合計\nNG Total', p.totalNG.toString(), p.totalNG > 0 ? AppConfig.ngColor : Colors.white),
              _buildSummaryDivider(),
              _buildSummaryCell('良品合計\nGood Qty', p.finalGoodQuantity.toString(), AppConfig.okColor),
              _buildSummaryDivider(),
              _buildSummaryCell('正味時間\nWork Hours', '${p.totalWorkHours.toStringAsFixed(1)}h', AppConfig.primaryAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCell(String label, String val, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            val,
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 9, color: AppConfig.textMuted, height: 1.2),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider() => Container(width: 1, height: 28, color: AppConfig.borderSecondary, margin: const EdgeInsets.symmetric(horizontal: 8));

  Widget _reviewInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 13, color: AppConfig.textSecondary)),
          Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: AppConfig.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildReviewFieldContainer({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppConfig.textSecondary)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildInlineCounter(String label, int val, Function(int) onUpdate) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: AppConfig.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppConfig.borderSecondary),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AppConfig.textSecondary)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: val > 0 ? () => onUpdate(val - 1) : null,
                child: const Icon(Icons.remove_circle_outline_rounded, size: 16, color: AppConfig.textMuted),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('$val', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              GestureDetector(
                onTap: () => onUpdate(val + 1),
                child: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppConfig.primaryAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitFloatingBar(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: provider.isSubmitting ? null : AppConfig.primaryGradient,
          color: provider.isSubmitting ? AppConfig.cardColor : null,
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
            onTap: provider.isSubmitting ? null : () => _submitForm(context),
            child: Center(
              child: provider.isSubmitting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '提出データを送信中... / Submitting...',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.textSecondary),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          '記録を提出 / Submit Daily Report',
                          style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductThumbnailHeader(ReportProvider p) {
    final product = p.activeProduct;
    final hasImg = product.imageUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: AppConfig.cardRadius,
        border: Border.all(color: AppConfig.borderSecondary),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: hasImg ? () => _showProductImagePreview(context, product.imageUrl) : null,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppConfig.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConfig.borderSecondary, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: hasImg
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_rounded, color: AppConfig.textMuted, size: 28),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image_not_supported_rounded, color: AppConfig.textMuted, size: 28),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.sebanggo.isNotEmpty ? product.sebanggo : '背番号なし / No Sebanggo',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppConfig.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '品番: ${product.productNumber.isNotEmpty ? product.productNumber : '未スキャン / Not Scanned'}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppConfig.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialScanSection(ReportProvider p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConfig.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppConfig.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '材料ロット / Material Lot',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppConfig.textSecondary),
              ),
              SizedBox(
                height: 28,
                child: OutlinedButton.icon(
                  onPressed: () => _scanMaterialInProduction(p),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: const BorderSide(color: AppConfig.primaryAccent),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 14),
                  label: Text('スキャン / Scan', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          if (p.materialLots.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: p.materialLots.map((lot) {
                return Chip(
                  backgroundColor: AppConfig.cardColor,
                  side: const BorderSide(color: AppConfig.borderSecondary),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(
                    lot,
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
                  ),
                  onDeleted: () {
                    p.removeMaterialLot(lot);
                    _showSnack(context, 'ロット $lot を削除しました / Removed Lot: $lot');
                  },
                  deleteIcon: const Icon(Icons.cancel_rounded, size: 14, color: AppConfig.textMuted),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _scanMaterialInProduction(ReportProvider p) {
    setState(() => _scanError = '');
    final expectedMat = p.activeProduct.materialCode;

    QrScannerDialog.show(
      context: context,
      title: '材料追加スキャン / Scan Material Lot',
      instruction: '材料の現品票QRコードをスキャンしてください\nScan Material QR code',
      onScanSuccess: (value) async {
        final parts = value.split(',');
        if (parts.length < 2) {
          _showSnack(context, '❌ 無効なQRコード / Invalid QR code', isError: true);
          return;
        }
        final scannedMatCode = parts[0].trim();
        final lotNumber = parts[1].trim();

        final validCodes = expectedMat.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty);
        if (!validCodes.contains(scannedMatCode)) {
          _showSnack(context, '❌ 材料コード不一致 / Material code mismatch\nExpected: $expectedMat\nScanned: $scannedMatCode', isError: true);
          return;
        }

        if (p.materialLots.contains(lotNumber)) {
          _showSnack(context, '⚠️ 既にスキャン済みのロットです / Lot already scanned: $lotNumber', isError: true);
          return;
        }

        await Future.delayed(const Duration(milliseconds: 300));

        if (context.mounted) {
          _showSnack(context, '材料スキャン成功。ラベル写真を撮影してください。/ Scan OK. Please capture the label photo.');
        }
        
        try {
          final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
          if (image != null) {
            p.addMaterialLotWithPhoto(lotNumber, image.path);
            if (context.mounted) {
              _showSnack(context, '材料ロットと写真を登録しました / Registered Lot: $lotNumber');
            }
          } else {
            if (context.mounted) {
              _showSnack(context, '❌ 写真撮影がキャンセルされたため、登録されませんでした / Cancelled: Lot $lotNumber not registered', isError: true);
            }
          }
        } catch (e) {
          if (context.mounted) {
            _showSnack(context, 'カメラ起動エラー / Camera Error: $e', isError: true);
          }
        }
      },
    );
  }

  void _showProductImagePreview(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.white, size: 64),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// CUSTOM COMPONENT WIDGETS
// ────────────────────────────────────────────────────────────────────────────
class WorkflowTimeline extends StatelessWidget {
  const WorkflowTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final currentStage = provider.appStage;
    final isScanComplete = provider.isSetupComplete;

    final List<Map<String, dynamic>> stages = [
      {'stage': AppStage.scan, 'label': '段取り検証\nScan', 'icon': Icons.qr_code_scanner_rounded},
      {'stage': AppStage.production, 'label': '加工記録\nProduction', 'icon': Icons.precision_manufacturing_rounded},
      {'stage': AppStage.quality, 'label': '品質確認\nQuality', 'icon': Icons.camera_alt_rounded},
      {'stage': AppStage.submit, 'label': '記録提出\nSubmit', 'icon': Icons.send_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        color: AppConfig.cardColor,
        border: Border(bottom: BorderSide(color: AppConfig.borderSecondary)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(stages.length, (index) {
          final s = stages[index];
          final stage = s['stage'] as AppStage;
          final label = s['label'] as String;
          final icon = s['icon'] as IconData;
          final isActive = currentStage == stage;
          
          bool isCompleted = false;
          if (stage == AppStage.scan) {
            isCompleted = isScanComplete;
          } else if (stage == AppStage.production) {
            isCompleted = isScanComplete && currentStage.index > stage.index;
          } else if (stage == AppStage.quality) {
            isCompleted = isScanComplete && currentStage.index > stage.index;
          }

          final canTap = isScanComplete || stage == AppStage.scan;

          return Expanded(
            child: GestureDetector(
              onTap: canTap
                  ? () {
                      HapticFeedback.lightImpact();
                      provider.setAppStage(stage);
                    }
                  : null,
              child: Opacity(
                opacity: canTap ? 1.0 : 0.35,
                child: Column(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle_rounded : icon,
                      color: isCompleted
                          ? AppConfig.okColor
                          : (isActive ? AppConfig.primaryAccent : AppConfig.textMuted),
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                        color: isActive ? AppConfig.primaryAccent : AppConfig.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class TouchCounterCard extends StatelessWidget {
  final String label;
  final String subLabel;
  final int value;
  final Color color;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const TouchCounterCard({
    super.key,
    required this.label,
    required this.subLabel,
    required this.value,
    required this.color,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onIncrement();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: AppConfig.cardColor,
          borderRadius: AppConfig.cardRadius,
          border: Border.all(
            color: value > 0 ? color : AppConfig.borderSecondary,
            width: value > 0 ? 2 : 1,
          ),
          boxShadow: value > 0
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
            ),
            Text(
              subLabel,
              style: GoogleFonts.outfit(fontSize: 10, color: AppConfig.textMuted),
            ),
            const SizedBox(height: 14),
            Text(
              '$value',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: value > 0 ? color : AppConfig.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onDecrement();
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppConfig.borderSecondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.remove_rounded, color: AppConfig.textSecondary, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompactTouchCounterCard extends StatelessWidget {
  final String label;
  final String subLabel;
  final int value;
  final Color color;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const CompactTouchCounterCard({
    super.key,
    required this.label,
    required this.subLabel,
    required this.value,
    required this.color,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onIncrement();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppConfig.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value > 0 ? color : AppConfig.borderSecondary,
            width: value > 0 ? 1.5 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
                ),
                Text(
                  subLabel,
                  style: GoogleFonts.outfit(fontSize: 8, color: AppConfig.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  '$value',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: value > 0 ? color : AppConfig.textPrimary,
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onDecrement();
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppConfig.borderSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove_rounded, color: AppConfig.textSecondary, size: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
