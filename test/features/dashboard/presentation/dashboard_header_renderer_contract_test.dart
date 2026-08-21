import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_field_mesh.dart';

void main() {
  group('maximum-quality Header renderer contract', () {
    test(
      'applies Header opacity once after an opaque mesh instead of at every vertex',
      () {
        final opacity = DashboardHeaderFieldLayerOpacity.resolve(.57);

        // Per-vertex alpha creates the visible cell seams from the physical
        // screenshot when adjacent antialiased mesh triangles are composited
        // over three Header effect layers.  The source visual opacity belongs
        // to the whole layer instead.
        expect(opacity.vertexAlpha, 255);
        expect(opacity.compositeAlpha, 145);
      },
    );

    test(
      'retains the mesh backend across phase-only paints and recreates vertices only after a color generation',
      () {
        final mesh = DashboardHeaderInterpolatedFieldMesh();
        final geometry = DashboardHeaderFieldSamplingGeometry.resolve(
          logicalSize: const Size(360, 84),
          devicePixelRatio: 3,
          renderScale: 1,
        );
        expect(mesh.configure(geometry), isTrue);
        expect(mesh.configure(geometry), isFalse);
        for (var index = 0; index < mesh.vertexCount; index += 1) {
          mesh.setArgb(index, const Color(0xff8b3eff).toARGB32());
        }

        final first = ui.PictureRecorder();
        mesh.draw(
          Canvas(first),
          opacity: DashboardHeaderFieldLayerOpacity.resolve(1),
        );
        first.endRecording().dispose();
        expect(mesh.verticesGeneration, 1);

        final second = ui.PictureRecorder();
        mesh.draw(
          Canvas(second),
          opacity: DashboardHeaderFieldLayerOpacity.resolve(1),
        );
        second.endRecording().dispose();
        expect(
          mesh.verticesGeneration,
          1,
          reason:
              'a phase-only paint must reuse the stable native mesh backend',
        );

        mesh.setArgb(0, const Color(0xffff8bda).toARGB32());
        final third = ui.PictureRecorder();
        mesh.draw(
          Canvas(third),
          opacity: DashboardHeaderFieldLayerOpacity.resolve(.96),
        );
        third.endRecording().dispose();
        expect(mesh.verticesGeneration, 2);
      },
    );

    test(
      'maximum spatial quality keeps display-rate phase updates even when the source control is set to 100',
      () {
        // `frameMs` is the audited source field-step value. It may bound a
        // source-field refresh, but it must not make the production maximum
        // quality visual lane visibly advance only at 10 Hz.
        expect(
          DashboardHeaderRenderCadence.effectiveFrameMs(
            renderScale: 1,
            sourceFrameMs: 100,
          ),
          16,
        );
      },
    );
  });
}
