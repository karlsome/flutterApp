import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_config.dart';
import 'providers/report_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable dynamic web font fetching so GoogleFonts can fetch Outfit font if not bundled
  GoogleFonts.config.allowRuntimeFetching = true;

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

  final prefs = await SharedPreferences.getInstance();
  final String? factory = prefs.getString('kurachi_selected_factory');
  final String? machine = prefs.getString('kurachi_selected_machine');
  final bool hasSetup = factory != null && machine != null && factory.isNotEmpty && machine.isNotEmpty;

  runApp(
    ChangeNotifierProvider(
      create: (_) => ReportProvider(),
      child: KurachiApp(
        hasSetup: hasSetup,
        initialFactory: factory,
        initialMachine: machine,
      ),
    ),
  );
}

class KurachiApp extends StatefulWidget {
  final bool hasSetup;
  final String? initialFactory;
  final String? initialMachine;

  const KurachiApp({
    super.key,
    required this.hasSetup,
    this.initialFactory,
    this.initialMachine,
  });

  @override
  State<KurachiApp> createState() => _KurachiAppState();
}

class _KurachiAppState extends State<KurachiApp> {
  @override
  void initState() {
    super.initState();
    if (widget.hasSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ReportProvider>().initEnvironment(
              widget.initialFactory!,
              widget.initialMachine!,
            );
      });
    }
  }

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
      home: widget.hasSetup ? const HomeScreen() : const SetupScreen(),
    );
  }
}
