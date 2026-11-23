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
/// - **data valid tampil di daftar** di bawah formulir,
///   menggunakan Cloud Firestore dan difilter berdasarkan akun warga.
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

  // --------------------------------------------------------- EDIT KEBUTUHAN

  Future<void> _ubah(KebutuhanWarga kebutuhan) async {
    if (!kebutuhan.bisaDiubah) return;

    List<GuidanceService> layanan;

    try {
      layanan = await ref.read(servicesProvider.future);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat pilihan layanan.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (!mounted) return;

    final namaController =
        TextEditingController(text: kebutuhan.namaPemohon);
    final pesanController =
        TextEditingController(text: kebutuhan.pesan);
    final formKey = GlobalKey<FormState>();

    String? serviceId = layanan.any(
      (s) => s.id == kebutuhan.serviceId,
    )
        ? kebutuhan.serviceId
        : null;

    bool menyimpan = false;

    final berhasil = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Kebutuhan'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: namaController,
                          decoration: const InputDecoration(
                            labelText: 'Nama pemohon',
                          ),
                          validator: _validasiNama,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: serviceId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Jenis layanan',
                          ),
                          items: [
                            for (final s in layanan)
                              DropdownMenuItem(
                                value: s.id,
                                child: Text(s.nama),
                              ),
                          ],
                          onChanged: menyimpan
                              ? null
                              : (nilai) {
                                  setDialogState(
                                    () => serviceId = nilai,
                                  );
                                },
                          validator: _validasiLayanan,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: pesanController,
                          maxLines: 4,
                          maxLength: 300,
                          decoration: const InputDecoration(
                            labelText: 'Pesan atau kebutuhan',
                          ),
                          validator: _validasiPesan,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: menyimpan
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: menyimpan
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ??
                              false)) {
                            return;
                          }

                          final dipilih = layanan.where(
                            (s) => s.id == serviceId,
                          );

                          if (dipilih.isEmpty) return;

                          setDialogState(() => menyimpan = true);

                          try {
                            await ref
                                .read(kebutuhanRepositoryProvider)
                                .ubah(
                                  id: kebutuhan.id,
                                  namaPemohon: namaController.text,
                                  serviceId: dipilih.first.id,
                                  serviceNama: dipilih.first.nama,
                                  pesan: pesanController.text,
                                );

                            if (!mounted) return;

                            ref.invalidate(daftarKebutuhanProvider);

                            Navigator.pop(dialogContext, true);
                          } catch (e) {
                            setDialogState(() => menyimpan = false);

                            ScaffoldMessenger.of(dialogContext)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  e is KebutuhanException
                                      ? e.pesan
                                      : 'Gagal mengubah kebutuhan.',
                                ),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        },
                  child: menyimpan
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Simpan Perubahan'),
                ),
              ],
            );
          },
        );
      },
    );

    namaController.dispose();
    pesanController.dispose();

    if (!mounted) return;

    if (berhasil == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kebutuhan berhasil diperbarui.'),
        ),
      );
    }
  }

  // -------------------------------------------------------- HAPUS KEBUTUHAN

  Future<void> _hapus(KebutuhanWarga kebutuhan) async {
    if (!kebutuhan.bisaDiubah) return;

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Kebutuhan?'),
        content: Text(
          'Apakah kamu yakin ingin menghapus kebutuhan '
          'milik ${kebutuhan.namaPemohon}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;

    try {
      await ref.read(kebutuhanRepositoryProvider).hapus(
            id: kebutuhan.id,
          );

      ref.invalidate(daftarKebutuhanProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kebutuhan berhasil dihapus.'),
        ),
      );
    } on KebutuhanException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.pesan),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus kebutuhan.'),
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
                    'kelurahan. Data akan disimpan di server dan dapat '
                    'dilihat kembali melalui akun Anda.',
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
            _KartuKebutuhan(
              kebutuhan: k,
              onEdit: () => _ubah(k),
              onDelete: () => _hapus(k),
            ),
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _KartuKebutuhan({
    required this.kebutuhan,
    required this.onEdit,
    required this.onDelete,
  });

  static String _waktu(DateTime d) {
    String dua(int n) => n.toString().padLeft(2, '0');
    return '${dua(d.day)}/${dua(d.month)}/${d.year} '
        '${dua(d.hour)}:${dua(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bisaDiubah = kebutuhan.bisaDiubah;

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

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Text(
                    kebutuhan.serviceNama,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  label: Text(kebutuhan.status),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: bisaDiubah
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              kebutuhan.pesan,
              style: theme.textTheme.bodyMedium,
            ),

            if (kebutuhan.diubahPada != null) ...[
              const SizedBox(height: 8),
              Text(
                'Terakhir diubah: ${_waktu(kebutuhan.diubahPada!)}',
                style: theme.textTheme.bodySmall,
              ),
            ],

            if (bisaDiubah) ...[
              const SizedBox(height: 12),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
