#!/usr/bin/env python3
"""Materialize six exact run-44757517198 cases from their UUID-bound ZIP entries."""
import argparse
import importlib.util
import json
import re
import sys
import zipfile
from pathlib import Path

sys.dont_write_bytecode = True
base = Path('/workspace/outputs/r15-continuation')
app = Path('/workspace/r15-continuation-app')
spec = importlib.util.spec_from_file_location('case', app / 'scripts/keyguard-r15-case-manifest.py')
case = importlib.util.module_from_spec(spec)
spec.loader.exec_module(case)
z = zipfile.ZipFile(base / 'run-44757517198/artifact.zip')
root = 'android/keyguard-r12-candidate-r12_contract'
source = '536987c2345bf0c0cc2cb297b68c7227a0aed3c8'
raw_root = base / 'contract-materialization-raw'
out_root = base / 'materialized-contract'
raw_root.mkdir(exist_ok=True)
out_root.mkdir(exist_ok=True)


def take(member, dest):
    data = z.read(member)
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)
    return dest


def inputs(label, target):
    prefix = f'{root}/{label}'
    data = {}
    for key, member in {
        'identity': f'{prefix}/identity.txt', 'process': f'{prefix}/process-identity.txt',
        'transcript': f'{prefix}/instrumentation.txt',
        'app_before': f'{root}/installed-app-sha256.txt', 'test_before': f'{root}/installed-test-sha256.txt',
        'app_after': f'{prefix}/installed-app-after-sha256.txt', 'test_after': f'{prefix}/installed-test-after-sha256.txt',
    }.items():
        data[key] = take(member, target / key)
    identity = case.key_values(data['identity'].read_text())
    return data, identity['run_uuid'], prefix


for route in ('SURFACE_LIVE', 'SURFACE_STATIC', 'LEGACY_R11'):
    row = 'r13_service_demand_burst'
    raw = raw_root / (row + '-' + route)
    data, run_id, prefix = inputs('financial_service_' + route, raw)
    fixture = take(f'{prefix}/probe/files/keyguard-service-probe/r15-contract/{run_id}/financial-main/fixture.txt', raw / 'fixture')
    args = argparse.Namespace(source=source, scope='r12_contract', row=row, route=route, run_id=44757517198,
        job_id=136361053242, fixture=fixture, run_metadata=base / 'preflight/run-44757517198.json',
        out=out_root / (row + '-' + route), capture=None, report=[], **data)
    _, errors = case.make(args)
    print(row, route, 'PASS' if not errors else 'FAIL ' + ','.join(errors), flush=True)

for route in ('SURFACE_LIVE', 'SURFACE_STATIC', 'LEGACY_R11'):
    row = 'r12_selector_persistence'
    raw = raw_root / (row + '-' + route)
    first, id1, first_prefix = inputs('selector_' + route + '_one', raw / 'one')
    second, id2, second_prefix = inputs('selector_' + route + '_two', raw / 'two')
    if id1 != id2:
        raise ValueError('selector case UUID differs between phases')
    first_dir = f'{first_prefix}/probe/files/keyguard-service-probe/r15-contract/{id1}/selector'
    second_dir = f'{second_prefix}/probe/files/keyguard-service-probe/r15-contract/{id2}/selector'
    phase_one_fixture = take(first_dir + '/phase-one.txt', raw / 'one/fixture')
    phase_one_receipt = take(first_dir + '/phase-one.properties', raw / 'one/store-receipt')
    fixture = take(second_dir + '/phase-two.txt', raw / 'two/fixture')
    args = argparse.Namespace(source=source, scope='r12_contract', row=row, route=route, run_id=44757517198,
        job_id=136361053242, fixture=fixture, run_metadata=base / 'preflight/run-44757517198.json',
        out=out_root / (row + '-' + route), capture=None, report=[],
        phase_one_fixture=phase_one_fixture, phase_one_receipt=phase_one_receipt,
        **{'phase_one_' + key: value for key, value in first.items()}, **second)
    _, errors = case.make(args)
    print(row, route, 'PASS' if not errors else 'FAIL ' + ','.join(errors), flush=True)
