import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  test('publishes one complete frame and rejects older epochs', () {
    final store = DashboardVisibleFrameStore();
    var notifications = 0;
    store.addListener(() => notifications += 1);

    expect(store.publish(_frame(day: 2, epoch: 4, generation: 8)), isTrue);
    expect(store.publish(_frame(day: 1, epoch: 3, generation: 99)), isFalse);

    expect(store.value!.queryKey, _keyForDay(2));
    expect(store.visiblePublishCount, 1);
    expect(store.staleFrameRejectCount, 1);
    expect(notifications, 1);
  });

  test('same epoch rejects out-of-order generations', () {
    final store = DashboardVisibleFrameStore();
    store.publish(_frame(day: 3, epoch: 7, generation: 12));

    expect(store.publish(_frame(day: 2, epoch: 7, generation: 11)), isFalse);
    expect(store.value!.queryKey, _keyForDay(3));
    expect(store.staleFrameRejectCount, 1);
  });

  test('same visual frame is a notification no-op', () {
    final store = DashboardVisibleFrameStore();
    final frame = _frame(day: 5, epoch: 2, generation: 3);
    var notifications = 0;
    store.addListener(() => notifications += 1);

    expect(store.publish(frame), isTrue);
    expect(store.publish(frame), isFalse);
    expect(store.visiblePublishCount, 1);
    expect(notifications, 1);
  });

  test('settle promotion changes no visual counters or lane identities', () {
    final store = DashboardVisibleFrameStore();
    final preview = _frame(day: 7, epoch: 9, generation: 14);
    store.publish(preview);
    final before = store.visiblePublishCount;
    var notifications = 0;
    store.addListener(() => notifications += 1);

    expect(
      store.promoteCommitted(expectedKey: preview.queryKey, epoch: 9),
      isTrue,
    );

    expect(store.value!.mode, DashboardVisibleMode.committed);
    expect(store.value!.amount, same(preview.amount));
    expect(store.value!.count, same(preview.count));
    expect(store.value!.logBox, same(preview.logBox));
    expect(store.visiblePublishCount, before);
    expect(store.logRebindCount + store.amountRestartCount, 0);
    expect(notifications, 0);
  });

  test(
    'same-payload settle publishes committed LogBox metadata without rebinding payload',
    () {
      final store = DashboardVisibleFrameStore();
      addTearDown(store.dispose);
      final preview = _frame(day: 7, epoch: 9, generation: 14);
      var payloadNotifications = 0;
      var presentationNotifications = 0;
      store.logBoxLane.addListener(() => payloadNotifications += 1);
      store.logBoxPresentationLane.addListener(
        () => presentationNotifications += 1,
      );

      expect(store.publish(preview), isTrue);
      final payloadBefore = store.logBoxLane.value;
      final presentationBefore = store.logBoxPresentationLane.value;
      payloadNotifications = 0;
      presentationNotifications = 0;

      expect(
        store.promoteCommitted(expectedKey: preview.queryKey, epoch: 9),
        isTrue,
      );

      expect(store.logBoxLane.value, same(payloadBefore));
      expect(payloadNotifications, 0);
      expect(presentationNotifications, 1);
      expect(
        store.logBoxPresentationLane.value!.mode,
        DashboardVisibleMode.committed,
      );
      expect(store.logBoxPresentationLane.value!.queryKey, preview.queryKey);
      expect(
        store.logBoxPresentationLane.value!.coreRevision,
        preview.coreRevision,
      );
      expect(
        store.logBoxPresentationLane.value!.viewportId,
        preview.logBox.viewportId,
      );
      expect(
        store.logBoxPresentationLane.value,
        isNot(same(presentationBefore)),
      );
    },
  );

  test('atomically stages narrow presentation lanes from one frame', () {
    final store = DashboardVisibleFrameStore();
    addTearDown(store.dispose);
    final first = _frame(day: 4, epoch: 1, generation: 1);
    final second = _frame(day: 5, epoch: 1, generation: 2);
    var navigationNotifications = 0;
    var amountNotifications = 0;
    var countNotifications = 0;
    var logNotifications = 0;
    store.navigationLane.addListener(() => navigationNotifications += 1);
    store.amountLane.addListener(() => amountNotifications += 1);
    store.countLane.addListener(() => countNotifications += 1);
    store.logBoxLane.addListener(() => logNotifications += 1);

    expect(store.publish(first), isTrue);
    expect(store.publish(second), isTrue);

    expect(store.navigationLane.value, same(second));
    expect(store.amountLane.value, same(second));
    expect(store.countLane.value, same(second));
    expect(store.logBoxLane.value, same(second));
    expect(
      second.amountPresentationId,
      second.preparedFrame.amountPresentationId,
    );
    expect(
      second.countPresentationId,
      second.preparedFrame.countPresentationId,
    );
    expect(second.logBoxPresentationId, second.preparedFrame.logViewportId);
    expect(store.logBoxLane.value!.logBox, same(second.preparedFrame.logBox));
    expect(second.amount, same(second.preparedFrame.summary.amount));
    expect(second.count, same(second.preparedFrame.summary.count));
    expect(second.logBox, same(second.preparedFrame.logViewport.viewport));
    expect(
      second.preparedFrame.stableRowIdentities,
      same(second.preparedFrame.logViewport.stableRowIdentities),
    );
    expect(
      second.preparedFrame.stableAssetIdentities,
      same(second.preparedFrame.logViewport.stableAssetIdentities),
    );
    expect(
      <LedgerQueryKey>{
        store.amountLane.value!.amount.queryKey,
        store.countLane.value!.count.queryKey,
        store.logBoxLane.value!.logBox.queryKey,
      },
      <LedgerQueryKey>{second.queryKey},
    );
    expect(navigationNotifications, 2);
    expect(amountNotifications, 2);
    expect(countNotifications, 2);
    expect(logNotifications, 2);

    expect(
      store.promoteCommitted(expectedKey: second.queryKey, epoch: 1),
      isTrue,
    );
    expect(navigationNotifications, 2);
    expect(amountNotifications, 2);
    expect(countNotifications, 2);
    expect(logNotifications, 2);
  });

  test('flushes LogBox presentation metadata before its payload listener', () {
    final store = DashboardVisibleFrameStore();
    addTearDown(store.dispose);
    final notificationOrder = <String>[];
    store.logBoxPresentationLane.addListener(
      () => notificationOrder.add('presentation'),
    );
    store.logBoxLane.addListener(() => notificationOrder.add('payload'));

    expect(store.publish(_frame(day: 9, epoch: 3, generation: 21)), isTrue);

    expect(notificationOrder, <String>['presentation', 'payload']);
    expect(
      store.logBoxPresentationLane.value!.queryKey,
      store.logBoxLane.value!.queryKey,
    );
  });

  test(
    'Mind interaction preview updates content lanes without replacing committed navigation',
    () {
      final store = DashboardVisibleFrameStore();
      addTearDown(store.dispose);
      final committed = _frame(day: 4, epoch: 3, generation: 20);
      final preview = _frame(day: 8, epoch: 3, generation: 21);
      final order = store.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.mindAmount,
        localGeneration: 7,
      );
      store.publish(committed);

      expect(
        store.publishPreparedInteractionPreview(
          preview,
          previewGeneration: 7,
          order: order,
        ),
        isTrue,
      );
      expect(store.value, same(committed));
      expect(store.navigationLane.value, same(committed));
      expect(store.amountLane.value, same(preview));
      expect(store.countLane.value, same(preview));
      expect(store.logBoxLane.value, same(preview));
      expect(store.interactionPreviewPublishCount, 1);
      expect(store.mixedProjectionCount, 0);

      store.clearPreparedInteractionPreview(order: order);
      expect(store.value, same(committed));
      expect(store.amountLane.value, same(committed));
      expect(store.countLane.value, same(committed));
      expect(store.logBoxLane.value, same(committed));
    },
  );

  test('rejects a preview order issued by a different visible-frame store', () {
    final store = DashboardVisibleFrameStore();
    final foreignStore = DashboardVisibleFrameStore();
    addTearDown(store.dispose);
    addTearDown(foreignStore.dispose);
    final committed = _frame(day: 4, epoch: 3, generation: 20);
    final preview = _frame(day: 8, epoch: 3, generation: 21);
    store.publish(committed);
    final foreignOrder = foreignStore.nextInteractionPreviewOrder(
      producer: DashboardInteractionPreviewProducer.mindAmount,
      localGeneration: 1,
    );

    expect(
      store.publishPreparedInteractionPreview(
        preview,
        previewGeneration: 1,
        order: foreignOrder,
      ),
      isFalse,
    );
    expect(
      store.lastInteractionPreviewRejectionReason,
      'orderNotIssuedByVisibleFrameStore',
    );
    expect(store.interactionPreviewOrder, isNull);

    final localOrder = store.nextInteractionPreviewOrder(
      producer: DashboardInteractionPreviewProducer.mindAmount,
      localGeneration: 1,
    );
    expect(localOrder.interactionEpoch, 1);
    expect(
      store.publishPreparedInteractionPreview(
        preview,
        previewGeneration: 1,
        order: localOrder,
      ),
      isTrue,
    );
  });

  test(
    'RED: a later Avatar intent is accepted after a high-frequency Mind producer',
    () {
      final store = DashboardVisibleFrameStore();
      addTearDown(store.dispose);
      final committed = _frame(day: 4, epoch: 3, generation: 20);
      final mind = _frame(day: 8, epoch: 3, generation: 21);
      final avatar = _frame(day: 9, epoch: 3, generation: 22);
      store.publish(committed);
      final mindOrder = store.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.mindAmount,
        localGeneration: 63,
      );

      expect(
        store.publishPreparedInteractionPreview(
          mind,
          previewGeneration: 63,
          order: mindOrder,
        ),
        isTrue,
      );
      final staleMindOrder = store.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.mindAmount,
        localGeneration: 64,
      );
      final avatarOrder = store.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.budgetAvatar,
        localGeneration: 2,
      );
      expect(
        store.publishPreparedInteractionPreview(
          avatar,
          previewGeneration: 2,
          order: avatarOrder,
        ),
        isTrue,
        reason:
            'A later Avatar intent may not be rejected solely because Mind '
            'used more local preview ticks in the same visible-frame store.',
      );
      expect(store.logBoxLane.value, same(avatar));

      expect(
        store.publishPreparedInteractionPreview(
          mind,
          previewGeneration: 64,
          order: staleMindOrder,
        ),
        isFalse,
        reason:
            'A delayed completion from the older Mind owner must remain stale '
            'after the newer Avatar intent is visible.',
      );
      expect(store.logBoxLane.value, same(avatar));
    },
  );

  test(
    'an older issued Mind completion stays stale after a later Mind intent',
    () {
      final store = DashboardVisibleFrameStore();
      addTearDown(store.dispose);
      final committed = _frame(day: 4, epoch: 3, generation: 20);
      final currentMind = _frame(day: 8, epoch: 3, generation: 21);
      final staleMind = _frame(day: 9, epoch: 3, generation: 22);
      store.publish(committed);
      final staleMindOrder = store.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.mindAmount,
        localGeneration: 1,
      );
      final currentMindOrder = store.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.mindAmount,
        localGeneration: 2,
      );

      expect(
        store.publishPreparedInteractionPreview(
          currentMind,
          previewGeneration: 2,
          order: currentMindOrder,
        ),
        isTrue,
      );
      expect(
        store.publishPreparedInteractionPreview(
          staleMind,
          previewGeneration: 1,
          order: staleMindOrder,
        ),
        isFalse,
        reason:
            'The shared epoch orders producers, but cannot resurrect a stale '
            'completion from the same Mind producer with an older local target.',
      );
      expect(store.logBoxLane.value, same(currentMind));
    },
  );

  test('an earlier Mind cleanup cannot clear the newer Avatar owner', () {
    final store = DashboardVisibleFrameStore();
    addTearDown(store.dispose);
    final committed = _frame(day: 4, epoch: 3, generation: 20);
    final mind = _frame(day: 8, epoch: 3, generation: 21);
    final avatar = _frame(day: 9, epoch: 3, generation: 22);
    final mindOrder = store.nextInteractionPreviewOrder(
      producer: DashboardInteractionPreviewProducer.mindAmount,
      localGeneration: 63,
    );
    final avatarOrder = store.nextInteractionPreviewOrder(
      producer: DashboardInteractionPreviewProducer.budgetAvatar,
      localGeneration: 2,
    );
    store.publish(committed);

    expect(
      store.publishPreparedInteractionPreview(
        mind,
        previewGeneration: 63,
        order: mindOrder,
      ),
      isTrue,
    );
    expect(
      store.publishPreparedInteractionPreview(
        avatar,
        previewGeneration: 2,
        order: avatarOrder,
      ),
      isTrue,
    );

    store.clearPreparedInteractionPreview(order: mindOrder);

    expect(store.logBoxLane.value, same(avatar));
    expect(store.amountLane.value, same(avatar));
    expect(store.countLane.value, same(avatar));
    expect(store.interactionPreviewOrder, same(avatarOrder));
  });

  test('accepts a later Mind owner after an earlier Avatar owner', () {
    final store = DashboardVisibleFrameStore();
    addTearDown(store.dispose);
    final committed = _frame(day: 4, epoch: 3, generation: 20);
    final avatar = _frame(day: 8, epoch: 3, generation: 21);
    final mind = _frame(day: 9, epoch: 3, generation: 22);
    store.publish(committed);
    final avatarOrder = store.nextInteractionPreviewOrder(
      producer: DashboardInteractionPreviewProducer.budgetAvatar,
      localGeneration: 2,
    );

    expect(
      store.publishPreparedInteractionPreview(
        avatar,
        previewGeneration: 2,
        order: avatarOrder,
      ),
      isTrue,
    );
    final staleAvatarOrder = store.nextInteractionPreviewOrder(
      producer: DashboardInteractionPreviewProducer.budgetAvatar,
      localGeneration: 3,
    );
    final mindOrder = store.nextInteractionPreviewOrder(
      producer: DashboardInteractionPreviewProducer.mindAmount,
      localGeneration: 64,
    );
    expect(
      store.publishPreparedInteractionPreview(
        mind,
        previewGeneration: 64,
        order: mindOrder,
      ),
      isTrue,
    );
    expect(
      store.publishPreparedInteractionPreview(
        avatar,
        previewGeneration: 3,
        order: staleAvatarOrder,
      ),
      isFalse,
    );
    expect(store.logBoxLane.value, same(mind));
  });

  test(
    'orders Mind then Avatar then Summary then Mind by shared intent epoch',
    () {
      final store = DashboardVisibleFrameStore();
      addTearDown(store.dispose);
      final committed = _frame(day: 4, epoch: 3, generation: 20);
      final mindStart = _frame(day: 5, epoch: 3, generation: 21);
      final avatar = _frame(day: 6, epoch: 3, generation: 22);
      final summary = _frame(day: 7, epoch: 3, generation: 23);
      final mindEnd = _frame(day: 8, epoch: 3, generation: 24);
      store.publish(committed);
      final mindStartOrder = store.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.mindAmount,
        localGeneration: 1,
      );

      expect(
        store.publishPreparedInteractionPreview(
          mindStart,
          previewGeneration: 1,
          order: mindStartOrder,
        ),
        isTrue,
      );
      final avatarOrder = store.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.budgetAvatar,
        localGeneration: 1,
      );
      expect(
        store.publishPreparedInteractionPreview(
          avatar,
          previewGeneration: 1,
          order: avatarOrder,
        ),
        isTrue,
      );
      final summaryOrder = store.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.summaryTime,
        localGeneration: 1,
      );
      expect(
        store.publishPreparedInteractionPreview(
          summary,
          previewGeneration: 1,
          order: summaryOrder,
        ),
        isTrue,
      );
      final staleSummaryOrder = store.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.summaryTime,
        localGeneration: 2,
      );
      final mindEndOrder = store.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.mindAmount,
        localGeneration: 2,
      );
      expect(
        store.publishPreparedInteractionPreview(
          mindEnd,
          previewGeneration: 2,
          order: mindEndOrder,
        ),
        isTrue,
      );
      expect(
        store.publishPreparedInteractionPreview(
          summary,
          previewGeneration: 2,
          order: staleSummaryOrder,
        ),
        isFalse,
      );
      expect(store.logBoxLane.value, same(mindEnd));
      expect(
        store.interactionPreviewOrder!.producer,
        DashboardInteractionPreviewProducer.mindAmount,
      );
      expect(store.interactionPreviewOrder!.interactionEpoch, 5);
    },
  );

  test(
    'RED: a queued Summary intent rejects an older Mind completion before its display frame flushes',
    () {
      final store = DashboardVisibleFrameStore();
      addTearDown(store.dispose);
      final committed = _frame(day: 4, epoch: 3, generation: 20);
      final staleMind = _frame(day: 8, epoch: 3, generation: 21);
      final summary = _frame(day: 9, epoch: 4, generation: 22);
      store.publish(committed);
      final mindOrder = store.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.mindAmount,
        localGeneration: 63,
      );
      final summaryOrder = store.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.summaryTime,
        localGeneration: 1,
      );

      expect(store.claimInteractionPublicationIntent(summaryOrder), isTrue);
      expect(
        store.publishPreparedInteractionPreview(
          staleMind,
          previewGeneration: 63,
          order: mindOrder,
        ),
        isFalse,
        reason:
            'A completion from the prior Mind intent cannot win merely because '
            'the Summary visual frame is waiting for the next display callback.',
      );
      expect(store.publish(summary, interactionOrder: summaryOrder), isTrue);
      expect(store.value, same(summary));
      expect(store.logBoxLane.value, same(summary));
      expect(store.interactionPreviewOrder, same(summaryOrder));

      final nextMind = _frame(day: 10, epoch: 4, generation: 23);
      final nextMindOrder = store.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.mindAmount,
        localGeneration: 64,
      );
      expect(
        store.publishPreparedInteractionPreview(
          nextMind,
          previewGeneration: 64,
          order: nextMindOrder,
        ),
        isTrue,
      );
      expect(store.logBoxLane.value, same(nextMind));
    },
  );

  test(
    'POST-DF1 RED: an armed Mind canonical handoff retains live lanes when its projection differs',
    () {
      final store = DashboardVisibleFrameStore();
      addTearDown(store.dispose);
      final committed = _frame(day: 4, epoch: 3, generation: 20);
      final preview = _frame(day: 8, epoch: 3, generation: 21);
      final mismatchedCanonical = _frame(
        day: 8,
        epoch: 4,
        generation: 22,
        contentSeed: 0,
      ).asCommitted();
      final order = store.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.mindAmount,
        localGeneration: 7,
      );
      store.publish(committed);
      store.publishPreparedInteractionPreview(
        preview,
        previewGeneration: 7,
        order: order,
      );

      expect(
        store.armPreparedInteractionPreviewCanonicalReconciliation(
          order: order,
          frameGeneration: preview.frameGeneration,
        ),
        isTrue,
      );
      expect(store.publish(mismatchedCanonical), isFalse);

      expect(store.value, same(mismatchedCanonical));
      expect(store.amountLane.value, same(preview));
      expect(store.countLane.value, same(preview));
      expect(store.logBoxLane.value, same(preview));
      expect(
        store.interactionPreviewReconciliationState,
        DashboardInteractionPreviewReconciliationState.retainedMismatch,
      );
      expect(store.interactionPreviewCanonicalMismatchRetainCount, 1);
    },
  );

  test(
    'POST-DF1 RED: an armed Mind canonical handoff removes its overlay only after an exact projection match',
    () {
      final store = DashboardVisibleFrameStore();
      addTearDown(store.dispose);
      final committed = _frame(day: 4, epoch: 3, generation: 20);
      final preview = _frame(day: 8, epoch: 3, generation: 21);
      final exactCanonical = _frame(
        day: 8,
        epoch: 4,
        generation: 22,
      ).asCommitted();
      final order = store.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.mindAmount,
        localGeneration: 7,
      );
      store.publish(committed);
      store.publishPreparedInteractionPreview(
        preview,
        previewGeneration: 7,
        order: order,
      );

      expect(
        store.armPreparedInteractionPreviewCanonicalReconciliation(
          order: order,
          frameGeneration: preview.frameGeneration,
        ),
        isTrue,
      );
      expect(store.publish(exactCanonical), isTrue);

      expect(store.amountLane.value, same(exactCanonical));
      expect(store.countLane.value, same(exactCanonical));
      expect(store.logBoxLane.value, same(exactCanonical));
      expect(
        store.interactionPreviewReconciliationState,
        DashboardInteractionPreviewReconciliationState.reconciledExact,
      );
      expect(store.interactionPreviewCanonicalReconcileCount, 1);
    },
  );

  test('settle promotion requires the exact visible key and epoch', () {
    final store = DashboardVisibleFrameStore();
    final preview = _frame(day: 8, epoch: 11, generation: 20);
    store.publish(preview);

    expect(
      store.promoteCommitted(expectedKey: _keyForDay(7), epoch: 11),
      isFalse,
    );
    expect(
      store.promoteCommitted(expectedKey: preview.queryKey, epoch: 10),
      isFalse,
    );
    expect(store.value!.mode, DashboardVisibleMode.preview);
  });
}

