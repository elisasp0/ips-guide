import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../data/repositories/knowledge_base_repository.dart';
import '../../../domain/engine/guidance_session.dart';
import '../../../domain/entities/guidance_question.dart';
import '../../../domain/entities/guidance_result.dart';
import '../../result/application/hasil_provider.dart';

/// Siklus sesi panduan (§15 Tahap 4):
/// `loading → questioning → completed | error`.
///
/// Controller tidak pernah mengevaluasi aturan sendiri — semua inferensi
/// ada di `GuidanceSession` (§3.1 aturan 2). Urutan operasi di dalam
/// session sudah benar: jawab → pangkas → inferensi (U-04).
enum GuidancePhase { idle, loading, questioning, completed, error }

class GuidanceState {
  final GuidancePhase phase;
  final String? serviceId;
  final String? serviceNama;
  final GuidanceQuestion? question;

  /// Jumlah jawaban tersimpan (untuk progres & mengaktifkan tombol Kembali).
  final int answered;

  /// Batas atas progres: jumlah pertanyaan aktif layanan.
  final int totalQuestions;
  final GuidanceResult? result;
  final String? error;

  const GuidanceState({
    required this.phase,
    this.serviceId,
    this.serviceNama,
    this.question,
    this.answered = 0,
    this.totalQuestions = 0,
    this.result,
    this.error,
  });

  const GuidanceState.idle()
      : phase = GuidancePhase.idle,
        serviceId = null,
        serviceNama = null,
        question = null,
        answered = 0,
        totalQuestions = 0,
        result = null,
        error = null;

  const GuidanceState.loading(String this.serviceId)
      : phase = GuidancePhase.loading,
        serviceNama = null,
        question = null,
        answered = 0,
        totalQuestions = 0,
        result = null,
        error = null;
}

class GuidanceController extends Notifier<GuidanceState> {
  GuidanceSession? _session;

  @override
  GuidanceState build() => const GuidanceState.idle();

  /// Mulai (atau mulai ulang) sesi untuk satu layanan.
  ///
  /// Aman dipanggil berulang dari H4: sesi questioning untuk layanan yang
  /// sama tidak di-restart.
  Future<void> mulai(String serviceId) async {
    if (state.phase == GuidancePhase.questioning &&
        state.serviceId == serviceId) {
      return;
    }
    _session = null;
    ref.read(hasilPanduanProvider.notifier).set(null);
    state = GuidanceState.loading(serviceId);
    try {
      final repo = await ref.read(repositoryProvider.future);
      final kb = await repo.loadService(serviceId);
      _session = GuidanceSession(kb);
      _publish();
    } on KnowledgeBaseException catch (e) {
      state = GuidanceState(
        phase: GuidancePhase.error,
        serviceId: serviceId,
        error: 'Layanan belum tersedia. ${e.message}',
      );
    } catch (_) {
      state = GuidanceState(
        phase: GuidancePhase.error,
        serviceId: serviceId,
        error: 'Layanan belum tersedia. Coba beberapa saat lagi.',
      );
    }
  }

  /// Pengguna memilih satu opsi untuk pertanyaan aktif.
  void jawab(String value) {
    final q = state.question;
    final session = _session;
    if (q == null || session == null) return;
    session.answer(q.factKey, value);
    _publish();
  }

  /// Tombol "Kembali": buang jawaban terakhir DAN picu recompute —
  /// fakta jalur lama dipangkas oleh session (U-04, T-04).
  void kembali() {
    final session = _session;
    if (session == null) return;
    final keys = session.answers.keys.toList();
    if (keys.isEmpty) return;
    session.kembali(keys.last);
    ref.read(hasilPanduanProvider.notifier).set(null);
    _publish();
  }

  /// Tombol "Selesai" di H5: akhiri sesi.
  void selesai() {
    _session = null;
    ref.read(hasilPanduanProvider.notifier).set(null);
    state = const GuidanceState.idle();
  }

  void _publish() {
    final session = _session!;
    final kb = session.kb;
    final total = kb.questions.where((q) => q.aktif).length;

    if (session.isFinished) {
      final result = session.buildResult();
      ref.read(hasilPanduanProvider.notifier).set(
            HasilPanduan(
              result: result,
              ringkasanJawaban: _ringkasanJawaban(session),
            ),
          );
      state = GuidanceState(
        phase: GuidancePhase.completed,
        serviceId: kb.serviceId,
        serviceNama: kb.service.nama,
        answered: session.answers.length,
        totalQuestions: total,
        result: result,
      );
      return;
    }

    state = GuidanceState(
      phase: GuidancePhase.questioning,
      serviceId: kb.serviceId,
      serviceNama: kb.service.nama,
      question: session.currentQuestion,
      answered: session.answers.length,
      totalQuestions: total,
    );
  }

  /// Ringkasan untuk H5: (teks pertanyaan, label jawaban) urut penjawaban.
  List<(String, String)> _ringkasanJawaban(GuidanceSession session) {
    final kb = session.kb;
    final out = <(String, String)>[];
    for (final entry in session.answers.entries) {
      final q = kb.questionByFactKey(entry.key);
      if (q == null) continue;
      String label = entry.value;
      for (final o in q.opsi) {
        if (o.value == entry.value) {
          label = o.label;
          break;
        }
      }
      out.add((q.teks, label));
    }
    return out;
  }
}

/// Provider controller sesi panduan — satu sesi aktif global (tab Panduan
/// menampilkan sesi aktif, §3.6).
final guidanceControllerProvider =
    NotifierProvider<GuidanceController, GuidanceState>(
  GuidanceController.new,
);
