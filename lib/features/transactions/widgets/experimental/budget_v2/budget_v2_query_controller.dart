import 'package:flutter/foundation.dart';

@immutable
class BudgetV2ExternalQueryScope {
  const BudgetV2ExternalQueryScope({
    required this.searchQuery,
    required this.categoryIds,
    required this.merchantKeys,
  });

  final String searchQuery;
  final Set<int> categoryIds;
  final Set<String> merchantKeys;

  BudgetV2ExternalQueryScope copyWith({
    String? searchQuery,
    Set<int>? categoryIds,
    Set<String>? merchantKeys,
  }) {
    return BudgetV2ExternalQueryScope(
      searchQuery: searchQuery ?? this.searchQuery,
      categoryIds: categoryIds ?? this.categoryIds,
      merchantKeys: merchantKeys ?? this.merchantKeys,
    );
  }
}

@immutable
class BudgetV2QueryReconciliation {
  const BudgetV2QueryReconciliation({
    required this.avatarKeyToAdopt,
    required this.clearExternalAvatar,
    required this.clearSelectedVendor,
  });

  final String? avatarKeyToAdopt;
  final bool clearExternalAvatar;
  final bool clearSelectedVendor;

  bool get requiresStoreWrite => false;
}

class BudgetV2QueryController {
  BudgetV2QueryController({
    required this.unfilteredAvatarKey,
    required Map<int, String> avatarKeyByCategoryId,
  }) : _avatarKeyByCategoryId = Map<int, String>.unmodifiable(
         avatarKeyByCategoryId,
       );

  final String unfilteredAvatarKey;
  final Map<int, String> _avatarKeyByCategoryId;

  BudgetV2ExternalQueryScope _externalScope = const BudgetV2ExternalQueryScope(
    searchQuery: '',
    categoryIds: <int>{},
    merchantKeys: <String>{},
  );
  String? _externalAvatarKey;
  String? _selectedVendorKey;
  _AvatarAcknowledgement? _avatarAcknowledgement;
  Set<String>? _vendorAcknowledgement;

  BudgetV2ExternalQueryScope get externalScope => _externalScope;
  String? get externalAvatarKey => _externalAvatarKey;
  String? get selectedVendorKey => _selectedVendorKey;

  void selectVendor(String? vendorKey) {
    _selectedVendorKey = vendorKey;
    _vendorAcknowledgement = null;
  }

  void acknowledgeVendor(Set<String> merchantKeys) {
    _vendorAcknowledgement = Set<String>.unmodifiable(merchantKeys);
  }

  void acknowledgeAvatar({
    required String avatarKey,
    required Set<int> categoryIds,
  }) {
    _externalAvatarKey = avatarKey;
    _avatarAcknowledgement = _AvatarAcknowledgement(
      avatarKey: avatarKey,
      categoryIds: Set<int>.unmodifiable(categoryIds),
    );
  }

  BudgetV2QueryReconciliation reconcileExternalScope(
    BudgetV2ExternalQueryScope scope,
  ) {
    final frozenScope = BudgetV2ExternalQueryScope(
      searchQuery: scope.searchQuery,
      categoryIds: Set<int>.unmodifiable(scope.categoryIds),
      merchantKeys: Set<String>.unmodifiable(scope.merchantKeys),
    );
    _externalScope = frozenScope;

    final acknowledgedAvatar = _avatarAcknowledgement;
    final acknowledgementMatches =
        acknowledgedAvatar != null &&
        _sameSet(acknowledgedAvatar.categoryIds, frozenScope.categoryIds);
    final nextAvatarKey = acknowledgementMatches
        ? acknowledgedAvatar.avatarKey
        : _avatarFor(frozenScope.categoryIds);
    _avatarAcknowledgement = null;

    final externalAvatarChanged = nextAvatarKey != _externalAvatarKey;
    String? avatarKeyToAdopt;
    var clearExternalAvatar = false;
    if (externalAvatarChanged) {
      if (nextAvatarKey == null) {
        clearExternalAvatar = _externalAvatarKey != null;
      } else {
        avatarKeyToAdopt = nextAvatarKey;
      }
      _externalAvatarKey = nextAvatarKey;
    }

    final acknowledgedVendors = _vendorAcknowledgement;
    final vendorAcknowledgementMatches =
        acknowledgedVendors != null &&
        _sameSet(acknowledgedVendors, frozenScope.merchantKeys);
    _vendorAcknowledgement = null;
    var clearSelectedVendor = false;
    final selectedVendorKey = _selectedVendorKey;
    if (selectedVendorKey != null &&
        ((externalAvatarChanged && !acknowledgementMatches) ||
            (!vendorAcknowledgementMatches &&
                !frozenScope.merchantKeys.contains(selectedVendorKey)))) {
      _selectedVendorKey = null;
      clearSelectedVendor = true;
    }

    return BudgetV2QueryReconciliation(
      avatarKeyToAdopt: avatarKeyToAdopt,
      clearExternalAvatar: clearExternalAvatar,
      clearSelectedVendor: clearSelectedVendor,
    );
  }

  String? _avatarFor(Set<int> categoryIds) {
    if (categoryIds.isEmpty) return unfilteredAvatarKey;
    if (categoryIds.length != 1) return null;
    return _avatarKeyByCategoryId[categoryIds.single];
  }
}

@immutable
class _AvatarAcknowledgement {
  const _AvatarAcknowledgement({
    required this.avatarKey,
    required this.categoryIds,
  });

  final String avatarKey;
  final Set<int> categoryIds;
}

bool _sameSet<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.containsAll(right);
