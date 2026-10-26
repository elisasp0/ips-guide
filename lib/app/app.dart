import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

/// Root aplikasi IPS-Guide (§3.2 lapisan `app/`): tema §13 + routing.
class IpsGuideApp extends ConsumerWidget {
  const IpsGuideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'IPS-Guide',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
