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

  // Premium Color Palette - Tailored Dark Mode
  static const Color backgroundColor = Color(0xFF0F172A); // Deep Slate 900
  static const Color cardColor = Color(0xFF1E293B); // Slate 800
  static const Color borderSecondary = Color(0xFF334155); // Slate 700
  
  static const Color primaryAccent = Color(0xFF6366F1); // Indigo 500
  static const Color primaryHover = Color(0xFF4F46E5); // Indigo 600
  
  static const Color okColor = Color(0xFF10B981); // Emerald 500
  static const Color ngColor = Color(0xFFEF4444); // Red 500
  static const Color warningColor = Color(0xFFF59E0B); // Amber 500
  
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  // Standard border radius
  static final BorderRadius borderRadius = BorderRadius.circular(16);
  static final BorderRadius cardRadius = BorderRadius.circular(20);

  // Modern Linear Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo to Violet
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient okGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)], // Emerald to Green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ngGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)], // Red to Dark Red
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
