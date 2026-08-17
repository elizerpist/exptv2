import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../debug/demo_seed_coordinator.dart';
import '../../core/assets/prepared_vector_asset_atlas.dart';
import '../../core/design/dashboard_mode_palette.dart';
import '../../core/debug/debug_floating_button.dart';
import '../../core/diagnostics/fluvi_build_identity.dart';
import '../../core/diagnostics/fluvi_diagnostic_bridge.dart';
import '../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../core/diagnostics/fluvi_onscreen_diagnostics.dart';
import '../../core/demo_data/demo_data_bridge.dart';
import '../../features/dashboard/application/dashboard_core_controller.dart';
import '../../features/dashboard/application/dashboard_core_mode_controller.dart';
import '../../features/dashboard/application/dashboard_interaction_readiness.dart';
import '../../features/dashboard/application/dashboard_mode_spec.dart';
import '../../features/dashboard/application/dashboard_render_readiness_diagnostics.dart';
import '../../features/dashboard/presentation/core_dashboard.dart';
import '../../features/dashboard/query/application/query_menu_data_controller.dart';
import '../../features/dashboard/query/application/saved_query_controller.dart';
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
import 'fluvi_fullscreen_button.dart';
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
    this.initialDate,
    this.initialPlane = TimePlane.month,
    this.initialRailOpen = false,
    this.initialDirection = LedgerDirection.income,
  });

  final DashboardModeSpec mode;
  final DashboardDataRuntimeRepository? dashboardRepository;
  final DateTime? initialDate;
  final TimePlane initialPlane;
  final bool initialRailOpen;
  final LedgerDirection initialDirection;

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

class _FluviAppShellState extends State<FluviAppShell> {
  late final DashboardCoreController _controller;
  late final DashboardCoreModeController _modeController;
  late final DashboardInteractionReadiness _readiness;
  late final QueryMenuRepository _queryRepository;
  late final QueryMenuDataController _queryData;
  late final SavedQueryController _savedQueries;
  late final bool _seedDemo;
  Future<void>? _startupFlow;
  StreamSubscription? _diagnosticSubscription;
  Bnb03Item _selectedNavigationItem = Bnb03Item.home;
  double? _devicePixelRatio;
  PreparedLogBoxRasterSet? _preparedLogBoxRasters;
  bool _queryMenuOpen = false;
  bool _queryApplying = false;

  @override
  void initState() {
    super.initState();
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
    _queryRepository = kIsWeb
        ? const EmptyQueryMenuRepository()
        : MethodChannelQueryMenuRepository();
    _queryData = QueryMenuDataController(repository: _queryRepository);
    _savedQueries = SavedQueryController(repository: _queryRepository);
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
          _preparedLogBoxRasters = atlas.logBoxRastersFor(devicePixelRatio);
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
    if (kFluviOnscreenDiagnosticsEnabled && !kIsWeb) {
      _diagnosticSubscription = FluviDiagnosticBridge().watch().listen(
        FluviDiagnosticLogger.log,
      );
    }
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
    late final Future<void> operation;
    operation = _runDashboardStartup().whenComplete(() {
      if (identical(_startupFlow, operation)) _startupFlow = null;
    });
    _startupFlow = operation;
    return operation;
  }

  Future<void> _runDashboardStartup() async {
    if (_seedDemo) {
      try {
        await DemoSeedCoordinator(
          bridge: const MethodChannelDemoDataBridge(),
          timeNavigation: _controller.navigation,
        ).seedAndNavigate();
        _controller.markSeedCommitted();
      } on Object catch (error) {
        debugPrint('[FluviDemoSeed] failed: $error');
        _readiness.fail(error);
        return;
      }
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
    if (_readiness.isReady) {
      _controller.renderReadinessDiagnostics.markReady();
    }
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
    _diagnosticSubscription?.cancel();
    _diagnosticSubscription = null;
    _readiness.removeListener(_onReadinessChanged);
    _readiness.dispose();
    _queryData.dispose();
    _savedQueries.dispose();
    _modeController.dispose();
    _controller.dispose();
    super.dispose();
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
  }

  void _closeQueryMenu() {
    _controller.notifyQuerySheetDismissalRequested();
    _controller.discardQueryDraftCandidate(reason: 'sheetClosed');
    _controller.queryComposer.closeWithoutApply();
    setState(() {
      _queryMenuOpen = false;
      _queryApplying = false;
    });
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                  return Stack(
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
                            preparedLogBoxRasters: _preparedLogBoxRasters!,
                            onLogBoxWarmupSurfaceAttached: (viewportId) {
                              _readiness.markLogBoxSurfaceAttached(
                                viewportId: viewportId,
                              );
                            },
                            onLogBoxWarmupSurfaceLaidOut: (viewportId) {
                              _readiness.markLogBoxSurfaceLaidOut(
                                viewportId: viewportId,
                              );
                            },
                            onLogBoxWarmupTextLayoutsPrepared: (viewportId) {
                              _readiness.markLogBoxTextLayoutsPrepared(
                                viewportId: viewportId,
                              );
                            },
                            onLogBoxWarmupError: (error, _) {
                              _readiness.fail(error);
                            },
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
                },
              ),
              const Positioned(
                top: 12,
                right: 12,
                child: SafeArea(bottom: false, child: FluviFullscreenButton()),
              ),
              if (kFluviOnscreenDiagnosticsEnabled)
                DebugFloatingButton(
                  physicalReportProvider: _physicalRailReport,
                  diagnosticStatusProvider: _diagnosticStatus,
                ),
            ],
          ),
          bottomNavigationBar: _BottomNavigationSafeArea(
            child: Bnb03BottomNavigation(
              selected: _selectedNavigationItem,
              onChanged: (item) {
                if (item == Bnb03Item.search) {
                  _openQueryMenu();
                  return;
                }
                setState(() => _selectedNavigationItem = item);
              },
            ),
          ),
        ),
        FluviSlideUpSheet(
          isOpen: _queryMenuOpen,
          onDismiss: _closeQueryMenu,
          onDismissTransitionStarted:
              _controller.notifyQuerySheetReverseTransitionStarted,
          onDismissTransitionCompleted: _controller.notifyQuerySheetDismissed,
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
              _savedQueries.refresh(_controller.queryComposer.draft.direction),
            ),
          ),
        ),
      ],
    );
  }
}
