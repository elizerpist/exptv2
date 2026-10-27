import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../debug/demo_seed_coordinator.dart';
import '../../core/assets/prepared_vector_asset_atlas.dart';
import '../../core/categories/application/category_collection_controller.dart';
import '../../core/categories/data/empty_category_repository.dart';
import '../../core/categories/data/method_channel_category_repository.dart';
import '../../core/categories/domain/category_repository.dart';
import '../../core/categories/presentation/category_avatar_palette_scope.dart';
import '../../core/financial_limits/data/method_channel_financial_limit_repository.dart';
import '../../core/financial_limits/domain/financial_limit_repository.dart';
import '../../core/design/dashboard_mode_palette.dart';
import '../../core/design/fluvi_global_appearance.dart';
import '../../core/design/fluvi_typography_scope.dart';
import '../../core/debug/debug_floating_button.dart';
import '../../core/diagnostics/fluvi_build_identity.dart';
import '../../core/diagnostics/fluvi_diagnostic_bridge.dart';
import '../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../core/diagnostics/fluvi_onscreen_diagnostics.dart';
import '../../core/demo_data/demo_data_bridge.dart';
import '../../features/manual_transactions/data/method_channel_manual_transaction_repository.dart';
import '../../features/manual_transactions/data/unavailable_manual_transaction_repository.dart';
import '../../features/manual_transactions/domain/manual_transaction_repository.dart';
import '../../features/manual_transactions/domain/manual_transaction_models.dart';
import '../../features/manual_transactions/presentation/creation_selector_sheet.dart';
import '../../features/manual_transactions/presentation/manual_transaction_editor.dart';
import '../../features/automation/data/method_channel_automation_repository.dart';
import '../../features/automation/data/unavailable_automation_repository.dart';
import '../../features/automation/domain/automation_repository.dart';
import '../../features/automation/presentation/automation_dashboard_page.dart';
import '../../features/automation/presentation/push_profile_wizard_page.dart';
import '../../features/automation/presentation/recurring_transaction_wizard_page.dart';
import '../../features/automation/presentation/ghost_manager_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/pulse/data/method_channel_pulse_repository.dart';
import '../../features/pulse/data/unavailable_pulse_repository.dart';
import '../../features/pulse/domain/pulse_repository.dart';
import '../../features/pulse/application/pulse_delivery_coordinator.dart';
import '../../features/pulse/presentation/pulse_dashboard_page.dart';
import '../../features/dashboard/application/dashboard_core_controller.dart';
import '../../features/dashboard/application/dashboard_presentation_preferences.dart';
import '../../core/preferences/data/method_channel_dashboard_presentation_preferences_store.dart';
import '../../features/dashboard/application/dashboard_core_mode_controller.dart';
import '../../features/dashboard/application/transaction_direction_controller.dart';
import '../../features/dashboard/application/dashboard_interaction_readiness.dart';
import '../../features/dashboard/application/dashboard_mode_spec.dart';
import '../../features/dashboard/application/dashboard_render_readiness_diagnostics.dart';
import '../../features/dashboard/presentation/core_dashboard.dart';
import '../../features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import '../../features/dashboard/presentation/dashboard_shell_presentation.dart';
import '../../features/dashboard/presentation/summary_pill_variant.dart';
import '../../features/dashboard/query/application/query_menu_data_controller.dart';
import '../../features/dashboard/query/application/dashboard_applied_query_facet_loader.dart';
import '../../features/dashboard/query/application/saved_query_controller.dart';
import '../../features/dashboard/query/data/dashboard_ledger_entry.dart';
import '../../features/dashboard/query/data/method_channel_query_menu_repository.dart';
import '../../features/dashboard/query/data/query_menu_repository.dart';
import '../../features/dashboard/query/domain/ledger_direction.dart';
import '../../features/dashboard/query/domain/current_ledger_query_scope.dart';
import '../../features/dashboard/query/presentation/query_menu_sheet.dart';
import '../../features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import '../../features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';
import '../../features/dashboard/runtime/data/method_channel_dashboard_data_runtime_repository.dart';
import '../../features/dashboard/time_navigation/domain/time_plane.dart';
import 'bnb03_bottom_navigation.dart';
import '../../shared/presentation/fluvi_slide_up_sheet.dart';

class _BottomNavigationSafeArea extends StatelessWidget {
  const _BottomNavigationSafeArea({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bottomInset,
          child: const ColoredBox(
            key: ValueKey('fluvi-bottom-safe-area-background'),
            color: Colors.white,
          ),
        ),
        SafeArea(top: false, child: child),
      ],
    );
  }
}

/// Root owner for the one dashboard controller lifecycle in this UI slice.
class FluviAppShell extends StatefulWidget {
  const FluviAppShell({
    super.key,
    this.mode = DashboardModeSpec.balance,
    this.dashboardRepository,
    this.categoryRepository,
    this.financialLimitRepository,
    this.queryRepository,
    this.manualTransactionRepository,
    this.automationRepository,
    this.automationPermissionRepository,
    this.pulseRepository,
    this.initialDate,
    this.initialPlane = TimePlane.month,
    this.initialRailOpen = false,
    this.initialDirection = LedgerDirection.income,
    this.initialSummaryPillVariant,
    this.shellPresentation,
  });

