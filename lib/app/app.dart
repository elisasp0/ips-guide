import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/simple_pages.dart';
import '../features/auth/application/auth_controller.dart';
import 'router.dart';
import 'theme.dart';

/// Root aplikasi IPS-Guide (§3.2 lapisan `app/`): tema §13 + routing.
///
/// Selama status sesi belum diketahui, ditampilkan halaman splash agar rute
/// tidak sempat dirender sebelum guard autentikasi berjalan (§9.1).
class IpsGuideApp extends ConsumerWidget {
  const IpsGuideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    if (auth.status == AuthStatus.memuat) {
      return MaterialApp(
        title: 'IPS-Guide',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: const SplashPage(),
      );
    }

    return MaterialApp.router(
      title: 'IPS-Guide',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
