// Historical geometry oracle: equations from 2e809f2, intentionally independent
// of the replacement physical policy. Values describe layout envelopes, not
// pixel-detected chart ink. See generated evidence JSON for that distinction.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_unified_mother_card_geometry.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_unified_mother_card_motion.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_unified_mother_card_geometry.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/mind_unified_mother_card_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart';

Rect historicalRect(DashboardBounds b) =>
    Rect.fromLTWH(b.left, b.top, b.width, b.height);
Map<String, Object> historicalMotherCard(DashboardLayoutFrame f, bool mind) {
  final s = 1 - f.headerExpansionProgress;
  final h = historicalRect(f.headerBounds);
  final joined = historicalRect(
    DashboardHeaderContentMotherCardBounds.resolve(geometry: f),
  );
  late Rect body, content;
  if (mind) {
    final scale = 1 + (DashboardMotionTokens.zone2CollapseScale - 1) * s;
    final width = h.width * scale;
    final top = h.bottom + f.zone2Shift;
    body = Rect.fromLTWH(
      h.center.dx - width / 2,
      top,
      width,
      math.max(h.bottom, top + f.canonicalMotherCardContentHeight * (1 - s)) -
          top,
    );
    final source = historicalRect(
      f.unifiedSubheaderBounds!,
    ).shift(Offset(0, f.zone2Shift));
    content = Rect.fromLTWH(
      source.center.dx - source.width * f.zone2Scale / 2,
      source.top,
      source.width * f.zone2Scale,
      source.height * f.zone2Scale,
    );
  } else {
    final m = f.lowerCardMotion!;
    final layoutWidth = h.width + h.left * 2 - m.left - m.right;
    final width = layoutWidth * m.scale;
    final target = Rect.fromLTWH(
      m.left + (layoutWidth - width) / 2,
      m.top + f.modeContentBounds.top - f.zone2Bounds.top,
      width,
      f.modeContentBounds.height * m.scale,
    );
    final vertical = Rect.lerp(
      Rect.fromLTRB(h.left, h.bottom, h.right, joined.bottom),
      target,
      s,
    )!;
    body = Rect.fromLTRB(
      target.left,
      vertical.top,
      target.right,
      vertical.bottom,
    );
    if (f.mode == DashboardModeSpec.balance) {
      final scale = width / h.width;
      final authored = Rect.fromLTRB(
        joined.left,
        h.bottom + BalanceAlternativeHtmlTokens.outerInset,
        joined.right,
        joined.bottom - BalanceAlternativeHtmlTokens.outerInset,
      );
      final x = body.left - h.left * scale;
      final y = body.top + f.zone2Shift - h.bottom * scale;
      content = Rect.fromLTWH(
        x + authored.left * scale,
        y + authored.top * scale,
        authored.width * scale,
        authored.height * scale,
      );
    } else {
      content = Rect.fromLTWH(
        target.left,
        m.top,
        width,
        f.zone2Bounds.height * m.scale,
      );
    }
  }
  List<double> coords(Rect r) => [r.left, r.top, r.right, r.bottom];
  return {
    'separation': s,
    'body': coords(body),
    'contentLayoutEnvelope': coords(content),
    'visibleContentBottom': math.min(content.bottom, body.bottom),
    'bottomClippedHeightFraction':
        ((content.bottom - body.bottom).clamp(0.0, content.height) /
        content.height),
    'bodyMinusUnclippedContentBottom': body.bottom - content.bottom,
    'summary': coords(historicalRect(f.summaryBounds)),
    'joined': coords(joined),
    'header': coords(h),
  };
}

