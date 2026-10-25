/// Presentation-independent membership for recurring/ghost transactions.
///
/// This is deliberately a query dimension rather than a LogBox visibility
/// switch: every dashboard projection receives the same committed ledger
/// universe. Pending occurrences are still presentation-only and never enter
/// financial totals.
enum GhostFilterMode {
  nonGhost,
  onlyGhost,
  both;

  GhostFilterMode get next => switch (this) {
    GhostFilterMode.nonGhost => GhostFilterMode.onlyGhost,
    GhostFilterMode.onlyGhost => GhostFilterMode.both,
    GhostFilterMode.both => GhostFilterMode.nonGhost,
  };

  String get semanticLabel => switch (this) {
    GhostFilterMode.nonGhost => 'Nem ismétlődő tranzakciók',
    GhostFilterMode.onlyGhost => 'Ghost eredetű tranzakciók',
    GhostFilterMode.both => 'Minden tranzakció és ghost',
  };
}
