import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/simple_pages.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/guidance/presentation/guidance_tab_page.dart';
import '../features/guidance/presentation/pertanyaan_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/result/presentation/hasil_page.dart';
import '../features/services/presentation/service_list_page.dart';
import 'shell.dart';

/// Navigasi (§3.6) + guard autentikasi (§9.1, Tahap 5).
///
/// ShellRoute untuk tiga tab utama; di luar shell: /login, /panduan/:serviceId
/// (H4), /hasil (H5), /admin (H6).
///
/// Guard di sini bersifat **kenyamanan**, bukan keamanan (U-05): ia dapat
/// dilewati lewat SDK. Yang menentukan adalah Firestore rules (Tahap 6).
final routerProvider = Provider<GoRouter>((ref) {
  // Beri tahu GoRouter saat status sesi berubah, tanpa membangun ulang router
  // (membangun ulang akan kehilangan riwayat navigasi).
  final pemicu = ValueNotifier<int>(0);
  ref.listen<AuthState>(authControllerProvider, (_, _) => pemicu.value++);
  ref.onDispose(pemicu.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: pemicu,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final diLogin = state.matchedLocation == '/login';

      // Status belum diketahui — halaman splash ditangani IpsGuideApp.
      if (auth.status == AuthStatus.memuat) return null;

      // Belum masuk ATAU profil hilang (U-07): keduanya harus di H1.
      if (auth.status != AuthStatus.masuk) {
        return diLogin ? null : '/login';
      }

      if (diLogin) return '/';

      // S25: warga yang membuka /admin dialihkan ke Beranda.
      if (state.matchedLocation.startsWith('/admin') && !auth.isAdmin) {
        return '/';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final path = state.uri.path;
          final int index;
          if (path.startsWith('/layanan')) {
            index = 1;
          } else if (path.startsWith('/panduan')) {
            index = 2;
          } else {
            index = 0;
          }
          return AdaptiveShell(selectedIndex: index, child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'beranda',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/layanan',
            name: 'layanan',
            builder: (context, state) => const ServiceListPage(),
          ),
          GoRoute(
            path: '/panduan',
            name: 'panduan',
            builder: (context, state) => const GuidanceTabPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/panduan/:serviceId',
        name: 'pertanyaan',
        builder: (context, state) => PertanyaanPage(
          serviceId: state.pathParameters['serviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/hasil',
        name: 'hasil',
        builder: (context, state) => const HasilPage(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const PlaceholderPage(
          title: 'Kelola Panduan',
          pesan: 'Dibangun pada Tahap 7.',
        ),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
});
