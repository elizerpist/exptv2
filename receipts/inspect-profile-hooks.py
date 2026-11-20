#!/usr/bin/env python3
"""Inspect the downloaded profile APK DEX without storing it on the full disk."""
import hashlib
import io
import json
import os
import re
import subprocess
import urllib.request
import zipfile

url = ('https://media.githubusercontent.com/media/elizerpist/exptv2/'
       '4b3f421a871a40cf7c9d7fa972b9057d63179429/'
       'fluvi_R16_HUMAN_DIAGNOSTIC_7c49a2238629.apk')
data = urllib.request.urlopen(url, timeout=180).read()
digest = hashlib.sha256(data).hexdigest()
assert digest == '5837bcc8a2711396a38a3436d7f45e3b2f96f66302648c994ebe0736235345d9'
archive = zipfile.ZipFile(io.BytesIO(data))
env = os.environ.copy()
env['LD_PRELOAD'] = '/workspace/outputs/r16/dexdump-proc-fd.so'
result = []
for name in archive.namelist():
    if not re.fullmatch(r'classes\d*\.dex', name):
        continue
    fd = os.memfd_create('r16-dex', 0)
    content = archive.read(name)
    assert os.write(fd, content) == len(content)
    os.lseek(fd, 0, 0)
    proc = subprocess.Popen(['/workspace/.toolchains/android-sdk/build-tools/36.0.0/dexdump',
        '-d', f'/proc/self/fd/{fd}'], pass_fds=(fd,), env=env, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, text=True, errors='replace')
    hits = []
    current_method = ''
    for line in proc.stdout:
        method = re.search(r'\|\[[0-9a-fA-F]+\]\s+([^\s]+)', line)
        if method:
            current_method = method.group(1)
        if (re.search(r'KeyguardR(?:15Acquisition|16Layer)TestHooks', line)
                and re.search(r'\|[0-9a-fA-F]+:', line)):
            hits.append({'method': current_method, 'instruction': line.strip(),
                         'self': bool(re.search(r'KeyguardR(?:15Acquisition|16Layer)TestHooks\.', current_method))})
    error = proc.stderr.read()
    code = proc.wait()
    os.close(fd)
    if code:
        raise RuntimeError(f'dexdump {name} rc={code}: {error[-500:]}')
    external = [hit for hit in hits if not hit['self']]
    result.append({'dex': name, 'self_reference_count': len(hits) - len(external),
                   'external_reference_count': len(external), 'external_examples': external[:12]})
report = {
    'apk_sha256': digest,
    'initial_attempts': ['O_NOFOLLOW on /proc/self/fd (ELOOP)', 'UTF-8 decoder rejected a DEX string'],
    'inspection': 'SDK DEX disassembly with a self-fd-only open shim; no separate release APK',
    'dexes': result,
}
with open('/workspace/outputs/r16/profile-dex-hooks.json', 'w') as f:
    json.dump(report, f, indent=2)
    f.write('\n')
print(json.dumps(report, indent=2))
