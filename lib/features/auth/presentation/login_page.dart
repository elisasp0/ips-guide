import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/layout/responsive.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/auth_repository.dart';
import '../application/auth_controller.dart';

/// H1 Login (§5, §9).
///
/// - Mode **Masuk** dan **Daftar** berada di halaman yang sama (§9.3) agar
///   jumlah halaman Must tetap enam.
/// - Formulir Daftar meminta **nama** — aturan `create` Firestore
///   mensyaratkannya (§9.1).
/// - Format email & panjang kata sandi divalidasi di klien SEBELUM repository
///   dipanggil (S24).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static final _polaEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  final _nama = TextEditingController();

  bool _modeDaftar = false;
  bool _sandiTerlihat = false;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    _nama.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    // S24: masukan tidak valid ditolak di sini, repository tidak dipanggil.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final pengendali = ref.read(authControllerProvider.notifier);
    if (_modeDaftar) {
      await pengendali.daftar(
        nama: _nama.text.trim(),
        email: _email.text.trim(),
        password: _sandi.text,
      );
    } else {
      await pengendali.masuk(
        email: _email.text.trim(),
        password: _sandi.text,
      );
    }
  }

  void _gantiMode(bool daftar) {
    if (_modeDaftar == daftar) return;
    setState(() {
      _modeDaftar = daftar;
      _formKey.currentState?.reset();
      _sandi.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final petunjuk = ref.watch(authRepositoryProvider).petunjukDemo;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(kPagePadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('IPS-Guide', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Panduan layanan administrasi Kelurahan Tegalsari',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),

                      if (auth.status == AuthStatus.profilHilang)
                        _ProfilHilang(
                          pesan: auth.pesanGalat ??
                              AuthErrorCode.profilTidakDitemukan.pesan,
                          sedangProses: auth.sedangProses,
                          onKeluar: () => ref
                              .read(authControllerProvider.notifier)
                              .keluar(),
                        )
                      else ...[
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('Masuk')),
                            ButtonSegment(value: true, label: Text('Daftar')),
                          ],
                          selected: {_modeDaftar},
                          showSelectedIcon: false,
                          onSelectionChanged: auth.sedangProses
                              ? null
                              : (pilihan) => _gantiMode(pilihan.first),
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_modeDaftar) ...[
                                TextFormField(
                                  key: const Key('h1-nama'),
                                  controller: _nama,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Nama lengkap',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Nama wajib diisi.'
                                          : null,
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextFormField(
                                key: const Key('h1-email'),
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                                validator: (v) {
                                  final nilai = (v ?? '').trim();
                                  if (nilai.isEmpty) {
                                    return 'Email wajib diisi.';
                                  }
                                  if (!_polaEmail.hasMatch(nilai)) {
                                    return 'Format email tidak valid.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                key: const Key('h1-sandi'),
                                controller: _sandi,
                                obscureText: !_sandiTerlihat,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _kirim(),
                                decoration: InputDecoration(
                                  labelText: 'Kata sandi',
                                  suffixIcon: IconButton(
                                    tooltip: _sandiTerlihat
                                        ? 'Sembunyikan kata sandi'
                                        : 'Tampilkan kata sandi',
                                    icon: Icon(
                                      _sandiTerlihat
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () => _sandiTerlihat = !_sandiTerlihat,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Kata sandi wajib diisi.';
                                  }
                                  if (v.length < 6) {
                                    return 'Kata sandi minimal 6 karakter.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        if (auth.pesanGalat != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            auth.pesanGalat!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          key: const Key('h1-kirim'),
                          onPressed: auth.sedangProses ? null : _kirim,
                          child: auth.sedangProses
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_modeDaftar ? 'Daftar' : 'Masuk'),
                        ),
                        if (petunjuk != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Text(
                              petunjuk,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keadaan U-07: akun ada, profil tidak ditemukan.
///
/// Tidak ada pemulihan otomatis (nama tidak boleh ditebak dari email);
/// satu-satunya jalan adalah keluar lalu hubungi admin / daftar ulang.
class _ProfilHilang extends StatelessWidget {
  final String pesan;
  final bool sedangProses;
  final VoidCallback onKeluar;

  const _ProfilHilang({
    required this.pesan,
    required this.sedangProses,
    required this.onKeluar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Profil akun tidak ditemukan',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(pesan, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        OutlinedButton(
          key: const Key('h1-keluar'),
          onPressed: sedangProses ? null : onKeluar,
          child: const Text('Keluar'),
        ),
      ],
    );
  }
}
