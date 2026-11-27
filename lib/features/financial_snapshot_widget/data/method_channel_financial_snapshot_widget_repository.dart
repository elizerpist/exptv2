import 'package:flutter/services.dart';

import '../domain/financial_snapshot_widget_repository.dart';

final class MethodChannelFinancialSnapshotWidgetRepository
    implements FinancialSnapshotWidgetRepository {
  const MethodChannelFinancialSnapshotWidgetRepository();
  static const _channel = MethodChannel('com.fluvi/runtime_monitoring');

  @override
  Future<FinancialSnapshotWidgetStatus> load() async =>
      FinancialSnapshotWidgetStatus.fromMap(
        await _channel.invokeMapMethod<Object?, Object?>(
              'getFinancialSnapshotWidget',
            ) ??
            const {},
      );

  @override
  Future<FinancialSnapshotWidgetStatus> saveWidget(
    FinancialSnapshotWidgetConfiguration configuration,
  ) async => FinancialSnapshotWidgetStatus.fromMap(
    await _channel.invokeMapMethod<Object?, Object?>(
          'setFinancialSnapshotWidget',
          configuration.toMap(),
        ) ??
        const {},
  );
}
