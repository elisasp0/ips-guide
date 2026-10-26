/// Hasil akhir panduan — §10.7 RANCANGAN-ARSITEKTUR.md.
///
/// `null` outcome (tidak ada aturan yang menetapkan keputusan) berarti
/// "Panduan belum tersedia" — bukan kegagalan sistem, melainkan deteksi
/// celah basis pengetahuan (§10.8).
enum Outcome {
  dapatDiproses('dapat_diproses'),
  denganCatatan('dengan_catatan'),
  tidakDapatDiproses('tidak_dapat_diproses');

  const Outcome(this.wireName);

  /// Nama yang dipakai di Firestore / seed JSON (§8.2).
  final String wireName;

  static Outcome? fromWireName(String? name) {
    if (name == null) return null;
    for (final o in Outcome.values) {
      if (o.wireName == name) return o;
    }
    return null;
  }
}
