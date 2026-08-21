import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_target_avatar_preview_coalescer.dart';

void main() {
  test('latest semantic avatar preview wins within one display frame', () {
    final scheduled = <FrameCallback>[];
    final published = <int>[];
    final coalescer = BudgetTargetAvatarPreviewCoalescer(
      scheduleFrame: scheduled.add,
      onPublish: published.add,
    );
    addTearDown(coalescer.dispose);

    coalescer.submit(2);
    coalescer.submit(3);
    coalescer.submit(4);

    expect(scheduled, hasLength(1));
    expect(published, isEmpty);
    scheduled.single(const Duration(milliseconds: 16));

    expect(published, <int>[4]);
    expect(coalescer.previewPublications, 1);
    expect(coalescer.semanticCrossings, 3);
  });

  test('dispose drops a scheduled transient preview safely', () {
    final scheduled = <FrameCallback>[];
    final published = <int>[];
    final coalescer = BudgetTargetAvatarPreviewCoalescer(
      scheduleFrame: scheduled.add,
      onPublish: published.add,
    );

    coalescer.submit(7);
    coalescer.dispose();
    scheduled.single(Duration.zero);

    expect(published, isEmpty);
  });
}
