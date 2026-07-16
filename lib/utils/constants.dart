// lib/utils/constants.dart

import 'package:flutter/material.dart';

// ============================================================
// 🌟 APP COLORS (المستودع المركزي الثابت للألوان)
// ============================================================
class AppColors {
  AppColors._(); // منع إنشاء instance

  // الألوان الأساسية
  static const Color navy       = Color(0xFF1D2D44); // الكحلي الداكن
  static const Color navyLight  = Color(0xFF2A437D); // كحلي فاتح
  static const Color beige      = Color(0xFFFFF9EE); // الخلفية العاجية (البيج)
  static const Color white      = Color(0xFFFFFFFF); // أبيض صافي للكروت
  static const Color greyLine   = Color(0xFFC5C1D6); // الرمادي للحدود والخطوط السفلى

  // ألوان الحالات والتبويبات
  static const Color green      = Color(0xFF179E1E); 
  static const Color greenLight = Color(0xFF56CD76); 
  static const Color red        = Color(0xFFD92326); 
  static const Color orange     = Color(0xFFEB8E0B); 
  static const Color cyan       = Color(0xFF06B6D4); 
  static const Color lime       = Color(0xFFC8F984); 
  static const Color otpBoxBg   = Color(0xFFDDE1F0); // لون مربعات التحقق الفاتح

  // ألوان النصوص
  static const Color textDark   = Color(0xFF1D2D44); 
  static const Color textGrey   = Color(0xFF8E8E93); // رمادي صريح ومناسب للكتابة والتلميح
  static const Color textLight  = Color(0xFFFFFFFF); 

  // التدرج المعتمد لشاشة الـ Welcome
  static LinearGradient get welcomeGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.50, 0.75, 0.88, 1.0],
    colors: [
      white,
      Color(0x87FFF8F4), 
      Color(0xFFFFF8F4), 
      Color(0x997591BB), 
      navyLight,
    ],
  );
}

// ============================================================
// 🌟 APP TEXT STYLES (خطوط النظام المركزية المربوطة بـ ThemeData)
// ============================================================
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Inter', fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyRegular = TextStyle(
    fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w400,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3,
  );

  static const TextStyle cardLabel = TextStyle(
    fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, height: 1.4,
  );
}

// ============================================================
// 🌟 APP SPACING & DIMENSIONS (الأبعاد والمساحات المعتمدة)
// ============================================================
class AppSpacing {
  AppSpacing._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double screenH = 28.0;
}

class AppDimensions {
  AppDimensions._();
  static const double roleCardWidth = 158.0;
  static const double roleCardHeight = 205.0;

  static const BorderRadius roleCardRadius = BorderRadius.only(
    topRight: Radius.circular(40), bottomLeft: Radius.circular(40),
  );

  static const BorderRadius roleCardRadiusFlipped = BorderRadius.only(
    topLeft: Radius.circular(40), bottomRight: Radius.circular(40),
  );

  static const double iconBoxSize = 56.0;
  static const double iconBoxRadius = 14.0;
  static const double iconSize = 28.0;
}

// ============================================================
// 🌟 APP THEME (التوزيع الاحترافي للألوان داخل هيكلية النظام)
// ============================================================
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.beige, // خلفية التطبيق بيج دائماً

    colorScheme: const ColorScheme.light(
      primary: AppColors.cyan,              
      primaryContainer: AppColors.navy,     // الكحلي للهيدر والأزرار
      surface: AppColors.white,             
      onSurface: AppColors.textDark,        
      onSurfaceVariant: AppColors.textGrey, // الرمادي للتلميحات
      outline: AppColors.greyLine,          // الرمادي للخطوط السفلى للحقول
      error: AppColors.red,                 
      tertiary: AppColors.otpBoxBg,         
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.heading2,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: AppTextStyles.button,
        elevation: 0,
      ),
    ),

    // 🌟 التعديل السحري: جعل الحقول عبارة عن خط سفلي فقط بدون مستطيلات بيضاء
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.beige, // جعل الخلفية بيج متطابقة مع الشاشة ليختفي المستطيل تماماً
      hintStyle: AppTextStyles.bodySecondary.copyWith(color: AppColors.textGrey),
      contentPadding: const EdgeInsets.symmetric(vertical: 10), // حشوة ناعمة للخط
      
      // الحدود الافتراضية والتمكين: خط سفلي رفيع رمادي
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.greyLine, width: 1.0),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.greyLine, width: 1.0),
      ),
      // الحدود عند التركيز والكتابة: خط كحلي أنيق
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.navy, width: 1.5),
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: AppTextStyles.heading1,
      titleLarge: AppTextStyles.heading2,
      bodyLarge: AppTextStyles.bodyMedium,
      bodyMedium: AppTextStyles.bodyRegular,
      bodySmall: AppTextStyles.bodySecondary,
      labelLarge: AppTextStyles.button,
    ),
  );
}