DashboardVisibleFrame _frame({
  required int day,
  required int epoch,
  required int generation,
  int? contentSeed,
}) {
  final content = contentSeed ?? day;
  final parent = _parentScope();
  final scope = parent.copyWith(
    timeScope: DayScope(LocalDate(year: 2026, month: 6, day: day)),
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: parent.key,
    coreRevision: 3,
    totalMinor: content * 100,
    formattedAmount: '$content,00 Ft',
    entryCount: content,
    formattedEntryCount: '$content',
    logBox: DashboardLogViewportState(
      queryKey: scope.key,
      revision: 3,
      groups: const [],
      entryCount: content,
      nextCursor: null,
      direction: LedgerDirection.income,
    ),
    presentationDigest: content,
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: parent.key,
    plane: TimePlane.month,
    railOpen: true,
    semanticIndex: day - 1,
    childLabel: '$day',
    navigationEpoch: epoch,
    presentationEpoch: epoch,
    frameGeneration: generation,
    mode: DashboardVisibleMode.preview,
  );
}

LedgerQueryKey _keyForDay(int day) => _parentScope()
    .copyWith(timeScope: DayScope(LocalDate(year: 2026, month: 6, day: day)))
    .key;

CurrentLedgerQueryScope _parentScope() => CurrentLedgerQueryScope(
  direction: LedgerDirection.income,
  timeScope: const MonthScope(YearMonth(year: 2026, month: 6)),
);
