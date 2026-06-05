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
    return Container(
      decoration: const BoxDecoration(
        color: AppConfig.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: AppConfig.borderSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                    fontSize: 20,
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
          // Product image
          if (product.imageUrl.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: AppConfig.borderRadius,
                    border: Border.all(color: AppConfig.borderSecondary, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: AppConfig.borderRadius,
                    child: Image.network(
                      product.imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 80,
                        color: AppConfig.cardColor,
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded,
                              color: AppConfig.textMuted, size: 36),
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
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.borderSecondary,
                shape: RoundedRectangleBorder(
                    borderRadius: AppConfig.borderRadius),
              ),
              child: Text(
                '閉じる / Close',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppConfig.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
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

  Widget _divider() =>
      const Divider(color: AppConfig.borderSecondary, height: 1);
}
