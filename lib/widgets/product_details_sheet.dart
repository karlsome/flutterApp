import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../models/product_model.dart';
import '../providers/report_provider.dart';
import 'package:provider/provider.dart';

class ProductDetailsSheet extends StatelessWidget {
  final Product product;

  const ProductDetailsSheet({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    return SafeArea(
      child: Container(
        color: AppConfig.backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_outline_rounded,
                      color: AppConfig.primaryAccent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '製品詳細 / Product Specs',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppConfig.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppConfig.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Product image section
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: product.imageUrl.isNotEmpty ? () => _showImagePreview(context, product.imageUrl) : null,
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppConfig.cardColor,
                      borderRadius: AppConfig.borderRadius,
                      border: Border.all(color: AppConfig.borderSecondary, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: AppConfig.borderRadius,
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_rounded, color: AppConfig.textMuted, size: 40),
                                    SizedBox(height: 8),
                                    Text('画像読み込み失敗 / Load Failed', style: TextStyle(color: AppConfig.textMuted, fontSize: 12)),
                                  ],
                                ),
                              ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported_rounded, color: AppConfig.textMuted, size: 40),
                                  SizedBox(height: 8),
                                  Text('製品画像なし / No Image Available', style: TextStyle(color: AppConfig.textMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          // Specs list
          Flexible(
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: AppConfig.cardColor,
                  borderRadius: AppConfig.cardRadius,
                  border: Border.all(color: AppConfig.borderSecondary),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('背番号 / Sebanggo', product.sebanggo, highlight: true),
                    _divider(),
                    _row('品番 / Part Number', product.productNumber),
                    _divider(),
                    _row('モデル / Model', product.model),
                    _divider(),
                    _row('形状 / Shape', product.shape),
                    _divider(),
                    _row('R/L', product.rl),
                    _divider(),
                    _row('材料 / Material', product.material),
                    _divider(),
                    _row('材料背番号 / Mat. Code', product.materialCode),
                    _divider(),
                    _row('色 / Color', product.materialColor),
                    _divider(),
                    _row('型番 / Kataban', product.kataban),
                    _divider(),
                    _row('収容数 / Capacity', product.capacity.toString()),
                    _divider(),
                    _row('送りピッチ / Feed Pitch', product.feedPitch),
                    _divider(),
                    _row('離型紙 / Release Paper', product.releasePaper),
                    _divider(),
                    _row('SRS', product.srs),
                    _divider(),
                    _row('合計休憩 / Break Total', '${provider.totalBreakMinutes} 分'),
                    _divider(),
                    _row('保全時間 / Maintenance', '${provider.totalTroubleMinutes} 分'),
                    _divider(),
                    _row('稼働時間 / Work Hours',
                        '${provider.totalWorkHours.toStringAsFixed(2)} h'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Close button
          SizedBox(
            width: double.infinity,
            height: AppConfig.buttonHeight,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppConfig.borderSecondary, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: AppConfig.borderRadius),
              ),
              child: Text(
                '閉じる / Close',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppConfig.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppConfig.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(
                fontSize: highlight ? 16 : 14,
                color: highlight ? AppConfig.primaryAccent : AppConfig.textPrimary,
                fontWeight:
                    highlight ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
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

  Widget _divider() =>
      const Divider(color: AppConfig.borderSecondary, height: 1);
}
