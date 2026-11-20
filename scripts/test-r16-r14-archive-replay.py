#!/usr/bin/env python3
"""Re-evaluate the original R15-era R14 specimens, never as R16 results."""
import hashlib
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tarfile
import urllib.request
import zipfile

SOURCE = '536987c2345bf0c0cc2cb297b68c7227a0aed3c8'
BASE = ('https://media.githubusercontent.com/media/elizerpist/exptv2/'
        'd5b3acefb6a567e6fdb515eb0c50e72bf6d12476/r15-evidence/')
AGGREGATE = ('https://media.githubusercontent.com/media/elizerpist/exptv2/'
             '3efba1e12a17890c44599b62bc1cfbc28709791c/r15-evidence/'
             'r15-aggregate-28-cases-536987c2.tar.gz')
CASES = {
    'exclusion': ('r14_exclusion', 136364358907, 14640568475,
        'dc8c402d2d52e84c57c5d1a3870f6b4e0e9fd5491169ffb601555372fac22c48',
        ['before-a-before.png', 'before-a-green-reference.png', 'before-a-occluder.png',
         'after-a-occluder.png', 'after-successor-occluder.png']),
    'fresh-main': ('r14_fresh_main', 136364358688, 14639399199,
        '352b7e9e0c38018bb0b1e6f8310da8d8728a1b682bb97fb5c1d342d45eea74dc', []),
    'late-only': ('r14_late_only', 136364358744, 14638994595,
        'aefbbedc53d90634f1f8f58a818aaf1b9ba6ab394e903acda161efc0c009c499',
        ['after-a-before.png', 'after-a-green-reference.png', 'after-a-occluder.png']),
    'real-return': ('r14_real_occlusion', 136364358741, 14639708651,
        'bc0645d2af256749a41b2f9327f94ce431fbafdb8f563e52dbe3423af4409bee',
        ['independent-before.png', 'independent-green-reference.png',
         'independent-occluder.png', 'after-real-return.png']),
    'terminal-stale': ('r14_terminal_stale', 136364358975, 14640682486,
        '5950fee89a78f4179678ca0f00778ed05d19906ecc1f3ebf8ace42e82ef2adb6', []),
}


def download(url, digest):
    body = urllib.request.urlopen(url, timeout=180).read()
    if hashlib.sha256(body).hexdigest() != digest:
        raise ValueError('archived_digest_mismatch')
    return body


def main():
    repo = Path(__file__).resolve().parent.parent
    output = repo / 'android/keyguard-r16-r14-replay'
    output.mkdir(parents=True, exist_ok=False)
    fixtures = output / 'fixtures'; fixtures.mkdir()
    results = output / 'cases'; results.mkdir()
    harness = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip()
    archive_body = download(AGGREGATE, '4472aac117113a1570531ad6d41c61e8d8b923568a2156e3e8583f355ce6a2c1')
    aggregate = tarfile.open(fileobj=io.BytesIO(archive_body))
    receipts = []
    for label, (row, job, artifact, digest, images) in CASES.items():
        url = BASE + f'r15-run-44758461466-{artifact}.zip'
        body = download(url, digest)
        z = zipfile.ZipFile(io.BytesIO(body))
        root = fixtures / label; root.mkdir()
        prefix = f'android/keyguard-r14-candidate/{label}/'
        for leaf in ('identity.txt', 'instrumentation.txt', 'process-identity.txt'):
            (root / leaf).write_bytes(z.read(prefix + leaf))
        identity = dict(line.split('=', 1) for line in (root / 'identity.txt').read_text().splitlines() if '=' in line)
        if identity.get('source') != SOURCE or not identity.get('run_uuid'):
            raise ValueError('archived_identity_mismatch')
        probe = prefix + f'probe/files/keyguard-service-probe/r14/{identity["run_uuid"]}/{label}/'
        needed = ['fixture.txt', 'capture.txt', *images]
        if label in ('exclusion', 'fresh-main', 'late-only'):
            needed += ['queue-and-reads.txt', 'g1-withdrawal-marks.txt']
        for leaf in needed:
            (root / leaf).write_bytes(z.read(probe + leaf))
        for leaf in ('app-before', 'app-after', 'test-before', 'test-after', 'run-metadata.json'):
            member = aggregate.getmember(f'materialized-pending/{row}-SURFACE_LIVE/{leaf}')
            stream = aggregate.extractfile(member)
            if stream is None: raise ValueError('archived_receipt_missing')
            (root / leaf).write_bytes(stream.read())
        receipts.append(dict(label=label, row=row, job=job, artifact=artifact, url=url,
                             archive_sha256=digest, run_uuid=identity['run_uuid']))
    (output / 'archive-receipts.json').write_text(json.dumps(dict(application_source=SOURCE,
        replay_harness=harness, original_run=44758461466, cases=receipts), indent=2) + '\n')
    env = os.environ.copy(); env['R16_R14_FIXTURE_DIR'] = str(fixtures)
    commands = [
        ('aggregate-controls', [sys.executable, str(repo / 'scripts/test-keyguard-r14-aggregate.py')]),
        ('manifest-controls', [sys.executable, str(repo / 'scripts/test-keyguard-r15-case-manifest.py')]),
        ('archive-adversarial', [sys.executable, str(repo / 'scripts/test-r16-r14-replay.py')]),
    ]
    failed = False
    for label, cmd in commands:
        proc = subprocess.run(cmd, cwd=repo, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (output / f'{label}.log').write_bytes(proc.stdout)
        print(label, 'PASS' if proc.returncode == 0 else 'FAIL', flush=True)
        failed |= proc.returncode != 0
    for label, (row, job, artifact, digest, images) in CASES.items():
        root = fixtures / label
        cmd = [sys.executable, str(repo / 'scripts/keyguard-r15-case-manifest.py'),
            '--source', SOURCE, '--scope', 'r14_recovery_candidate', '--row', row, '--route', 'SURFACE_LIVE',
            '--run-id', '44758461466', '--job-id', str(job), '--identity', str(root / 'identity.txt'),
            '--process', str(root / 'process-identity.txt'), '--transcript', str(root / 'instrumentation.txt'),
            '--fixture', str(root / 'fixture.txt'), '--app-before', str(root / 'app-before'),
            '--app-after', str(root / 'app-after'), '--test-before', str(root / 'test-before'),
            '--test-after', str(root / 'test-after'), '--run-metadata', str(root / 'run-metadata.json'),
            '--capture', str(root / 'capture.txt'), '--visual-dir', str(root), '--replay-harness', harness,
            '--out', str(results / label)]
        if (root / 'queue-and-reads.txt').is_file():
            cmd += ['--queue', str(root / 'queue-and-reads.txt')]
        proc = subprocess.run(cmd, cwd=repo, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (output / f'case-{label}.log').write_bytes(proc.stdout)
        print(label, proc.stdout.decode(errors='replace').strip(), flush=True)
        failed |= proc.returncode != 0
    (output / 'status.txt').write_text(f'archived_source={SOURCE}\nreplay_harness={harness}\n'
        f'current_candidate_28_row_gain=0\nresult={"FAIL" if failed else "PASS"}\n')
    return int(failed)


if __name__ == '__main__':
    raise SystemExit(main())
