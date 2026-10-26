import 'package:flutter/material.dart';

/// Style guide IPS-Guide — sumber: docs/RANCANGAN-ARSITEKTUR.md §13.
///
/// Warna disusun eksplisit (bukan ColorScheme.fromSeed) agar palet
/// konsisten dengan token warna frame Figma (Minggu 4).
abstract final class AppColors {
  static const Color primary = Color(0xFF0F766E); // Tombol utama, nav aktif
  static const Color textPrimary = Color(0xFF0F172A); // Judul, isi
  static const Color textSecondary = Color(0xFF475569); // Keterangan, label
  static const Color outline = Color(0xFFCBD5E1); // Batas kartu, pemisah
  static const Color background = Color(0xFFF8FAFC); // Latar halaman
  static const Color surface = Color(0xFFFFFFFF); // Kartu, AppBar
  static const Color success = Color(0xFF15803D); // dapat_diproses
  static const Color waiting = Color(0xFFC2410C); // dengan_catatan
  static const Color danger = Color(0xFFB91C1C); // tidak_dapat_diproses, galat
}

const ColorScheme _scheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.primary,
  onPrimary: Colors.white,
  secondary: AppColors.primary,
  onSecondary: Colors.white,
  error: AppColors.danger,
  onError: Colors.white,
  surface: AppColors.surface,
  onSurface: AppColors.textPrimary,
);

/// Tipografi Inter — judul 22/700, subjudul 16/700, isi 14/400,
/// keterangan 12/400 (§13.2).
const String _fontFamily = 'Inter';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _scheme,
  scaffoldBackgroundColor: AppColors.background,
  fontFamily: _fontFamily,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      // Judul 22/700
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      // Subjudul 16/700
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      // Isi 14/400
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),
    bodySmall: TextStyle(
      // Keterangan 12/400
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
  ),
  cardTheme: const CardThemeData(
    // Kartu: putih, garis #CBD5E1, radius 12, padding 16 (§13.3)
    color: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      side: BorderSide(color: AppColors.outline),
    ),
    margin: EdgeInsets.zero,
  ),
  filledButtonTheme: FilledButtonThemeData(
    // Tombol utama: isi #0F766E, teks putih, radius 12, tinggi >=48 (§13.3)
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(64, 48),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      textStyle: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    // Tombol sekunder: putih, garis #0F766E (§13.3)
    style: OutlinedButton.styleFrom(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.primary,
      minimumSize: const Size(64, 48),
      side: const BorderSide(color: AppColors.primary),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      textStyle: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.outline),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.outline),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.danger),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
);
