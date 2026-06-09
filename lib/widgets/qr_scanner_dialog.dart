import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../config/app_config.dart';

class QrScannerDialog extends StatefulWidget {
  final String title;
  final String instruction;
  final Function(String) onScanSuccess;

  const QrScannerDialog({
    super.key,
    required this.title,
    required this.instruction,
    required this.onScanSuccess,
  });

  static void show({
    required BuildContext context,
    required String title,
    required String instruction,
    required Function(String) onScanSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QrScannerDialog(
        title: title,
        instruction: instruction,
        onScanSuccess: onScanSuccess,
      ),
    );
  }

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  late final MobileScannerController _controller;
  bool _hasScanned = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: AppConfig.backgroundColor,
          borderRadius: AppConfig.cardRadius,
          border: Border.all(color: AppConfig.borderSecondary, width: 2),
        ),
        width: 500,
        height: 560,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppConfig.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_scanner_rounded,
                      color: AppConfig.primaryAccent, size: 26),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: AppConfig.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Torch toggle
                  IconButton(
                    onPressed: _toggleTorch,
                    icon: Icon(
                      _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _torchOn
                          ? AppConfig.warningColor
                          : AppConfig.textSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // Scanner viewfinder
            Expanded(
              child: Stack(
                children: [
                  ClipRect(
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: (BarcodeCapture capture) {
                        if (_hasScanned) return;
                        final barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final qrCode = barcodes.first.rawValue;
                          if (qrCode != null && qrCode.isNotEmpty) {
                            setState(() => _hasScanned = true);
                            _controller.stop().then((_) {
                              widget.onScanSuccess(qrCode);
                              if (mounted) Navigator.pop(context);
                            });
                          }
                        }
                      },
                    ),
                  ),
                  // Finder overlay
                  Center(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppConfig.primaryAccent, width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  // Instruction bar
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      width: double.infinity,
                      child: Text(
                        widget.instruction,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppConfig.onAccent, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Cancel button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _controller.stop().then((_) {
                      if (mounted) Navigator.pop(context);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.ngColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppConfig.borderRadius),
                  ),
                  child: Text(
                    'キャンセル / Cancel',
                    style: TextStyle(
                        color: AppConfig.onAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
