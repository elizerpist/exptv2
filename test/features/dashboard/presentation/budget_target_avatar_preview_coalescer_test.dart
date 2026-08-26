import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_target_avatar_preview_coalescer.dart';

void main() {
  test('every semantic avatar crossing publishes immediately', () {
    final published = <int>[];
    final publisher = BudgetTargetAvatarPreviewPublisher(
      onPublish: published.add,
    );
    addTearDown(publisher.dispose);

    publisher.submit(2);
    publisher.submit(3);
    publisher.submit(4);

    expect(published, <int>[2, 3, 4]);
    expect(publisher.previewPublications, 3);
    expect(publisher.semanticCrossings, 3);
  });

  test('dispose drops later transient previews safely', () {
    final published = <int>[];
    final publisher = BudgetTargetAvatarPreviewPublisher(
      onPublish: published.add,
    );

    publisher.submit(7);
    publisher.dispose();
    publisher.submit(8);

    expect(published, <int>[7]);
  });
}
