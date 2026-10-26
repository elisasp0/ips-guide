import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ips_guide/domain/entities/guidance_result.dart';

/// Bundle hasil untuk H5 — diset controller saat sesi selesai, dibersihkan
/// saat sesi baru dimulai atau tombol Selesai ditekan.
///
/// H5 membaca dari sini (bukan menyimpan sendiri) sehingga guard "/hasil
/// tanpa sesi aktif → /layanan" cukup memeriksa null (§3.6).
class HasilPanduan {
  final GuidanceResult result;

  /// (teks pertanyaan, jawaban terpilih) sesuai urutan penjawaban.
  final List<(String, String)> ringkasanJawaban;

  const HasilPanduan({required this.result, required this.ringkasanJawaban});
}

class HasilPanduanNotifier extends Notifier<HasilPanduan?> {
  @override
  HasilPanduan? build() => null;

  void set(HasilPanduan? value) => state = value;
}

final hasilPanduanProvider =
    NotifierProvider<HasilPanduanNotifier, HasilPanduan?>(
  HasilPanduanNotifier.new,
);
