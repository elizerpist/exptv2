import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart' as core_theme;
import '../../../core/theme/app_colors.dart';
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
  final _sheetBridge = NativeImeSheetBridge();
  final _nativeBridge = NativeBridge();
  late final TransactionStore _store = TransactionStore(
    TransactionRepository(_nativeBridge),
  );
  var _mode = 'probe';
  ExpenseTheme? _expenseTheme;
  Object? _error;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final stopwatch = Stopwatch()..start();
      final state = await _sheetBridge.getInitialState();
      final mode = state['mode']?.toString() ?? 'probe';
      final type = TransactionTypeX.fromAny(state['type']);
      if (mode != 'addTransaction') {
        if (mounted) {
          setState(() {
            _mode = mode;
            _loaded = true;
          });
        }
        return;
      }

      final settingsFuture = _nativeBridge.expenseLoadSettings();
      final categoriesFuture = _nativeBridge.expenseListCategories();
      final settings = await settingsFuture;
      final categories = await categoriesFuture;
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
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Material(
        color: AppColors.white,
        child: Center(child: CircularProgressIndicator()),
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
