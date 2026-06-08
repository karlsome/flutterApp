import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'providers/report_provider.dart';
import 'screens/setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable dynamic web font fetching to optimize for offline/low-performance tablets
  GoogleFonts.config.allowRuntimeFetching = false;

  // Force portrait orientation on phones; allow both on tablets
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Full-screen immersive mode on Android
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppConfig.backgroundColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ReportProvider(),
      child: const KurachiApp(),
    ),
  );
}

class KurachiApp extends StatelessWidget {
  const KurachiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DCP iReporter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppConfig.backgroundColor,
        colorScheme: const ColorScheme.light(
          surface: AppConfig.backgroundColor,
          primary: AppConfig.primaryAccent,
          onPrimary: Colors.white,
          secondary: AppConfig.okColor,
          error: AppConfig.ngColor,
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.light().textTheme,
        ),
        cardTheme: CardThemeData(
          color: AppConfig.cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppConfig.cardRadius,
            side: const BorderSide(color: AppConfig.borderSecondary, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
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
          labelStyle: const TextStyle(color: AppConfig.textSecondary),
          hintStyle: const TextStyle(color: AppConfig.textMuted),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConfig.primaryAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppConfig.cardColor,
          contentTextStyle: GoogleFonts.outfit(color: AppConfig.textPrimary),
          shape: RoundedRectangleBorder(borderRadius: AppConfig.borderRadius),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const SetupScreen(),
    );
  }
}
