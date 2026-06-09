import 'package:flutter/material.dart';

class AppConfig {
  // Remote Endpoints
  static const String serverUrl = 'https://kurachi.onrender.com';
  
  static const String ipUrl = 
      'https://script.google.com/macros/s/AKfycbyC6-KiT3xwGiahhzhB-L-OOL8ufG0WqnT5mjEelGBKGnbiqVAS6qjT78FlzBUHqTn3Gg/exec';
      
  static const String picUrl = 
      'https://script.google.com/macros/s/AKfycbwHUW1ia8hNZG-ljsguNq8K4LTPVnB6Ng_GLXIHmtJTdUgGGd2WoiQo9ToF-7PvcJh9bA/exec';
      
  static const String googleSheetLiveStatusUrl = 
      'https://script.google.com/macros/s/AKfycbwbL30hlX9nBlQH4dwxlbdxSM5kJtgtNEQJQInA1mgXlEhYJxFHykZkdXV38deR6P83Ow/exec';
      
  static const String dbUrl = 
      'https://script.google.com/macros/s/AKfycbx0qBw0_wF5X-hA2t1yY-d5h5M7Z_a8z_V9R5D6k/exec';

  // Constants
  static const String defaultFactory = '小瀬';
  static const String defaultMachine = 'OZNC01';

  // Dynamic Theme Flag
  static bool isDark = false;

  // Premium Color Palette - Light & Dark Modes
  static Color get backgroundColor => isDark 
      ? const Color(0xFF121212) // Deep Charcoal / Jet Black
      : const Color(0xFFF7F9FC); // Cool Off-white

  static Color get cardColor => isDark 
      ? const Color(0xFF1E1E1E) // Slate Gray Card
      : const Color(0xFFFFFFFF); // White

  static Color get borderSecondary => isDark 
      ? const Color(0xFF2C2C2C) // Dark Border
      : const Color(0xFFE2E8F0); // Slate 200

  static Color get inputFillColor => isDark 
      ? const Color(0xFF121212) // Dark Mode input field fill
      : const Color(0xFFF1F5F9); // Light Mode input field fill (Slate 100)

  static Color get inputBorderColor => isDark 
      ? const Color(0xFF475569) // Dark Mode input border (Slate 600)
      : const Color(0xFFCBD5E1); // Light Mode input border (Slate 300)

  static Color get primaryAccent => isDark 
      ? const Color(0xFFFFD166) // Neon Safety Yellow
      : const Color(0xFF1D3557); // Vivid Blue / Navy

  static Color get primaryHover => isDark 
      ? const Color(0xFFE5BC5C) 
      : const Color(0xFF152943);

  static Color get okColor => isDark 
      ? const Color(0xFF059669) // Emerald 600
      : const Color(0xFF00A896); // Electric Cyan

  static Color get ngColor => isDark 
      ? const Color(0xFFDC2626) // Red 600
      : const Color(0xFFDC2626); // Red 600 (kept same for consistency)

  static Color get warningColor => isDark 
      ? const Color(0xFFF4A261) // Industrial Orange
      : const Color(0xFFD97706); // Amber 600

  static Color get textPrimary => isDark 
      ? const Color(0xFFF8FAFC) // Slate 50
      : const Color(0xFF0F172A); // Slate 900

  static Color get textSecondary => isDark 
      ? const Color(0xFF94A3B8) // Slate 400
      : const Color(0xFF475569); // Slate 600

  static Color get textMuted => isDark 
      ? const Color(0xFF475569) // Slate 600
      : const Color(0xFF94A3B8); // Slate 400

  // ── Border radius scale ──────────────────────────────────────────────────────
  static final BorderRadius radiusSm   = BorderRadius.circular(8);   // chips, badges, small containers
  static final BorderRadius radiusMd   = BorderRadius.circular(12);  // inputs, secondary buttons
  static final BorderRadius borderRadius = BorderRadius.circular(16); // standard buttons, cards
  static final BorderRadius cardRadius = BorderRadius.circular(20);   // large cards, sheets, dialogs

  // ── Spacing scale — 8pt grid ─────────────────────────────────────────────────
  static const double sp4  = 4;
  static const double sp8  = 8;
  static const double sp12 = 12;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;
  static const double sp32 = 32;
  static const double sp48 = 48;
  static const double sp64 = 64;

  // ── Component sizes (Fitts's Law minimums) ───────────────────────────────────
  static const double touchTarget  = 48; // minimum tap target
  static const double buttonHeight = 52; // standard button height
  static const double inputHeight  = 56; // standard text field height

  // ── Semantic color aliases (replaces hardcoded Colors.white / Colors.black) ──
  static Color get onAccent => isDark 
      ? const Color(0xFF121212) // Dark text on Safety Yellow buttons
      : const Color(0xFFFFFFFF); // White text on Vivid Blue buttons

  static Color get overlayDark => isDark 
      ? const Color(0xFF000000) 
      : const Color(0xFF000000);

  // Modern Linear Gradient
  static LinearGradient get primaryGradient => isDark
      ? LinearGradient(
          colors: [Color(0xFFFFD166), Color(0xFFF4A261)], // Yellow to Orange
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : LinearGradient(
          colors: [Color(0xFF1D3557), Color(0xFF457B9D)], // Vivid Blue to Steel Blue
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

  static LinearGradient get okGradient => isDark
      ? LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)], // Emerald to Green
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : LinearGradient(
          colors: [Color(0xFF00A896), Color(0xFF02C2AD)], // Electric Cyan to Mint
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

  static LinearGradient get ngGradient => isDark
      ? LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFEF4444)], // Red to Light Red
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFEF4444)], // Red to Light Red
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
}
