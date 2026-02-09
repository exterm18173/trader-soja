import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/fx/fx_quote_create.dart';
import '../../data/models/fx/fx_quote_with_check_read.dart';
import '../../data/models/fx/fx_source_read.dart';
import '../../data/repositories/fx_quotes_repository.dart';
import '../../data/repositories/fx_sources_repository.dart';

class FxFuturesQuotesVM extends ChangeNotifier {
  final FxQuotesRepository quotesRepo;
  final FxSourcesRepository sourcesRepo;
  final FarmContext farmContext;

  FxFuturesQuotesVM(this.quotesRepo, this.sourcesRepo, this.farmContext);

  bool loading = false;
  Object? error;

  int? get farmId => farmContext.farmId;


  List<FxSourceRead> sources = [];
  int? selectedSourceId;

  DateTime selectedRefMes = _monthStart(DateTime.now());
  List<FxQuoteWithCheckRead> quotes = [];

  // ---- init ----
  void init({required int farmId}) {
    // default: mês atual (pode trocar na UI para futuros)
    selectedRefMes = _monthStart(DateTime.now());
  }

  // ---- loading helpers ----
  void _setLoading(bool v) {
    loading = v;
    notifyListeners();
  }

  void _setError(Object? e) {
    error = e;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  // ---- public api ----
  Future<void> loadInitial({bool keepSelectedSource = true}) async {
    if (farmId == null) return;

    _setLoading(true);
    _setError(null);
    try {
      sources = await sourcesRepo.list(onlyActive: true);
      if (!keepSelectedSource) selectedSourceId = null;

      // default: primeira fonte
      if (selectedSourceId == null && sources.isNotEmpty) {
        selectedSourceId = sources.first.id;
      }

      await loadQuotesForSelected();
    } on ApiException catch (e) {
      _setError(e);
    } catch (e) {
      _setError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setRefMes(DateTime mes) async {
    selectedRefMes = _monthStart(mes);
    notifyListeners();
    await loadQuotesForSelected();
  }

  void setSource(int? sourceId) {
    selectedSourceId = sourceId;
    notifyListeners();
    // não dispara load automático para não ficar “pesado” a cada clique,
    // mas pode chamar loadQuotesForSelected() se preferir.
  }

  Future<void> loadQuotesForSelected() async {
    if (farmId == null) return;

    _setLoading(true);
    _setError(null);
    try {
      quotes = await quotesRepo.list(
        farmId: farmId!,
        refMes: _fmtYmd(selectedRefMes),
        sourceId: selectedSourceId,
        limit: 1000,
      );

      quotes.sort((a, b) => a.quote.capturadoEm.compareTo(b.quote.capturadoEm));
    } on ApiException catch (e) {
      _setError(e);
      quotes = [];
    } catch (e) {
      _setError(e);
      quotes = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createQuote({
    required double brlPerUsd,
    String? observacao,
    DateTime? capturadoEm,
  }) async {
    if (farmId == null) return;
    if (selectedSourceId == null) {
      throw ApiException(message: 'Selecione uma fonte (source) antes de lançar a cotação.');
    }

    _setLoading(true);
    _setError(null);
    try {
      final payload = FxQuoteCreate(
        sourceId: selectedSourceId!,
        capturadoEm: (capturadoEm ?? DateTime.now()).toUtc(),
        refMes: selectedRefMes,
        brlPerUsd: brlPerUsd,
        observacao: observacao?.trim().isEmpty == true ? null : observacao?.trim(),
      );

      final created = await quotesRepo.create(
        farmId: farmId!,
        payload: payload,
      );

      // insere e mantém ordenado
      quotes = [...quotes, created];
      quotes.sort((a, b) => a.quote.capturadoEm.compareTo(b.quote.capturadoEm));
    } on ApiException catch (e) {
      _setError(e);
      rethrow;
    } catch (e) {
      _setError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ---- computed (cards) ----
  double? get lastReal {
    if (quotes.isEmpty) return null;
    return quotes.last.quote.brlPerUsd;
  }

  double? get lastModel {
    if (quotes.isEmpty) return null;
    return quotes.last.check.fxModel;
  }

  double? get lastManual {
    if (quotes.isEmpty) return null;
    return quotes.last.check.fxManual;
  }

  double? get mapePct {
    if (quotes.isEmpty) return null;
    final vals = quotes.map((e) => e.check.deltaPct.abs()).toList();
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  double? get maeAbs {
    if (quotes.isEmpty) return null;
    final vals = quotes.map((e) => e.check.deltaAbs.abs()).toList();
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  double? get maxErrPct {
    if (quotes.isEmpty) return null;
    return quotes.map((e) => e.check.deltaPct.abs()).reduce(max);
  }
}

// ---- helpers ----
DateTime _monthStart(DateTime d) => DateTime(d.year, d.month, 1);

String _fmtYmd(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
