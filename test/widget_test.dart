import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kurachi_dcp/main.dart';
import 'package:kurachi_dcp/providers/report_provider.dart';

void main() {
  testWidgets('App smoke test - renders without crash',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ReportProvider(),
        child: const KurachiApp(hasSetup: false),
      ),
    );
    // App renders successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
