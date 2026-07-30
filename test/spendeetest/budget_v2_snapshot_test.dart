import 'package:exptv2/features/transactions/widgets/experimental/budget_v2/budget_v2_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'real-size source preparation is cached by revision across source instances',
    () {
      var preparationCount = 0;
      var revisionReads = 0;
      final cache = BudgetV2SnapshotCache<_RawFixture, _PreparedFixture>(
        revisionOf: (source) {
          revisionReads += 1;
          return source.revision;
        },
        prepare: (source) {
          preparationCount += 1;
          final byAvatar = <String, List<int>>{};
          for (final record in source.records) {
            byAvatar
                .putIfAbsent(record.avatarKey, () => <int>[])
                .add(record.id);
          }
          return _PreparedFixture(byAvatar);
        },
        avatarDataOf: (prepared, avatarKey) => prepared.byAvatar[avatarKey]!,
      );
      final firstRecords = _GuardedRecords(_records());
      final sameRevisionRecords = _GuardedRecords(_records());
      final nextRevisionRecords = _GuardedRecords(_records());
      final firstSource = _RawFixture(revision: 41, records: firstRecords);
      final sameRevisionSource = _RawFixture(
        revision: 41,
        records: sameRevisionRecords,
      );
      final nextRevisionSource = _RawFixture(
        revision: 42,
        records: nextRevisionRecords,
      );

      final first = cache.resolve(firstSource);
      final sameRevision = cache.resolve(sameRevisionSource);
      final nextRevision = cache.resolve(nextRevisionSource);

      expect(identical(first, sameRevision), isTrue);
      expect(identical(first, nextRevision), isFalse);
      expect(revisionReads, 3);
      expect(preparationCount, 2);
      expect(firstRecords.traversedRecords, 4096);
      expect(sameRevisionRecords.traversedRecords, 0);
      expect(nextRevisionRecords.traversedRecords, 4096);
    },
  );

  test(
    'avatar selection reads the prepared index without another raw scan',
    () {
      final cache = BudgetV2SnapshotCache<_RawFixture, _PreparedFixture>(
        revisionOf: (source) => source.revision,
        prepare: (source) {
          final byAvatar = <String, List<int>>{};
          for (final record in source.records) {
            byAvatar
                .putIfAbsent(record.avatarKey, () => <int>[])
                .add(record.id);
          }
          return _PreparedFixture(byAvatar);
        },
        avatarDataOf: (prepared, avatarKey) => prepared.byAvatar[avatarKey]!,
      );
      final records = _GuardedRecords(_records());
      final source = _RawFixture(revision: 42, records: records);

      final snapshot = cache.resolve(source);
      expect(records.traversedRecords, 4096);
      records.rejectFurtherTraversal();

      expect(snapshot.avatarData('travel'), hasLength(2048));
      expect(records.traversedRecords, 4096);
    },
  );
}

class _RawFixture {
  const _RawFixture({required this.revision, required this.records});

  final int revision;
  final Iterable<_RawRecord> records;
}

class _RawRecord {
  const _RawRecord({required this.id, required this.avatarKey});

  final int id;
  final String avatarKey;
}

class _PreparedFixture {
  const _PreparedFixture(this.byAvatar);

  final Map<String, List<int>> byAvatar;
}

List<_RawRecord> _records() => List<_RawRecord>.generate(
  4096,
  (index) => _RawRecord(id: index, avatarKey: index.isEven ? 'food' : 'travel'),
);

class _GuardedRecords extends Iterable<_RawRecord> {
  _GuardedRecords(this._records);

  final List<_RawRecord> _records;
  var _allowTraversal = true;
  var traversedRecords = 0;

  void rejectFurtherTraversal() {
    _allowTraversal = false;
  }

  @override
  Iterator<_RawRecord> get iterator {
    if (!_allowTraversal) {
      throw StateError('Raw records must not be traversed after preparation.');
    }
    final iterator = _records.iterator;
    return _GuardedRecordIterator(
      iterator,
      onRecordVisited: () => traversedRecords += 1,
    );
  }
}

class _GuardedRecordIterator implements Iterator<_RawRecord> {
  _GuardedRecordIterator(this._delegate, {required this.onRecordVisited});

  final Iterator<_RawRecord> _delegate;
  final void Function() onRecordVisited;

  @override
  _RawRecord get current => _delegate.current;

  @override
  bool moveNext() {
    final moved = _delegate.moveNext();
    if (moved) onRecordVisited();
    return moved;
  }
}
