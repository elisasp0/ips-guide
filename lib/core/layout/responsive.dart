import 'package:flutter/material.dart';

/// Breakpoint responsif — 600 px (style guide Minggu 4, §13).
///
/// Di bawah 600 px: NavigationBar (bottom navigation).
/// 600 px ke atas: NavigationRail (sidebar).
const double kResponsiveBreakpoint = 600;

/// Margin tepi 16 px, jarak kelipatan 8 (§13.3).
const double kPagePadding = 16;

bool isWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kResponsiveBreakpoint;

/// Lebar maksimum konten H5 (§13.6: Hasil Panduan 720 px).
const double kResultMaxWidth = 720;
