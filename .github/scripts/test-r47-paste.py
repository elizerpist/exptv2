#!/usr/bin/env python3
"""Reject a fixed fixture or unmatched source in an R47 owner report."""
import hashlib
import os
import subprocess
import tempfile
from pathlib import Path

checker = Path(__file__).with_name('r46-check-paste.py')
token = '12345678-1234-1234-1234-123456789abc'

def check(source, motion, expect, stage='FIRST_SHADER_DRAW', draw_route='FLUVI_STREAM'):
    body = ('FLUVI_R46_RECORDING_V1\nroute=FLUVI_STREAM end=USER_STOP\n' + source + '\n' +
            'R45_EVENT originWakeEpoch=1 stage=REVEAL route=FLUVI_STREAM\n' +
            f'R45_EVENT originWakeEpoch=1 stage={stage} route={draw_route}\n' + motion + '\n' +
            'spoolDropped=0 spoolFailure=none\n').encode()
    data = body + f'bodyBytes={len(body)} bodySha256={hashlib.sha256(body).hexdigest()}\nEND_FLUVI_R46_RECORDING_V1\n'.encode()
    with tempfile.TemporaryDirectory() as d:
        report = Path(d) / 'report.txt'; report.write_bytes(data)
        result = subprocess.run(['python3', str(checker), str(report), 'FLUVI_STREAM', '1'],
                                env={**os.environ, 'R47_REQUIRE_ACTIVE_HEADER': 'true'}, capture_output=True)
        assert (result.returncode == 0) == expect, result.stderr.decode()

src = f'R47_MATERIAL origin=active_header_semantic token={token}'
draw = f'R45_EVENT stage=MOTION origin=active_header_semantic token={token}'
check(src, draw, True)
check('R47_MATERIAL origin=missing', draw, False)
check(src, draw.replace(token, 'deadbeef'), False)
check(src, draw + ' palette=compiled_public_v1', False)
frame_src = f'R47_MATERIAL origin=active_header_frame_package token={token}'
frame_draw = f'R45_EVENT stage=MOTION origin=active_header_frame_package token={token}'
check(frame_src, frame_draw, True, stage='FIRST_FRAME_DRAW')
check(frame_src, draw, False, stage='FIRST_FRAME_DRAW')
check(frame_src, frame_draw.replace(token, 'deadbeef'), False, stage='FIRST_FRAME_DRAW')
check(frame_src, frame_draw, False, stage='FIRST_FRAME_DRAW', draw_route='WIDGETS_ANYWHERE')
print('PASS: both qualified source/draw kinds and six false-positive controls')
