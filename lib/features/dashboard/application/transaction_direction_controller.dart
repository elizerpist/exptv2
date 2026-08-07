import 'package:flutter/foundation.dart';

enum TransactionDirection { income, expense }

/// Headless owner of local transaction-direction selection and pulse requests.
class TransactionDirectionController extends ChangeNotifier {
  TransactionDirectionController({
    TransactionDirection initialDirection = TransactionDirection.income,
  }) : _direction = initialDirection;

  TransactionDirection _direction;
  int _pulseRevision = 0;

  TransactionDirection get direction => _direction;
  int get pulseRevision => _pulseRevision;

  void select(TransactionDirection value) {
    if (value == _direction) return;
    _direction = value;
    _pulseRevision += 1;
    notifyListeners();
  }
}
