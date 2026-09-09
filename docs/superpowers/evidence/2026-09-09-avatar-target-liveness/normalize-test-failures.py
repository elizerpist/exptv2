from pathlib import Path
import hashlib
import json
import re
import sys

source = Path(sys.argv[1])
destination = Path(sys.argv[2])
text = re.sub(r'\x1b\[[0-9;]*m', '', source.read_text())
header = re.compile(r'^\+\d+(?: -\d+)?: .*?(test/[^\n]+\.dart): (.*?)( \[E\])?$')
records = {}
current = None
exception = None
failed_output = False

def normalize(lines):
    value = '\n'.join(lines).strip()
    value = re.sub(r'/data/data/com\.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi-(?:avatar-target-liveness|e8-milestone-time-window-avatar-first-load)-codex-20260909', '<WORKTREE>', value)
    value = re.sub(r'── callback \d+ ──', '── callback <ID> ──', value)
    return value

for line in text.splitlines():
    match = header.match(line)
    if match:
        current = match.group(1), match.group(2)
        record = records.setdefault(current, {'exceptions': [], 'error': [], 'failed': False})
        failed_output = bool(match.group(3))
        record['failed'] |= failed_output
        continue
    if current is None:
        continue
    if 'EXCEPTION CAUGHT BY' in line:
        exception = []
        records[current]['exceptions'].append(exception)
        continue
    if exception is not None:
        if re.match(r'^═{5,}$', line):
            exception = None
        else:
            exception.append(line)
        continue
    if failed_output:
        records[current]['error'].append(line)

failures = []
for (file, name), record in sorted(records.items()):
    if not record['failed']:
        continue
    evidence = [normalize(lines) for lines in record['exceptions']]
    error = normalize(record['error'])
    # Runner termination summary is not part of a test's assertion evidence.
    error = re.sub(r'\n\+\d+ -\d+: Some tests failed\.\s*$', '', error)
    evidence.append(error)
    encoded = json.dumps(evidence, ensure_ascii=False, separators=(',', ':')).encode()
    failures.append({'file': file, 'test': name, 'normalized_output': evidence, 'normalized_sha256': hashlib.sha256(encoded).hexdigest()})

result = {'raw_log_sha256': hashlib.sha256(source.read_bytes()).hexdigest(), 'failure_count': len(failures), 'normalization': ['remove runner progress/test interleaving', 'replace worktree path', 'replace scheduler callback registration ID; preserve assertion values and stack locations'], 'failures': failures}
destination.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({'file': str(destination), 'failure_count': len(failures), 'exception_counts': [len(f['normalized_output']) - 1 for f in failures]}))
