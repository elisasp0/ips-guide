import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/layout/responsive.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/kebutuhan_repository.dart';
import '../../../domain/entities/guidance_service.dart';
import '../../../domain/entities/kebutuhan_warga.dart';

/// H7 Sampaikan Kebutuhan — form warga (Modul Minggu 7).
///
/// Memenuhi luaran pertemuan 7:
/// - **tiga kolom dari dua jenis input**: nama (teks), jenis layanan
///   (dropdown), pesan (teks multiline);
/// - **setiap kolom punya validator** dengan pesan yang menyebut kolomnya;
/// - **pesan status berhasil dan gagal** lewat `SnackBar`;
/// - **data valid tampil di daftar** di bawah formulir, dari repository
///   in-memory (hilang saat aplikasi dijalankan ulang — disengaja).
///
/// Halaman ini tidak menyimpan NIK/KK atau dokumen apa pun; hanya nama,
/// layanan, dan pesan bebas (§1.4 dokumen arsitektur).
class KebutuhanPage extends ConsumerStatefulWidget {
  const KebutuhanPage({super.key});

  @override
  ConsumerState<KebutuhanPage> createState() => _KebutuhanPageState();
}

class _KebutuhanPageState extends ConsumerState<KebutuhanPage> {
  /// Nama orang tidak memuat angka; dipakai sebagai aturan format.
  static final RegExp _polaAngka = RegExp(r'[0-9]');

  /// Bukan `final`: setelah penyimpanan berhasil, form diganti dengan instance
  /// baru supaya seluruh kolom (dan pesan galatnya) benar-benar bersih.
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nama = TextEditingController();
  final TextEditingController _pesan = TextEditingController();

  String? _serviceId;
  bool _mengirim = false;

