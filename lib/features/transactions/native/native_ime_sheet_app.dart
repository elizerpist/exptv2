import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart' as core_theme;
import '../../../core/debug/debug_console.dart';
import '../../../services/native_bridge.dart';
import '../../../services/native_ime_sheet_bridge.dart';
import '../../diagnostics/native_ime_sheet_probe.dart';
import '../../settings/models/app_theme_settings.dart';
import '../../settings/theme/expense_theme.dart';
import '../data/transaction_repository.dart';
import '../models/transaction_category.dart';
import '../state/transaction_store.dart';
import '../widgets/add_transaction_sheet.dart';

class NativeImeSheetApp extends StatelessWidget {
  const NativeImeSheetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: core_theme.AppTheme.light,
      home: const _NativeImeSheetBootstrap(),
    );
  }
}

class _NativeImeSheetBootstrap extends StatefulWidget {
  const _NativeImeSheetBootstrap();

  @override
  State<_NativeImeSheetBootstrap> createState() =>
      _NativeImeSheetBootstrapState();
}

class _NativeImeSheetBootstrapState extends State<_NativeImeSheetBootstrap> {
  late final NativeImeSheetBridge _sheetBridge = NativeImeSheetBridge(
    onSheetStateChanged: _handleHostStateChanged,
  );
  final _nativeBridge = NativeBridge();
  late final TransactionStore _store = TransactionStore(
    TransactionRepository(_nativeBridge),
  );
  var _mode = 'probe';
  ExpenseTheme? _expenseTheme;
  ExpenseSettingsPayload? _settings;
  List<TransactionCategory>? _categories;
  Object? _error;
  var _loaded = false;
  var _readyRevision = 0;
  var _notifiedReadyRevision = -1;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _sheetBridge.dispose();
    _store.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final stopwatch = Stopwatch()..start();
      final state = await _sheetBridge.getInitialState();
      final mode = state['mode']?.toString() ?? 'probe';
      final type = TransactionTypeX.fromAny(state['type']);
      await _applyHostState(mode: mode, type: type, stopwatch: stopwatch);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loaded = true;
        _readyRevision += 1;
      });
      _scheduleContentReadyIfNeeded();
    }
  }

  Future<void> _handleHostStateChanged(Map<dynamic, dynamic> state) async {
    final stopwatch = Stopwatch()..start();
    await _applyHostState(
      mode: state['mode']?.toString() ?? _mode,
      type: TransactionTypeX.fromAny(state['type']),
      stopwatch: stopwatch,
    );
  }

  Future<void> _applyHostState({
    required String mode,
    required TransactionType type,
    required Stopwatch stopwatch,
  }) async {
    try {
      if (mode != 'addTransaction') {
        if (mounted) {
          setState(() {
            _mode = mode;
            _loaded = true;
            _readyRevision += 1;
          });
          _scheduleContentReadyIfNeeded();
        }
        return;
      }

      final settingsFuture = _settings == null
          ? _nativeBridge.expenseLoadSettings()
          : null;
      final categoriesFuture = _categories == null
          ? _nativeBridge.expenseListCategories()
          : null;
      final settings = _settings ?? await settingsFuture!;
      final categories = _categories ?? await categoriesFuture!;
      _settings = settings;
      _categories = categories;
      _store.startAddTransactionForm(categories: categories, type: type);
      DebugConsole.log(
        '[NativeImeSheet] AddTransaction bootstrap lightweight '
        'categories=${categories.length} elapsed=${stopwatch.elapsedMilliseconds}ms',
      );
      if (!mounted) return;
      setState(() {
        _mode = mode;
        _expenseTheme = ExpenseTheme.fromSettings(settings.themeSettings);
        _loaded = true;
        _readyRevision += 1;
      });
      _scheduleContentReadyIfNeeded();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loaded = true;
        _readyRevision += 1;
      });
      _scheduleContentReadyIfNeeded();
    }
  }

  void _scheduleContentReadyIfNeeded() {
    final revision = _readyRevision;
    if (_notifiedReadyRevision == revision) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _notifiedReadyRevision == revision) return;
      _notifiedReadyRevision = revision;
      DebugConsole.log(
        '[NativeImeSheet] content ready mode=$_mode revision=$revision',
      );
      unawaited(_sheetBridge.notifyContentReady());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Material(
        color: Colors.transparent,
        child: SizedBox.shrink(),
      );
    }
    if (_error != null) {
      return Material(
        color: Colors.transparent,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Text('Native sheet hiba: $_error'),
        ),
      );
    }
    if (_mode != 'addTransaction') {
      return const NativeImeSheetProbe();
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: AddTransactionSheet(
        store: _store,
        visible: true,
        nativeHostMode: true,
        expenseTheme:
            _expenseTheme ??
            ExpenseTheme.fromSettings(AppThemeSettings.defaults()),
        onClose: () => unawaited(_sheetBridge.closeSheet()),
        onSaved: _sheetBridge.notifyTransactionCommitted,
        reloadAfterSave: false,
      ),
    );
  }
}
