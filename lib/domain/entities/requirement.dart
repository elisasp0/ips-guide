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
}
