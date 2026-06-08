import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/report_provider.dart';
import '../widgets/qr_scanner_dialog.dart';

class SetupWizardDialog extends StatefulWidget {
  const SetupWizardDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SetupWizardDialog(),
    );
  }

  @override
  State<SetupWizardDialog> createState() => _SetupWizardDialogState();
}

class _SetupWizardDialogState extends State<SetupWizardDialog> {
  String _errorMessage = '';
  bool _isProcessing = false;

  void _showError(String msg) {
    setState(() {
      _errorMessage = msg;
    });
  }

  void _clearError() {
    setState(() {
      _errorMessage = '';
    });
  }

  // Helper to validate Material Code (case-sensitive exact match with split list)
  bool _validateMaterialCode(String scanned, String expectedString) {
    if (expectedString.isEmpty) return false;
    final validCodes = expectedString.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty);
    return validCodes.contains(scanned.trim());
  }

  // Step 1: Scan Kanban
  void _startStep1Scan(ReportProvider p) {
    _clearError();
    final ctx = context;
    QrScannerDialog.show(
      context: ctx,
      title: '背番号スキャン / Scan Kanban (Step 1)',
      instruction: 'カンバンのバーコードをスキャンしてください\nScan Kanban QR/Barcode',
      onScanSuccess: (value) async {
        final code = value.trim().toUpperCase();
        if (!p.sebanggoList.contains(code)) {
          _showError('❌ 背番号が存在しません / Sebanggo does not exist\nScanned: $code');
          return;
        }

        if (mounted) {
          setState(() => _isProcessing = true);
        }
        try {
          p.setSebanggo(code);
          p.setSetupStep(2);
        } catch (e) {
          _showError('Error: $e');
        } finally {
          if (mounted) {
            setState(() => _isProcessing = false);
          }
        }
      },
    );
  }

  // Step 2: Scan Material Lot
  void _startStep2Scan(ReportProvider p) {
    _clearError();
    final expectedMat = p.activeProduct.materialCode;
    final ctx = context;
    
    QrScannerDialog.show(
      context: ctx,
      title: '材料ロットスキャン / Scan Material Lot (Step 2)',
      instruction: '材料ラベルのQRコードをスキャンしてください\nScan Material Lot QR',
      onScanSuccess: (value) async {
        final parts = value.split(',');
        if (parts.length < 2) {
          _showError('❌ QR形式不正 / Invalid QR code format\nScanned: $value\nFormat expected: Code,Lot,Qty');
          return;
        }

        final scannedMatCode = parts[0].trim();
        final lotNumber = parts[1].trim();

        if (!_validateMaterialCode(scannedMatCode, expectedMat)) {
          _showError('❌ 材料コード不一致 / Material code mismatch\nExpected: $expectedMat\nScanned: $scannedMatCode');
          return;
        }

        p.addMaterialLot(lotNumber);
        p.setSetupStep(3);
      },
    );
  }

  // Step 3: Scan Thomson Board (OZMANAS only)
  void _startStep3BoardScan(ReportProvider p) {
    _clearError();
    final expectedKataban = p.activeProduct.kataban;
    final ctx = context;

    QrScannerDialog.show(
      context: ctx,
      title: 'トムソンボードスキャン / Scan Board (Step 3)',
      instruction: 'トムソンボードの型番QRコードをスキャンしてください\nScan Board QR code',
      onScanSuccess: (value) async {
        final boardCode = value.trim();
        if (boardCode != expectedKataban) {
          _showError('❌ 型番不一致 / 型番 mismatch\nExpected: $expectedKataban\nScanned: $boardCode');
          return;
        }

        // Success! Log completed action, update setup step to 0 (complete)
        p.logTabletAction('Scanned トムソンボード (Step 3)', 'Completed', {
          'sebanggo': p.sebanggo,
          'boardCode': boardCode,
          'source': 'Step 3 Modal (Flutter)'
        });
        
        p.setSetupStep(0);
        if (ctx.mounted) {
          Navigator.of(ctx).pop(); // Dismiss Wizard
        }
      },
    );
  }

  // Step 3: Dispatch command to NC Machine
  void _sendToNCCommand(ReportProvider p) {
    if (mounted) {
      Navigator.of(context).pop(); // Dismiss Wizard immediately
    }
    p.sendToNC(); // Run sending asynchronously in the background
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<ReportProvider>(context);
    final isOzmanas = p.selectedMachine.toUpperCase() == 'OZMANAS';
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        decoration: BoxDecoration(
          color: AppConfig.backgroundColor,
          borderRadius: AppConfig.cardRadius,
          border: Border.all(color: AppConfig.borderSecondary, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Title
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: const BoxDecoration(
                color: AppConfig.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: AppConfig.primaryAccent, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '段取りスキャン認証 / Setup Validation Wizard',
                      style: TextStyle(
                        color: AppConfig.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConfig.warningColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'STEP ${p.setupStep} / 3',
                      style: const TextStyle(
                        color: AppConfig.warningColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),

            // Stepper Indicator Visuals
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
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

            // Step Content Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConfig.cardColor,
                  borderRadius: AppConfig.borderRadius,
                  border: Border.all(color: AppConfig.borderSecondary),
                ),
                child: Column(
                  children: [
                    if (p.setupStep == 1) _buildStep1Content(context, p),
                    if (p.setupStep == 2) _buildStep2Content(context, p),
                    if (p.setupStep == 3) _buildStep3Content(context, p, isOzmanas),
                  ],
                ),
              ),
            ),

            // Error Display (if any)
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConfig.ngColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppConfig.ngColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppConfig.ngColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: AppConfig.ngColor,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom Actions / Cancel Reset buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        p.resetSetupWorkflow();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppConfig.borderSecondary),
                        shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
                      ),
                      child: const Text(
                        '中止・初期化 / Cancel & Reset',
                        style: TextStyle(color: AppConfig.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                    style: TextStyle(
                      color: isActive || isDone ? Colors.white : AppConfig.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
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

  // STEP 1 UI: Kanban Verification
  Widget _buildStep1Content(BuildContext context, ReportProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '1. カンバンの背番号をスキャンしてください\nScan product kanban to begin setup validation.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppConfig.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : () => _startStep1Scan(p),
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 22, color: Colors.white),
          label: const Text('背番号スキャン / Scan Kanban', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConfig.primaryAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
          ),
        ),

      ],
    );
  }

  // STEP 2 UI: Material QR Verification
  Widget _buildStep2Content(BuildContext context, ReportProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppConfig.warningColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              '材料照合 / Material Validation',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '背番号: ${p.sebanggo}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.primaryAccent),
        ),
        const SizedBox(height: 6),
        Text(
          '指定材料コード / Expected Material Code:\n${p.activeProduct.materialCode.replaceAll(',', ' or ')}',
          style: const TextStyle(fontSize: 14, color: AppConfig.textSecondary, height: 1.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => _startStep2Scan(p),
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 22, color: Colors.white),
          label: const Text('材料ラベルをスキャン / Scan Material', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConfig.primaryAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
          ),
        ),
      ],
    );
  }

  // STEP 3 UI: Machine Dispatch or Board Verification
  Widget _buildStep3Content(BuildContext context, ReportProvider p, bool isOzmanas) {
    if (isOzmanas) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, color: AppConfig.primaryAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'トムソンボード検証 / Thomson Board verification',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '指定型番 / Expected Board Code:\n${p.activeProduct.kataban}',
            style: const TextStyle(fontSize: 14, color: AppConfig.textSecondary, height: 1.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _startStep3BoardScan(p),
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 22, color: Colors.white),
            label: const Text('型番QRをスキャン / Scan Thomson Board', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.primaryAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
            ),
          ),
        ],
      );
    }

    // Default: Dispatch cutting details to NC
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.sensors_rounded, color: AppConfig.okColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'マシン送信 / Send Details to Machine',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '背番号「${p.sebanggo}」の切断プログラムデータをマシンへ送信します。\n'
          'Ready to dispatch program to machine ${p.selectedMachine}.',
          style: const TextStyle(fontSize: 13, color: AppConfig.textSecondary, height: 1.5),
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
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConfig.okColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
          ),
        ),
      ],
    );
  }
}
