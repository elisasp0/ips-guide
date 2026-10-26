/// Satu dokumen persyaratan (§7).
///
/// [sourceRuleId] adalah explanation facility: hasil H5 dapat menjelaskan
/// dari aturan mana persyaratan itu berasal.
class Requirement {
  final String id;
  final String nama;
  final String? keterangan;
  final bool wajib;
  final String sourceRuleId;

  const Requirement({
    required this.id,
    required this.nama,
    this.keterangan,
    this.wajib = true,
    required this.sourceRuleId,
  });

  /// Dipakai jalur simpan H6 (§12.3 tahap B: ubah nama/keterangan).
  ///
  /// `sourceRuleId` sengaja tidak dapat diubah — ia explanation facility yang
  /// diturunkan dari aturan, bukan data yang diisi admin.
  Requirement copyWith({String? nama, String? keterangan}) => Requirement(
        id: id,
        nama: nama ?? this.nama,
        keterangan: keterangan ?? this.keterangan,
        wajib: wajib,
        sourceRuleId: sourceRuleId,
      );
}