void main() {
  test('historical 2e809f2 physical/content bounds', () {
    final rows = <Object>[];
    for (final mode in [
      DashboardModeSpec.budget,
      DashboardModeSpec.balance,
      DashboardModeSpec.mind,
    ]) {
      for (final stretch in [0.0, 48.0]) {
        for (final s in [.35, .50, .65]) {
          final metrics = DashboardLayoutMetrics.reference.fitToViewport(
            const Size(412, 892),
          );
          final f = DashboardGeometryResolver.resolve(
            metrics: metrics,
            mode: mode,
            collapseProgress: metrics.collapseTravel * s,
            isRailExpanded: false,
            hasPhysicalRail: false,
            seamlessHeaderContent: mode == DashboardModeSpec.mind,
            principalModeContentExtraHeight: stretch,
            canonicalMotherCardContentExtraHeight: stretch,
            expandedHeaderExtraHeight: stretch / 2,
          );
          final row = historicalMotherCard(f, mode == DashboardModeSpec.mind);
          final body = row['body'] as List<double>;
          expect(body.every((v) => v.isFinite), isTrue);
          expect(body[3], greaterThanOrEqualTo(body[1]));
          expect(body[2], greaterThan(body[0]));
          rows.add({'mode': mode.mode.name, 'stretch': stretch, ...row});
        }
      }
    }
    final out = File(
      'docs/superpowers/evidence/2026-10-24-shared-motion/old-geometry.json',
    );
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'referenceCommit': '2e809f2',
        'viewport': [412, 892],
        'note':
            'Deterministic authored layout envelopes, clipped at old physical bottom; not measured rendered ink.',
        'rows': rows,
      }),
    );
  });
  test('current physical geometry comparison report', () {
    final rows = <Object>[];
    final metrics = DashboardLayoutMetrics.reference;
    for (final mode in [
      DashboardModeSpec.budget,
      DashboardModeSpec.balance,
      DashboardModeSpec.mind,
    ]) {
      for (final s in [.35, .5, .65]) {
        final f = DashboardGeometryResolver.resolve(
          metrics: metrics,
          mode: mode,
          collapseProgress: metrics.collapseTravel * s,
          isRailExpanded: false,
          hasPhysicalRail: false,
          seamlessHeaderContent: mode == DashboardModeSpec.mind,
        );
        final old = historicalMotherCard(f, mode == DashboardModeSpec.mind);
        late Rect body, visible, content;
        final oldContent = old['contentLayoutEnvelope'] as List<double>;
        content = Rect.fromLTRB(
          oldContent[0],
          oldContent[1],
          oldContent[2],
          oldContent[3],
        );
        if (mode == DashboardModeSpec.budget) {
          final t = BudgetUnifiedMotherCardGeometry.resolve(
            frame: f,
            headerRadius: BorderRadius.circular(20),
            contentRadius: BorderRadius.circular(20),
          );
          body = t.bodyBounds;
          visible = t.visibleBodyBounds;
        } else if (mode == DashboardModeSpec.balance) {
          final t = BalanceUnifiedMotherCardGeometry.resolve(
            frame: f,
            headerRadius: BorderRadius.circular(20),
            contentRadius: BorderRadius.circular(20),
          );
          body = t.bodyBounds;
          visible = t.visibleBodyBounds;
        } else {
          final t = MindUnifiedMotherCardGeometry.resolve(
            frame: f,
            headerRadius: BorderRadius.circular(20),
            contentRadius: BorderRadius.circular(20),
          );
          body = t.bodyBounds;
          visible = t.visibleBodyBounds;
          content = Rect.fromLTWH(
            t.contentBounds.center.dx -
                t.contentBounds.width * t.contentScale / 2,
            t.contentBounds.top,
            t.contentBounds.width * t.contentScale,
            t.contentBounds.height * t.contentScale,
          );
        }
        expect(body.height, greaterThanOrEqualTo(0));
        final gap = body.bottom - content.bottom;
        expect(
          body.bottom,
          lessThanOrEqualTo(f.summaryBounds.top),
          reason: '${mode.mode.name} separation=$s must clear Summary',
        );
        if (mode != DashboardModeSpec.mind) {
          expect(body.bottom, lessThan((old['body'] as List<double>)[3]));
        }
        if (mode == DashboardModeSpec.balance) {
          expect(
            gap,
            inInclusiveRange(0, BalanceAlternativeHtmlTokens.outerInset),
          );
        }
        rows.add({
          'mode': mode.mode.name,
          'separation': s,
          'oldBodyBottom': (old['body'] as List<double>)[3],
          'currentBodyTop': body.top,
          'currentBodyBottom': body.bottom,
          'currentVisibleBodyBottom': visible.bottom,
          'contentLayoutEnvelopeBottom': content.bottom,
          'bodyMinusUnclippedContentBottom': gap,
          'oldBodyMinusUnclippedContentBottom':
              old['bodyMinusUnclippedContentBottom'],
          'bottomClippedHeightFraction':
              ((content.bottom - body.bottom).clamp(0.0, content.height) /
              content.height),
          'summaryTop': f.summaryBounds.top,
          'extendsBelowSummaryTop': body.bottom > f.summaryBounds.top,
        });
      }
    }
    final out = File(
      'docs/superpowers/evidence/2026-10-24-shared-motion/current-geometry.json',
    );
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'note':
            'Authored content allocation, not ink; positive gap means trailing body; negative means clipped content allocation.',
        'rows': rows,
      }),
    );
  });
  test('all modes have equivalent normalized physical timing', () {
    final metrics = DashboardLayoutMetrics.reference;
    DashboardUnifiedMotherCardMotion resolve(
      DashboardModeSpec mode,
      double s,
    ) => DashboardUnifiedMotherCardMotion.resolve(
      frame: DashboardGeometryResolver.resolve(
        metrics: metrics,
        mode: mode,
        collapseProgress: metrics.collapseTravel * s,
        isRailExpanded: false,
        hasPhysicalRail: false,
        seamlessHeaderContent: mode == DashboardModeSpec.mind,
      ),
      headerRadius: BorderRadius.circular(20),
      contentRadius: BorderRadius.circular(20),
    );
    List<double> edges(DashboardUnifiedMotherCardMotion t) => [
      t.bodyBounds.top,
      t.bodyBounds.bottom,
      t.bodyBounds.width,
    ];
    for (final s in [0.0, .01, .05, .10, .20, .35, .50, .65, .80, .95, 1.0]) {
      List<double>? baseline;
      for (final mode in [
        DashboardModeSpec.budget,
        DashboardModeSpec.balance,
        DashboardModeSpec.mind,
      ]) {
        final first = edges(resolve(mode, 0)),
            last = edges(resolve(mode, 1)),
            current = edges(resolve(mode, s));
        final f = DashboardGeometryResolver.resolve(
          metrics: metrics,
          mode: mode,
          collapseProgress: metrics.collapseTravel * s,
          isRailExpanded: false,
          hasPhysicalRail: false,
          seamlessHeaderContent: mode == DashboardModeSpec.mind,
        );
        final adapterBody = switch (mode.mode) {
          DashboardMode.budget => BudgetUnifiedMotherCardGeometry.resolve(
            frame: f,
            headerRadius: BorderRadius.circular(20),
            contentRadius: BorderRadius.circular(20),
          ).bodyBounds,
          DashboardMode.balance => BalanceUnifiedMotherCardGeometry.resolve(
            frame: f,
            headerRadius: BorderRadius.circular(20),
            contentRadius: BorderRadius.circular(20),
          ).bodyBounds,
          DashboardMode.mind => MindUnifiedMotherCardGeometry.resolve(
            frame: f,
            headerRadius: BorderRadius.circular(20),
            contentRadius: BorderRadius.circular(20),
          ).bodyBounds,
        };
        expect(adapterBody, resolve(mode, s).bodyBounds);
        final normalized = [
          for (var i = 0; i < first.length; i++)
            (current[i] - first[i]) / (last[i] - first[i]),
        ];
        baseline ??= normalized;
        for (var i = 0; i < normalized.length; i++) {
          expect(
            normalized[i],
            closeTo(baseline[i], 1e-9),
            reason: '${mode.mode.name} master=$s edge=$i',
          );
        }
      }
    }
  });
}