  @override
  void dispose() {
    _nama.dispose();
    _pesan.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- validasi

  String? _validasiNama(String? nilai) {
    final teks = (nilai ?? '').trim();
    if (teks.isEmpty) return 'Nama pemohon wajib diisi.';
    if (teks.length < 3) return 'Nama minimal 3 karakter.';
    if (teks.length > 60) return 'Nama maksimal 60 karakter.';
    if (_polaAngka.hasMatch(teks)) return 'Nama tidak boleh mengandung angka.';
    return null;
  }

  String? _validasiLayanan(String? nilai) =>
      (nilai == null || nilai.isEmpty) ? 'Pilih jenis layanan.' : null;

  String? _validasiPesan(String? nilai) {
    final teks = (nilai ?? '').trim();
    if (teks.isEmpty) return 'Pesan atau kebutuhan wajib diisi.';
    if (teks.length < 10) return 'Pesan minimal 10 karakter.';
    return null;
  }

  // --------------------------------------------------------------- kirim

  Future<void> _kirim(List<GuidanceService> layanan) async {
    final messenger = ScaffoldMessenger.of(context);
    // Pesan lama tidak boleh menahan pesan baru (Modul Minggu 7 §4).
    messenger.hideCurrentSnackBar();

    if (!(_formKey.currentState?.validate() ?? false)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Periksa kembali isian yang ditandai merah.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    GuidanceService? dipilih;
    for (final s in layanan) {
      if (s.id == _serviceId) dipilih = s;
    }
    if (dipilih == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Jenis layanan tidak dikenal. Muat ulang halaman.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _mengirim = true);
    try {
      await ref.read(kebutuhanRepositoryProvider).kirim(
            namaPemohon: _nama.text,
            serviceId: dipilih.id,
            serviceNama: dipilih.nama,
            pesan: _pesan.text,
          );
      ref.invalidate(daftarKebutuhanProvider);
      if (!mounted) return;

      // Kosongkan kolom LALU ganti form dengan instance baru.
      //
      // `reset()` saja tidak cukup: dengan `autovalidateMode.onUserInteraction`
      // form masih mengingat bahwa pengguna pernah berinteraksi, sehingga
      // pengosongan kolom langsung memunculkan pesan "wajib diisi" padahal
      // pengiriman baru saja berhasil. GlobalKey baru membuat seluruh keadaan
      // kolom (termasuk penanda interaksi) dimulai dari nol.
      _nama.clear();
      _pesan.clear();
      setState(() {
        _serviceId = null;
        _mengirim = false;
        _formKey = GlobalKey<FormState>();
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Kebutuhan terkirim. Petugas akan menindaklanjuti.'),
        ),
      );
    } on KebutuhanException catch (e) {
      if (!mounted) return;
      setState(() => _mengirim = false);
      messenger.showSnackBar(
        SnackBar(content: Text(e.pesan), backgroundColor: AppColors.danger),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _mengirim = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan. Periksa koneksi lalu coba lagi.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // ----------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sampaikan Kebutuhan'),
        leading: IconButton(
          tooltip: 'Kembali ke Beranda',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(kPagePadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kResultMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tulis pertanyaan atau kebutuhan Anda untuk petugas '
                    'kelurahan. Data hanya tersimpan selama aplikasi berjalan '
                    'dan belum dikirim ke server.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  servicesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(kPagePadding),
                        child: Text(
                          'Daftar layanan gagal dimuat.\n$e',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    data: (layanan) => _formulir(theme, layanan),
                  ),
                  const SizedBox(height: 24),
                  _bagianDaftar(theme),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulir(ThemeData theme, List<GuidanceService> layanan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kPagePadding),
        child: Form(
          key: _formKey,
          // Pesan galat ikut diperbarui saat pengguna memperbaiki isian
          // (Modul Minggu 7 §4) sehingga pesan lama tidak tertinggal.
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('h7-nama'),
                controller: _nama,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama pemohon',
                ),
                validator: _validasiNama,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('h7-layanan'),
                // `initialValue` sengaja tidak diisi: nilai awal selalu
                // kosong, sehingga `reset()` benar-benar mengosongkan pilihan.
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Jenis layanan',
                ),
                items: [
                  for (final s in layanan)
                    DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(s.nama),
                    ),
                ],
                onChanged: _mengirim
                    ? null
                    : (nilai) => setState(() => _serviceId = nilai),
                validator: _validasiLayanan,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('h7-pesan'),
                controller: _pesan,
                maxLines: 4,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Pesan atau kebutuhan',
                  alignLabelWithHint: true,
                  hintText: 'Contoh: saya perlu memperbarui alamat pada KK '
                      'karena baru pindah rumah.',
                ),
                validator: _validasiPesan,
              ),
              const SizedBox(height: 4),
              // Tombol tetap aktif meski isian belum lengkap: pengguna selalu
              // mendapat penjelasan mengapa data belum terkirim.
              FilledButton(
                key: const Key('h7-kirim'),
                onPressed: _mengirim ? null : () => _kirim(layanan),
                child: _mengirim
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kirim'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bagianDaftar(ThemeData theme) {
    final daftarAsync = ref.watch(daftarKebutuhanProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Daftar kebutuhan terkirim',
                style: theme.textTheme.titleMedium),
            const SizedBox(width: 8),
            daftarAsync.maybeWhen(
              data: (daftar) => Text(
                '(${daftar.length})',
                style: theme.textTheme.bodySmall,
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        daftarAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(kPagePadding),
              child: Text('Daftar gagal dimuat.\n$e',
                  style: theme.textTheme.bodyMedium),
            ),
          ),
          data: (daftar) => daftar.isEmpty
              ? const _KeadaanKosong()
              : Column(
                  children: [
                    for (final k in daftar) ...[
                      _KartuKebutuhan(kebutuhan: k),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// Keadaan kosong daftar — dipakai sebelum ada data (Modul Minggu 6).
class _KeadaanKosong extends StatelessWidget {
  const _KeadaanKosong();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kPagePadding),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 40),
            const SizedBox(height: 8),
            Text(
              'Belum ada kebutuhan yang dikirim.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Isi formulir di atas lalu tekan Kirim.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu baris daftar kebutuhan yang sudah terkirim.
class _KartuKebutuhan extends StatelessWidget {
  final KebutuhanWarga kebutuhan;

  const _KartuKebutuhan({required this.kebutuhan});

  static String _waktu(DateTime d) {
    String dua(int n) => n.toString().padLeft(2, '0');
    return '${dua(d.day)}/${dua(d.month)}/${d.year} '
        '${dua(d.hour)}:${dua(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: Key('kebutuhan-${kebutuhan.id}'),
      child: Padding(
        padding: const EdgeInsets.all(kPagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    kebutuhan.namaPemohon,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  _waktu(kebutuhan.dibuatPada),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              kebutuhan.serviceNama,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(kebutuhan.pesan, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
