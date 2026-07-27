import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _allV3Ids = <String>{
  'BUGFIX-20260726V3-001',
  'BUGFIX-20260726V3-002',
  'BUGFIX-20260726V3-003',
  'BUGFIX-20260726V3-004',
  'BUGFIX-20260726V3-005',
  'BUGFIX-20260726V3-006',
  'BUGFIX-20260726V3-007',
  'BUGFIX-20260726V3-008',
  'BUGFIX-20260726V3-009',
  'BUGFIX-20260726V3-010',
  'BUGFIX-20260726V3-011',
  'BUGFIX-20260726V3-012',
};

/// Prerequisite inventory only; these component tests are not V3 acceptance evidence.
final Map<String, List<String>> v3ProofInventory = <String, List<String>>{
  'BUGFIX-20260726V3-001': ['spendee_balance_post_content_test.dart'],
  'BUGFIX-20260726V3-002': ['spendee_balance_post_content_test.dart'],
  'BUGFIX-20260726V3-003': ['spendee_balance_transaction_log_test.dart'],
  'BUGFIX-20260726V3-004': ['spendee_balance_performance_test.dart'],
  'BUGFIX-20260726V3-005': ['spendee_balance_v3_mapping_test.dart'],
  'BUGFIX-20260726V3-006': ['spendee_balance_dashboard_test.dart'],
  'BUGFIX-20260726V3-007': ['spendee_balance_dashboard_test.dart'],
  'BUGFIX-20260726V3-008': ['spendee_balance_cards_test.dart'],
  'BUGFIX-20260726V3-009': ['spendee_balance_cards_test.dart'],
  'BUGFIX-20260726V3-010': ['spendee_balance_html_contract_test.dart'],
  'BUGFIX-20260726V3-011': ['spendee_balance_transaction_log_test.dart'],
  'BUGFIX-20260726V3-012': ['spendee_balance_cards_test.dart'],
};

final Map<String, List<String>> v3ProofTests = v3ProofInventory;
const v3InventoryIsAcceptanceEvidence = false;

const v3RequiredFutureProofCategories = <String, String>{
  'BUGFIX-20260726V3-001': 'production-host geometry/material',
  'BUGFIX-20260726V3-002': 'production-host geometry/semantics',
  'BUGFIX-20260726V3-003': 'production-host transaction row',
  'BUGFIX-20260726V3-004': '14k trace',
  'BUGFIX-20260726V3-005': 'production-host mapping review',
  'BUGFIX-20260726V3-006': 'production-host paint bounds',
  'BUGFIX-20260726V3-007': 'production-host ancestor material',
  'BUGFIX-20260726V3-008': 'production-host FastInfo cards',
  'BUGFIX-20260726V3-009': 'production-host detail cards',
  'BUGFIX-20260726V3-010': 'reference source contract',
  'BUGFIX-20260726V3-011': 'production-host swipe trace',
  'BUGFIX-20260726V3-012': 'production-host visual style resolver',
};

void main() {
  test('every V3 row has a prerequisite-only proof inventory', () {
    expect(v3ProofTests.keys.toSet(), equals(_allV3Ids));
    expect(v3ProofTests.values.every((tests) => tests.isNotEmpty), isTrue);
    expect(
      v3ProofTests.values
          .expand((tests) => tests)
          .every((testFile) => File('test/spendeetest/$testFile').existsSync()),
      isTrue,
    );
    expect(v3RequiredFutureProofCategories.keys.toSet(), equals(_allV3Ids));
    expect(v3InventoryIsAcceptanceEvidence, isFalse);
  });
}
