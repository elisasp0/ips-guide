/// Catatan tambahan pada hasil panduan (§7).
///
/// Catatan berasal dari `rule.then.addNotes`; [sourceRuleId] menjelaskan
/// aturan sumbernya (explanation facility).
class GuidanceNote {
  final String teks;
  final String sourceRuleId;

  const GuidanceNote({required this.teks, required this.sourceRuleId});
}