  final DashboardModeSpec mode;
  final DashboardDataRuntimeRepository? dashboardRepository;
  final CategoryRepository? categoryRepository;
  final FinancialLimitRepository? financialLimitRepository;
  final QueryMenuRepository? queryRepository;
  final ManualTransactionRepository? manualTransactionRepository;
  final AutomationRepository? automationRepository;
  final AutomationPermissionRepository? automationPermissionRepository;
  final PulseRepository? pulseRepository;
  final DateTime? initialDate;
  final TimePlane initialPlane;
  final bool initialRailOpen;
  final LedgerDirection initialDirection;
  final SummaryPillVariant? initialSummaryPillVariant;
  final DashboardShellPresentationController? shellPresentation;

  @override
  State<FluviAppShell> createState() => _FluviAppShellState();
}

class _DashboardBootstrapSurface extends StatelessWidget {
  const _DashboardBootstrapSurface();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      key: ValueKey('dashboard-bootstrap-surface'),
      color: FluviVisualTokens.pageBackground,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _DashboardBootstrapFailureSurface extends StatelessWidget {
  const _DashboardBootstrapFailureSurface({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const ValueKey('dashboard-bootstrap-failure-surface'),
    color: FluviVisualTokens.pageBackground,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A dashboard adatai nem tölthetők be.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('dashboard-bootstrap-retry'),
              onPressed: onRetry,
              child: const Text('Újrapróbálás'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FluviAppShellState extends State<FluviAppShell>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final DashboardCoreController _controller;
  late final DashboardCoreModeController _modeController;
  late final DashboardPresentationPreferencesController
  _dashboardPresentationPreferences;
  late final DashboardInteractionReadiness _readiness;
  late final QueryMenuRepository _queryRepository;
  late final CategoryRepository _categoryRepository;
  late final CategoryCollectionController _categoryCollection;
  FinancialLimitRepository? _financialLimitRepository;
  late final QueryMenuDataController _queryData;
  late final DashboardAppliedQueryFacetLoader _appliedQueryFacets;
  late final SavedQueryController _savedQueries;
  late final DashboardShellPresentationController _shellPresentation;
  late final bool _ownsShellPresentation;
  late final DashboardHeaderVisualController _headerVisualController;
  late final ManualTransactionRepository _manualTransactionRepository;
  late final AutomationRepository _automationRepository;
  late final AutomationPermissionRepository _automationPermissionRepository;
  late final PulseRepository _pulseRepository;
  late final PulseDeliveryCoordinator _pulseDelivery;
  late final bool _seedDemo;
  Future<void>? _startupFlow;
  int _startupAttemptGeneration = 0;
  int? _activeStartupAttemptGeneration;
  int? _lastStartupReadyAttemptGeneration;
  int? _lastStartupFailureAttemptGeneration;
  StreamSubscription? _diagnosticSubscription;
  StreamSubscription<Object?>? _pulseCoreRevisionSubscription;
  Bnb03Item _selectedNavigationItem = Bnb03Item.home;
  double? _devicePixelRatio;
  PreparedLogBoxRasterBank? _preparedLogBoxRasters;
  bool _queryMenuOpen = false;
  bool _queryApplying = false;
  bool _pulseInitialized = false;
  bool _appActive = true;
  bool _headerInteractionActive = false;
  bool _routeObstructed = false;

  @override
  void initState() {
    super.initState();
    _headerVisualController = DashboardHeaderVisualController(vsync: this);
    _dashboardPresentationPreferences =
        DashboardPresentationPreferencesController(
          store: MethodChannelDashboardPresentationPreferencesStore(),
        );
    unawaited(_dashboardPresentationPreferences.restore());
    _seedDemo = !kIsWeb && const bool.fromEnvironment('FLUVI_SEED_DEMO');
    final repository = kIsWeb
        ? const EmptyDashboardDataRuntimeRepository()
        : widget.dashboardRepository ??
              MethodChannelDashboardDataRuntimeRepository();
    _controller = DashboardCoreController(
      dataRepository: repository,
      initialDate: widget.initialDate,
      initialPlane: widget.initialPlane,
      initialRailOpen: widget.initialRailOpen,
      initialDirection: widget.initialDirection,
      seedReady: !_seedDemo,
    );
    _modeController = DashboardCoreModeController(
      initialMode: widget.mode,
      onModeSwitched: _recordCoreModeSwitch,
    );
    _queryRepository =
        widget.queryRepository ??
        (kIsWeb
            ? const EmptyQueryMenuRepository()
            : MethodChannelQueryMenuRepository());
    _categoryRepository =
        widget.categoryRepository ??
        (kIsWeb
            ? const EmptyCategoryRepository()
            : MethodChannelCategoryRepository());
    _manualTransactionRepository =
        widget.manualTransactionRepository ??
        (kIsWeb
            ? const UnavailableManualTransactionRepository()
            : MethodChannelManualTransactionRepository());
    _pulseRepository =
        widget.pulseRepository ??
        (kIsWeb
            ? const UnavailablePulseRepository()
            : MethodChannelPulseRepository());
    _pulseDelivery = PulseDeliveryCoordinator(repository: _pulseRepository);
    WidgetsBinding.instance.addObserver(this);
    _automationRepository =
        widget.automationRepository ??
        (kIsWeb
            ? const UnavailableAutomationRepository()
            : MethodChannelAutomationRepository());
    _automationPermissionRepository =
        widget.automationPermissionRepository ??
        (kIsWeb
            ? const UnavailableAutomationPermissionRepository()
            : MethodChannelAutomationPermissionRepository());
    _categoryCollection = CategoryCollectionController(
      repository: _categoryRepository,
      onDiagnostic: _recordCategoryCollectionDiagnostic,
    );
    _financialLimitRepository = kIsWeb
        ? null
        : widget.financialLimitRepository ??
              MethodChannelFinancialLimitRepository();
    _queryData = QueryMenuDataController(repository: _queryRepository);
    _appliedQueryFacets = DashboardAppliedQueryFacetLoader(
      currentQuery: _controller.currentQuery,
      directionChanges: _controller.transactionDirection,
      scopeChanges: _controller.visibleFrames,
      activeDirection: () =>
          _controller.transactionDirection.direction ==
              TransactionDirection.income
          ? LedgerDirection.income
          : LedgerDirection.expense,
      activeScopeForDirection: _controller.mindAmountDomainScopeFor,
      repository: _queryRepository,
    );
    _savedQueries = SavedQueryController(repository: _queryRepository);
    _shellPresentation =
        widget.shellPresentation ?? DashboardShellPresentationController();
    _ownsShellPresentation = widget.shellPresentation == null;
    _readiness = DashboardInteractionReadiness(
      diagnostics: _controller.renderReadinessDiagnostics,
      buildInitialFrame: () async {
        final timer = Stopwatch()..start();
        _controller.renderReadinessDiagnostics.recordFirstUseStarted(
          subsystem: DashboardRenderSubsystem.viewportPayload,
          queryKey: 'bootstrap',
          entryCount: 0,
          railCritical: false,
        );
        try {
          final frame = await _controller.bootstrap();
          timer.stop();
          _controller.renderReadinessDiagnostics.recordFirstUseCompleted(
            subsystem: DashboardRenderSubsystem.viewportPayload,
            queryKey: frame.queryKey.value,
            entryCount: frame.logBox.entryCount,
            durationMicros: timer.elapsedMicroseconds,
          );
          return frame;
        } on Object catch (error) {
          timer.stop();
          _controller.renderReadinessDiagnostics.recordFirstUseFailed(
            subsystem: DashboardRenderSubsystem.viewportPayload,
            queryKey: 'bootstrap',
            entryCount: 0,
            durationMicros: timer.elapsedMicroseconds,
            error: error,
          );
          rethrow;
        }
      },
      prepareRenderCriticalResources: (devicePixelRatio) async {
        final frame = _controller.visibleFrames.value;
        final timer = Stopwatch()..start();
        _controller.renderReadinessDiagnostics.recordFirstUseStarted(
          subsystem: DashboardRenderSubsystem.categoryRaster,
          queryKey: frame?.queryKey.value ?? 'bootstrap',
          entryCount: frame?.logBox.entryCount ?? 0,
          railCritical: false,
        );
        try {
          final atlas = PreparedVectorAssetAtlas.instance;
          await atlas.prepare();
          await atlas.prepareLogBoxRasters(devicePixelRatio: devicePixelRatio);
          _preparedLogBoxRasters = atlas.logBoxRasterBankFor(devicePixelRatio);
          timer.stop();
          _controller.renderReadinessDiagnostics.recordFirstUseCompleted(
            subsystem: DashboardRenderSubsystem.categoryRaster,
            queryKey: frame?.queryKey.value ?? 'bootstrap',
            entryCount: frame?.logBox.entryCount ?? 0,
            durationMicros: timer.elapsedMicroseconds,
          );
        } on Object catch (error) {
          timer.stop();
          _controller.renderReadinessDiagnostics.recordFirstUseFailed(
            subsystem: DashboardRenderSubsystem.categoryRaster,
            queryKey: frame?.queryKey.value ?? 'bootstrap',
            entryCount: frame?.logBox.entryCount ?? 0,
            durationMicros: timer.elapsedMicroseconds,
            error: error,
          );
          rethrow;
        }
      },
    );
    _readiness.addListener(_onReadinessChanged);
    if (!kIsWeb) {
      _pulseCoreRevisionSubscription =
          const EventChannel(
            'com.fluvi/dashboard_core_revision_stream',
          ).receiveBroadcastStream().listen((_) {
            // Delivery has no independent financial cache. A real financial Core
            // revision is a fresh, generation-protected opportunity to inspect
            // the current A–D frame; a delivery-table write never emits here.
            _syncPulseDeliverySurface();
            unawaited(_pulseDelivery.reconcile());
          });
    }
    if (kFluviOnscreenDiagnosticsEnabled && !kIsWeb) {
      _diagnosticSubscription = FluviDiagnosticBridge().watch().listen(
        FluviDiagnosticLogger.log,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _syncPulseDeliverySurface(),
    );
  }

  Future<void> _openCreationSelector() async {
    _routeObstructed = true;
    _syncPulseDeliverySurface();
    try {
      final direction =
          _controller.transactionDirection.direction ==
              TransactionDirection.income
          ? LedgerDirection.income
          : LedgerDirection.expense;
      final action = await showCreationSelectorSheet(
        context,
        direction: direction,
      );
      if (!mounted || action == null) return;
      if (action == CreationSelectorAction.pushProfile) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => PushProfileWizardPage(
              repository: _automationRepository,
              permissions: _automationPermissionRepository,
            ),
          ),
        );
        return;
      }
      if (action == CreationSelectorAction.recurringTransaction) {
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            fullscreenDialog: true,
            builder: (_) => RecurringTransactionWizardPage(
              repository: _automationRepository,
              manualRepository: _manualTransactionRepository,
              categories: _categoryCollection.value,
              initialDirection: direction,
            ),
          ),
        );
        return;
      }
      await Navigator.of(context).push<ManualTransactionSaveResult>(
        PageRouteBuilder<ManualTransactionSaveResult>(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ManualTransactionEditor.create(
                repository: _manualTransactionRepository,
                categories: _categoryCollection.value,
                direction: direction,
                onSaved: _acceptManualTransactionSave,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
        ),
      );
    } finally {
      if (mounted) {
        _routeObstructed = false;
        _syncPulseDeliverySurface();
      }
    }
  }

  Future<void> _openEditTransaction(String entryId) async {
    _routeObstructed = true;
    _syncPulseDeliverySurface();
    try {
      if (entryId.startsWith('ghost:')) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => GhostManagerPage(
              repository: _automationRepository,
              manualRepository: _manualTransactionRepository,
              categories: _categoryCollection.value,
              initialOccurrenceId: entryId.substring('ghost:'.length),
              onOpenLedgerEntry: _openEditTransaction,
            ),
          ),
        );
        return;
      }
      await Navigator.of(context).push<ManualTransactionSaveResult>(
        PageRouteBuilder<ManualTransactionSaveResult>(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ManualTransactionEditor.edit(
                repository: _manualTransactionRepository,
                categories: _categoryCollection.value,
                entryId: entryId,
                onSaved: _acceptManualTransactionSave,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
        ),
      );
    } finally {
      if (mounted) {
        _routeObstructed = false;
        _syncPulseDeliverySurface();
      }
    }
  }

  Future<void> _acceptManualTransactionSave(
    ManualTransactionSaveResult saved,
  ) async {
    final coreRevision = saved.globalCoreRevision;
    if (coreRevision == null || coreRevision <= 0) return;
    final category = saved.effectiveCategory;
    final entry = saved.entry;
    final partner = saved.partner;
    final patch = category == null
        ? null
        : DashboardLedgerVisualPatch(
            entryId: entry.entryId,
            partnerId: entry.partnerId,
            direction: entry.direction.name,
            amountMinor: entry.amountScaled100,
            bookedLocalEpochDay: entry.bookedLocalEpochDay,
            bookedLocalTimeMinutes: entry.bookedLocalTimeMinutes,
            partnerDisplayName: partner.displayName,
            partnerAvatarCategoryId: partner.defaultCategoryId,
            partnerAvatarColorId: partner.categoryColorId,
            partnerAvatarIconId: partner.categoryIconId,
            categoryId: category.id,
            categoryDisplayName: category.name,
            categoryColorId: category.colorId,
            categoryIconId: category.iconId,
            assignmentMode: entry.categoryAssignmentMode.name,
            entryRevision: entry.revision,
          );
    await _controller.acceptKnownCoreRevision(coreRevision, visualPatch: patch);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ratio = View.of(context).devicePixelRatio;
    final previous = _devicePixelRatio;
    _devicePixelRatio = ratio;
    if (previous == null) unawaited(_startDashboard());
  }

  Future<void> _startDashboard() {
    final existing = _startupFlow;
    if (existing != null) return existing;
    final attemptGeneration = ++_startupAttemptGeneration;
    _activeStartupAttemptGeneration = attemptGeneration;
    late final Future<void> operation;
    operation = _runDashboardStartup(attemptGeneration).whenComplete(() {
      if (identical(_startupFlow, operation)) _startupFlow = null;
      if (_activeStartupAttemptGeneration == attemptGeneration) {
        _activeStartupAttemptGeneration = null;
      }
    });
    _startupFlow = operation;
    return operation;
  }

  Future<void> _runDashboardStartup(int attemptGeneration) async {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'DASHBOARD_STARTUP_ATTEMPT_STARTED',
        scope: 'attemptGeneration=$attemptGeneration stage=bootstrap',
        coreRevision: _readiness.frame?.coreRevision,
      ),
    );
    if (_seedDemo) {
      try {
        await DemoSeedCoordinator(
          bridge: const MethodChannelDemoDataBridge(),
          timeNavigation: _controller.navigation,
          preparedYearWindow:
              _controller.dataRuntime.requestTemplate.preparedYearWindow,
        ).seedAndNavigate();
        _controller.markSeedCommitted();
      } on Object catch (error) {
        debugPrint('[FluviDemoSeed] failed: $error');
        _recordStartupStageFailure(
          attemptGeneration: attemptGeneration,
          stage: 'demoSeed',
          error: error,
        );
        _readiness.fail(error);
        return;
      }
    }
    try {
      await _categoryCollection.start();
    } on Object catch (error) {
      _recordStartupStageFailure(
        attemptGeneration: attemptGeneration,
        stage: 'categoryCollection',
        error: error,
      );
      _readiness.fail(error);
      return;
    }
    await _readiness.start(
      devicePixelRatio:
          _devicePixelRatio ??
          WidgetsBinding
              .instance
              .platformDispatcher
              .implicitView
              ?.devicePixelRatio ??
          1,
    );
  }

  void _onReadinessChanged() {
    _syncPulseDeliverySurface();
    if (_readiness.isReady) {
      _controller.renderReadinessDiagnostics.markReady();
      unawaited(_appliedQueryFacets.start());
      final attemptGeneration = _activeStartupAttemptGeneration;
      if (attemptGeneration != null &&
          _lastStartupReadyAttemptGeneration != attemptGeneration) {
        _lastStartupReadyAttemptGeneration = attemptGeneration;
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'DASHBOARD_STARTUP_READY',
            coreRevision: _readiness.frame?.coreRevision,
            scope:
                'attemptGeneration=$attemptGeneration '
                'stage=ready readinessTask=-',
          ),
        );
      }
      return;
    }
    if (_readiness.phase == DashboardInteractionReadinessPhase.failed) {
      final attemptGeneration = _activeStartupAttemptGeneration;
      if (attemptGeneration == null ||
          _lastStartupFailureAttemptGeneration == attemptGeneration) {
        return;
      }
      _recordStartupStageFailure(
        attemptGeneration: attemptGeneration,
        stage: 'dashboardReadiness',
        error:
            _readiness.error ??
            StateError('Unknown dashboard startup failure.'),
        readinessTask: _readiness.failedTask,
      );
    }
  }

  void _recordStartupStageFailure({
    required int attemptGeneration,
    required String stage,
    required Object error,
    DashboardReadinessTask? readinessTask,
  }) {
    if (_lastStartupFailureAttemptGeneration == attemptGeneration) return;
    _lastStartupFailureAttemptGeneration = attemptGeneration;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'DASHBOARD_STARTUP_STAGE_FAILED',
        coreRevision: _readiness.frame?.coreRevision,
        error: '${error.runtimeType}: $error',
        scope:
            'attemptGeneration=$attemptGeneration stage=$stage '
            'readinessTask=${readinessTask?.name ?? '-'}',
      ),
    );
  }

  @override
  void didUpdateWidget(covariant FluviAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.mode, widget.mode)) {
      _modeController.setProgrammaticMode(widget.mode);
    }
  }

  void _recordCoreModeSwitch(DashboardCoreModeSwitchEvent event) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'CORE_MODE_SWITCHED',
        direction: event.direction.name,
        scope:
            'fromMode=${event.fromMode.mode.name} '
            'toMode=${event.toMode.mode.name}',
      ),
    );
  }

  void _recordCategoryCollectionDiagnostic(
    CategoryCollectionDiagnosticEvent event,
  ) {
    final stage = switch (event.stage) {
      CategoryCollectionDiagnosticStage.loadStarted =>
        'CATEGORY_COLLECTION_LOAD_STARTED',
      CategoryCollectionDiagnosticStage.ready => 'CATEGORY_COLLECTION_READY',
      CategoryCollectionDiagnosticStage.failed => 'CATEGORY_COLLECTION_FAILED',
    };
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: stage,
        entryCount: event.categoryCount,
        durationMs: event.durationMs,
        error: event.error?.toString(),
      ),
    );
  }

  void _recordBudgetCategoryRailInputUpdated(int categoryCount) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_CATEGORY_RAIL_INPUT_UPDATED',
        entryCount: categoryCount,
      ),
    );
  }

  String _physicalRailReport() {
    final report = _controller.exportPhysicalRailReport();
    return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      ...report,
      'buildIdentity': <String, Object?>{
        'mode': kProfileMode ? 'profile' : (kDebugMode ? 'debug' : 'release'),
        'purpose': kFluviBuildPurpose.diagnosticLabel,
        'entrypoint': kFluviBuildPurpose.entrypoint,
        'automatedScenarioRunnerPresent': kFluviAutomatedScenarioRunnerPresent,
        'automatedInputDriverActive': kFluviAutomatedInputDriverActive,
        'commit': const String.fromEnvironment(
          'FLUVI_BUILD_COMMIT',
          defaultValue: 'unknown',
        ),
      },
      'interactionReadiness': _readiness.report(),
      'diagnosticCapture': FluviDiagnosticLogger.captureReport(),
    });
  }

  Map<String, Object?> _diagnosticStatus() => <String, Object?>{
    ..._controller.onscreenDiagnosticStatus(),
    'build mode': kProfileMode ? 'profile' : (kDebugMode ? 'debug' : 'release'),
    'build purpose': kFluviBuildPurpose.diagnosticLabel,
    'entrypoint': kFluviBuildPurpose.entrypoint,
    'commit': const String.fromEnvironment(
      'FLUVI_BUILD_COMMIT',
      defaultValue: 'unknown',
    ),
    'automated scenario runner': kFluviAutomatedScenarioRunnerPresent,
    'automated input driver': kFluviAutomatedInputDriverActive,
    'readiness': _readiness.phase.name,
    'capture': <String, Object?>{
      'id': FluviDiagnosticLogger.captureId,
      'active': FluviDiagnosticLogger.captureActive,
      'frozen': FluviDiagnosticLogger.captureFrozen,
    },
    'last error': _readiness.error?.toString() ?? 'none',
  };

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _diagnosticSubscription?.cancel();
    _diagnosticSubscription = null;
    _pulseCoreRevisionSubscription?.cancel();
    _pulseCoreRevisionSubscription = null;
    _readiness.removeListener(_onReadinessChanged);
    _readiness.dispose();
    _categoryCollection.dispose();
    _appliedQueryFacets.dispose();
    _queryData.dispose();
    _savedQueries.dispose();
    if (_ownsShellPresentation) {
      _shellPresentation.dispose();
    }
    _dashboardPresentationPreferences.dispose();
    _headerVisualController.dispose();
    _pulseDelivery.dispose();
    _modeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _pulseDelivery.appLifecycleChanged(state);
    _syncPulseDeliverySurface();
  }

  void _syncPulseDeliverySurface() {
    if (!mounted) return;
    final ledgerVisible =
        _selectedNavigationItem == Bnb03Item.home && _readiness.isInteractive;
    _pulseDelivery.updateSurface(
      appActive: _appActive,
      ledgerVisible: ledgerVisible,
      headerVisible: ledgerVisible,
      unobstructed: !_queryMenuOpen && !_queryApplying && !_routeObstructed,
      interactionIdle: !_headerInteractionActive,
      headerLayoutSupported: true,
    );
  }

  void _onHeaderInteractionChanged(bool active) {
    if (_headerInteractionActive == active) return;
    _headerInteractionActive = active;
    _syncPulseDeliverySurface();
  }

  Future<void> _openPulseFromHeader() async {
    final presentation = _pulseDelivery.presentation;
    await _pulseDelivery.confirmVisibleTap();
    if (!mounted) return;
    _routeObstructed = true;
    _syncPulseDeliverySurface();
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => PulseDashboardPage(
            repository: _pulseRepository,
            fullscreen: true,
            headerStory: presentation?.story,
            headerDeliveryKey: presentation?.deliveryKey,
          ),
        ),
      );
    } finally {
      if (mounted) {
        _routeObstructed = false;
        _syncPulseDeliverySurface();
      }
    }
  }

  void _openQueryMenu() {
    if (!_readiness.isInteractive) return;
    final editingDirection =
        _controller.presentation.navigation.state.parentQueryScope.direction;
    _controller.queryComposer.open(editingDirection);
    final draft = _controller.queryComposer.draft;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_MENU_OPENED',
        queryKey: draft.key.value,
        direction: draft.direction.name,
        scope:
            'dashboardDirection=${_controller.transactionDirection.direction.name} '
            'presentationDirection='
            '${_controller.presentation.navigation.state.parentQueryScope.direction.name} '
            'editingDirection=${editingDirection.name} '
            'incomeAppliedQueryKey='
            '${_controller.currentQuery.scopeFor(LedgerDirection.income).key.value} '
            'expenseAppliedQueryKey='
            '${_controller.currentQuery.scopeFor(LedgerDirection.expense).key.value} '
            'draftDirection=${draft.direction.name}',
      ),
    );
    unawaited(_queryData.refresh(draft));
    unawaited(
      _controller.prepareQueryDraft(
        draft,
        composerIdentity: _controller.queryComposer.applyIdentity,
      ),
    );
    setState(() {
      _queryMenuOpen = true;
      _queryApplying = false;
    });
    _syncPulseDeliverySurface();
  }

  void _closeQueryMenu() {
    _controller.notifyQuerySheetDismissalRequested();
    _controller.discardQueryDraftCandidate(reason: 'sheetClosed');
    _controller.queryComposer.closeWithoutApply();
    setState(() {
      _queryMenuOpen = false;
      _queryApplying = false;
    });
    _syncPulseDeliverySurface();
  }

  void _queryDraftChanged(CurrentLedgerQueryScope draft) {
    unawaited(_queryData.refresh(draft));
    unawaited(
      _controller.prepareQueryDraft(
        draft,
        composerIdentity: _controller.queryComposer.applyIdentity,
      ),
    );
  }

  void _clearQueryDraft() {
    final draft = _controller.queryComposer.draft;
    final cleared = CurrentLedgerQueryScope(
      direction: draft.direction,
      timeScope: draft.timeScope,
    );
    _controller.queryComposer.updateDraft(scope: cleared);
    _queryDraftChanged(cleared);
  }

  Future<void> _applyQuery(CurrentLedgerQueryScope draft) async {
    if (!_queryMenuOpen || _queryApplying) return;
    final composerApplyIdentity = _controller.queryComposer.applyIdentity;
    setState(() {
      _queryApplying = true;
    });
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_APPLY_ACCEPTED',
        flowId: 'session:${composerApplyIdentity.sessionId}',
        queryKey: draft.key.value,
        direction: draft.direction.name,
      ),
    );
    try {
      // The sheet's data owner already owns the exact in-flight facet request
      // started by draft editing. Join it while the core awaits the separately
      // staged candidate instead of snapshotting a transient null and later
      // throwing away a result that became ready before publication.
      final presentation = await _queryData.presentationForAcceptedApply(draft);
      final published = await _controller.applyQuery(
        draft,
        facetPresentation: presentation.data,
        facetPresentationSource: presentation.source.name,
        facetPresentationExactScopeMatch: presentation.isExact,
        composerApplyIdentity: composerApplyIdentity,
      );
      if (published) {
        if (!mounted) return;
        setState(() {
          _queryMenuOpen = false;
          _queryApplying = false;
        });
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'QUERY_SHEET_DISMISS_REQUESTED',
            flowId: 'session:${composerApplyIdentity.sessionId}',
            queryKey: draft.key.value,
            direction: draft.direction.name,
          ),
        );
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'QUERY_SHEET_CLOSED_AFTER_APPLY',
            queryKey: _controller.currentQuery
                .scopeFor(draft.direction)
                .key
                .value,
            direction: draft.direction.name,
            scope:
                'visibleQueryKey='
                '${_controller.visibleFrames.value?.queryKey.value ?? 'none'}',
          ),
        );
      }
    } on Object catch (error) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'QUERY_APPLY_COMPLETED',
          queryKey: draft.key.value,
          direction: draft.direction.name,
          scope: 'published=false',
          error: '$error',
        ),
      );
    } finally {
      if (mounted && _queryMenuOpen) {
        setState(() => _queryApplying = false);
        _syncPulseDeliverySurface();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DashboardHeaderVisualTuning>(
      valueListenable: _headerVisualController.tuning,
      builder: (context, tuning, _) => CategoryAvatarColorProfileScope(
        profile: tuning.globalAppearance.avatarColorProfile,
        child: FluviTypographyScope(
          profile: tuning.globalAppearance.typography,
          child: Theme(
            data: tuning.globalAppearance.typography.applyToTheme(
              Theme.of(context),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Scaffold(
                  key: const ValueKey('fluvi-app-shell'),
                  // The body intentionally reaches the shell-owned bottom navigation.
                  // Scaffold then publishes that measured obstruction through the
                  // body's MediaQuery; the LogBox uses it only as terminal scroll
                  // content, never by shortening its viewport.
                  extendBody: true,
                  backgroundColor: FluviVisualTokens.pageBackground,
                  body: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedBuilder(
                        animation: _readiness,
                        builder: (context, _) {
                          final mountsDashboard = _readiness.mountsDashboard;
                          final dashboard = Stack(
                            fit: StackFit.expand,
                            children: [
                              if (mountsDashboard)
                                AbsorbPointer(
                                  key: const ValueKey(
                                    'dashboard-interaction-readiness-gate',
                                  ),
                                  absorbing: !_readiness.isInteractive,
                                  child: CoreDashboard(
                                    key: const ValueKey('ready-core-dashboard'),
                                    controller: _controller,
                                    modeController: _modeController,
                                    categoryCollection: _categoryCollection,
                                    categoryRepository: _categoryRepository,
                                    financialLimitRepository:
                                        _financialLimitRepository,
                                    onBudgetCategoryInputUpdated:
                                        _recordBudgetCategoryRailInputUpdated,
                                    onEditEntry: _openEditTransaction,
                                    onOpenQueryMenu: _openQueryMenu,
                                    preparedLogBoxRasters:
                                        _preparedLogBoxRasters!,
                                    shellPresentation: _shellPresentation,
                                    headerVisualController:
                                        _headerVisualController,
                                    dashboardPresentationPreferences:
                                        _dashboardPresentationPreferences,
                                    pulseDeliveryCoordinator: _pulseDelivery,
                                    onOpenPulse: _openPulseFromHeader,
                                    onHeaderInteractionChanged:
                                        _onHeaderInteractionChanged,
                                    mindQueryFacetLoader: _appliedQueryFacets,
                                    initialSummaryPillVariant:
                                        widget.initialSummaryPillVariant ??
                                        SummaryPillVariant.segmented,
                                    onLogBoxWarmupSurfaceAttached:
                                        (viewportId) {
                                          _readiness.markLogBoxSurfaceAttached(
                                            viewportId: viewportId,
                                          );
                                        },
                                    onLogBoxWarmupSurfaceLaidOut: (viewportId) {
                                      _readiness.markLogBoxSurfaceLaidOut(
                                        viewportId: viewportId,
                                      );
                                    },
                                    onLogBoxWarmupTextLayoutsPrepared:
                                        (viewportId) {
                                          _readiness
                                              .markLogBoxTextLayoutsPrepared(
                                                viewportId: viewportId,
                                              );
                                        },
                                    onLogBoxWarmupError: (error, _) {
                                      _readiness.fail(error);
                                    },
                                    initialLogBoxReadinessActive:
                                        !_readiness.isReady,
                                  ),
                                )
                              else if (_readiness.phase ==
                                  DashboardInteractionReadinessPhase.failed)
                                _DashboardBootstrapFailureSurface(
                                  onRetry: () => unawaited(_startDashboard()),
                                )
                              else
                                const _DashboardBootstrapSurface(),
                              if (mountsDashboard && !_readiness.isReady)
                                const _DashboardBootstrapSurface(),
                            ],
                          );
                          return IndexedStack(
                            index: switch (_selectedNavigationItem) {
                              Bnb03Item.search => 1,
                              Bnb03Item.cart => 2,
                              Bnb03Item.profile => 3,
                              _ => 0,
                            },
                            children: [
                              dashboard,
                              AutomationDashboardPage(
                                repository: _automationRepository,
                                permissions: _automationPermissionRepository,
                                manualRepository: _manualTransactionRepository,
                                categories: _categoryCollection.value,
                                direction:
                                    _controller
                                            .transactionDirection
                                            .direction ==
                                        TransactionDirection.income
                                    ? LedgerDirection.income
                                    : LedgerDirection.expense,
                                onOpenLedgerEntry: _openEditTransaction,
                              ),
                              _pulseInitialized
                                  ? PulseDashboardPage(
                                      repository: _pulseRepository,
                                    )
                                  : const SizedBox.shrink(),
                              SettingsPage(
                                permissions: _automationPermissionRepository,
                                dashboardPresentationPreferences:
                                    _dashboardPresentationPreferences,
                              ),
                            ],
                          );
                        },
                      ),
                      if (kFluviOnscreenDiagnosticsEnabled)
                        DebugFloatingButton(
                          physicalReportProvider: _physicalRailReport,
                          diagnosticStatusProvider: _diagnosticStatus,
                        ),
                    ],
                  ),
                  bottomNavigationBar: _BottomNavigationSafeArea(
                    child:
                        ValueListenableBuilder<
                          DashboardShellPresentationSettings
                        >(
                          valueListenable: _shellPresentation,
                          builder: (context, settings, _) => AnimatedBuilder(
                            animation: _controller.transactionDirection,
                            builder: (context, _) => Bnb03BottomNavigation(
                              selected: _selectedNavigationItem,
                              edgeShape: settings.bottomNavEdgeShape,
                              topBorder: settings.bottomNavTopBorder,
                              layoutStyle: settings.bottomNavLayoutStyle,
                              transactionDirection:
                                  _controller.transactionDirection.direction,
                              directionColorProfile:
                                  tuning.globalAppearance.directionColorProfile,
                              fabIconPresentation:
                                  tuning.globalAppearance.fabIconPresentation,
                              fabVectorPrimaryArgb:
                                  tuning.globalAppearance.fabVectorPrimaryArgb,
                              fabVectorHighlightArgb: tuning
                                  .globalAppearance
                                  .fabVectorHighlightArgb,
                              onChanged: (item) {
                                if (item == Bnb03Item.shop) {
                                  _openCreationSelector();
                                  return;
                                }
                                if (item == Bnb03Item.cart) {
                                  _pulseInitialized = true;
                                }
                                setState(() => _selectedNavigationItem = item);
                                _syncPulseDeliverySurface();
                              },
                            ),
                          ),
                        ),
                  ),
                ),
                FluviSlideUpSheet(
                  isOpen: _queryMenuOpen,
                  onDismiss: _closeQueryMenu,
                  onDismissTransitionStarted:
                      _controller.notifyQuerySheetReverseTransitionStarted,
                  onDismissTransitionCompleted:
                      _controller.notifyQuerySheetDismissed,
                  stickyFooter: QueryMenuStickyFooter(
                    composer: _controller.queryComposer,
                    dataController: _queryData,
                    applying: _queryApplying,
                    onApply: _applyQuery,
                    onClear: _clearQueryDraft,
                  ),
                  child: QueryMenuSheet(
                    composer: _controller.queryComposer,
                    dataController: _queryData,
                    savedQueries: _savedQueries,
                    onDraftChanged: _queryDraftChanged,
                    onClose: _closeQueryMenu,
                    onSavedPanelRequested: () => unawaited(
                      _savedQueries.refresh(
                        _controller.queryComposer.draft.direction,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
