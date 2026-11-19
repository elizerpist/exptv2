#!/usr/bin/env python3
"""Host negative controls for the exact-pair oracle; never Android evidence."""
import importlib.util
import sys
sys.dont_write_bytecode = True
import io
from pathlib import Path
import tarfile
import tempfile
import zipfile

path = Path(__file__).resolve().with_name('validate-keyguard-r12-admission.py')
spec = importlib.util.spec_from_file_location('r12_validator', path)
v = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v)
RUN='bf28a647-f5d5-43a0-bdde-880ef59ae58f'
CAP='f0ec6e52-1ea3-41c0-b8db-47694470be7b'
HARNESS='a'*40
CANDIDATE='b'*40
HASH='c'*64

def sample(role, req, ordinal):
    return dict(stage='SYSTEM_SAMPLE', role=role, req=req, ordinal=str(ordinal),
                available='true', primary='true', interactive='true', displayOn='true',
                displayOff='false', locked='true', userUnlocked='true')

def specimen(mode):
    app = v.STOCK if mode == 'baseline' else CANDIDATE
    manifest = dict(run=RUN, mode=mode, app=app, harness=HARNESS, api='35', abi='x86_64',
                    app_hash=HASH, test_hash=HASH, installed_app_hash=HASH, installed_test_hash=HASH,
                    instrument_rc='0', log_rc='0', probe_rc='0', window_rc='0', identity_rc='0',
                    extract_rc='0', preflight='PASS', forced_stop='PASS', pid='123')
    auth = dict(session='4', wake='7', epoch='10', interaction='2', attach='0')
    astart = dict(stage='READER_START', role='A', req='10', **auth)
    bstart = dict(stage='READER_START', role='B', req='11', **auth)
    rows = [dict(stage='RUN', appSha=app, harnessSha=HARNESS, pid='123', mode='FULL'),
            dict(stage='CAPTURE', mode='FULL'), astart, sample('A','10',1),
            dict(stage='A_TREE',req='10',unmasked='MAIN_KEYGUARD',masked='UNKNOWN',maskedReason='NO_MAIN_MARKER',mask='SYNTHETIC_NEGATIVE'),
            dict(stage='B_OFFER',req='11',freshness='FRAMEWORK_EVENT',freshnessRevision='5',outstanding='FRAMEWORK_EVENT',**auth), sample('A','10',2)]
    if mode == 'candidate': rows.append(bstart)
    rows += [dict(stage='APPLY_ENTER',role='A',req='10',decision='HIDDEN_UNKNOWN'),
             dict(stage='A_BOUNDARY',req='10',decision='HIDDEN_UNKNOWN',detached='true',authority='true',b='11',active='11' if mode == 'candidate' else '10',pending='none' if mode == 'candidate' else '11')]
    rows.append(dict(stage='A_FRESHNESS',req='10',b='11',revision='5',outstanding='FRAMEWORK_EVENT'))
    if mode == 'candidate':
        rows += [sample('B','11',1), dict(stage='B_TREE',req='11',unmasked='MAIN_KEYGUARD',reason='MAIN_CONFIRMED'),sample('B','11',2)]
    rows += [dict(stage='A_RELEASE_SIGNAL',req='10',b='11',bStarted='true' if mode == 'candidate' else 'false'),
             dict(stage='A_RELEASED',req='10'),dict(stage='APPLY_EXIT',role='A',req='10',decision='HIDDEN_UNKNOWN',detached='true')]
    if mode == 'baseline':
        rows += [bstart,sample('B','11',1),dict(stage='B_TREE',req='11',unmasked='MAIN_KEYGUARD',reason='MAIN_CONFIRMED'),sample('B','11',2)]
    rows += [dict(stage='APPLY_ENTER',role='B',req='11',decision='SHOW_FULL'),dict(stage='APPLY_EXIT',role='B',req='11',decision='SHOW_FULL'),
             dict(stage='ORDER',a='10',b='11',bStartedBeforeARelease='true' if mode == 'candidate' else 'false',maximumReaders='1',specimen='VALID')]
    if mode == 'baseline': rows.append(dict(stage='FAILURE',type='AssertionError'))
    rows += [dict(stage='FINALLY_RELEASE'),dict(stage='CLEANUP',status='PASS',specimen='VALID')]
    fixture='\n'.join('R12 '+ ' '.join(f'{k}={value}' for k,value in dict(row, seq=str(i),up=str(500+i),tid='123',run=RUN,capture='not-started' if row['stage']=='RUN' else CAP).items()) for i,row in enumerate(rows,1))+'\n'
    exact=[]
    for req, reason, decision in [('10','NO_MAIN_MARKER','HIDDEN_UNKNOWN'),('11','MAIN_CONFIRMED','SHOW_FULL')]:
        row=dict(capture=CAP,process='123-abc',session='4',wake='7',req=req,stage='INSPECTION_FINISHED',reason=reason,
                 surfaceClassification=decision,rootUnavailable='false',walkTruncated='false',abortedStale='false',
                 requestVisibilityEpoch='10',requestInteractionEpoch='2',requestWakeGeneration='7')
        exact.append(' '.join(f'{k}={value}' for k,value in row.items()))
    exact='\n'.join(exact)+'\n'
    header=f'INSTRUMENTATION_STATUS: class={v.CLASS}\nINSTRUMENTATION_STATUS: numtests=1\nINSTRUMENTATION_STATUS: test={v.METHOD}\nINSTRUMENTATION_STATUS_CODE: 1\nINSTRUMENTATION_STATUS: test={v.METHOD}\n'
    output = header + (f'INSTRUMENTATION_STATUS: stack=java.lang.AssertionError: {v.ASSERTION}\nINSTRUMENTATION_STATUS_CODE: -2\nFAILURES!!!\nTests run: 1,  Failures: 1\n' if mode == 'baseline' else 'INSTRUMENTATION_STATUS_CODE: 0\nOK (1 test)\n') + 'INSTRUMENTATION_CODE: -1\n'
    capture=f'captureId={CAP}\nprocessInstance=123-abc\n'
    expected=dict(run=RUN,mode=mode,app=app,harness=HARNESS)
    return [manifest, output, fixture, exact, capture, expected]

def passes(data):
    return v.validate(*data)

def rejects(name, data):
    try: passes(data)
    except (v.Invalid, ValueError): return
    raise AssertionError('accepted invalid ' + name)

for mode in ('baseline','candidate'):
    assert passes(specimen(mode))['verdict'].startswith('RED_EXPECTED=' if mode == 'baseline' else 'PASS=')

for name, transform in [
    ('wrong decision', lambda d: d.__setitem__(2,d[2].replace('decision=HIDDEN_UNKNOWN','decision=HIDDEN_SCREEN',1))),
    ('wrong A id', lambda d: d.__setitem__(3,d[3].replace('req=10','req=12',1))),
    ('root unavailable', lambda d: d.__setitem__(3,d[3].replace('reason=NO_MAIN_MARKER','reason=ROOT_UNAVAILABLE',1))),
    ('no windows', lambda d: d.__setitem__(3,d[3].replace('reason=NO_MAIN_MARKER','reason=NO_WINDOWS',1))),
    ('truncated', lambda d: d.__setitem__(3,d[3].replace('walkTruncated=false','walkTruncated=true',1))),
    ('stale result', lambda d: d.__setitem__(3,d[3].replace('abortedStale=false','abortedStale=true',1))),
    ('unrelated capture', lambda d: d.__setitem__(3,d[3].replace('capture='+CAP,'capture=3e4024fd-05f8-47bd-b18e-96ab91625b58',1))),
    ('missing exact A', lambda d: d.__setitem__(3,d[3].splitlines()[1]+'\n')),
    ('wrong epoch', lambda d: d.__setitem__(3,d[3].replace('requestVisibilityEpoch=10','requestVisibilityEpoch=11',1))),
    ('B superseded', lambda d: d.__setitem__(2,d[2].replace('pending=11','pending=12',1))),
    ('wrong B', lambda d: d.__setitem__(2,d[2].replace('req=11 freshness=', 'req=12 freshness=',1))),
    ('stale uuid', lambda d: d[0].__setitem__('run','b2978ce6-f584-4432-9c23-e4e41d9e23dc')),
    ('timed out adb', lambda d: d[0].__setitem__('instrument_rc','124')),
    ('source mismatch', lambda d: d[0].__setitem__('app','0'*40)),
    ('bad api', lambda d: d[0].__setitem__('api','34')),
    ('missing method', lambda d: d.__setitem__(1,d[1].replace(v.METHOD,'wrongMethod'))),
    ('wrong failure', lambda d: d.__setitem__(1,d[1].replace(v.ASSERTION,'fixture was not ready'))),
    ('probe missing', lambda d: d[0].__setitem__('probe_rc','1')),
    ('apk changed', lambda d: d[0].__setitem__('installed_app_hash','d'*64)),
    ('dirty/preflight', lambda d: d[0].__setitem__('preflight','FAIL')),
    ('force stop stale', lambda d: d[0].__setitem__('forced_stop','FAIL')),
    ('suppressed cleanup', lambda d: d.__setitem__(1,d[1]+'Suppressed: java.lang.Exception\n')),
    ('extra exception', lambda d: d.__setitem__(1,d[1]+'Caused by: java.lang.IllegalStateException: invalid\n')),
    ('failed cleanup', lambda d: d.__setitem__(2,d[2].replace('status=PASS specimen=VALID','status=FAIL specimen=VALID'))),
    ('stock presented candidate', lambda d: d[5].__setitem__('mode','candidate')),
]:
    data=specimen('baseline')
    transform(data)
    rejects(name,data)

candidate=specimen('candidate')
candidate[2]=candidate[2].replace('bStartedBeforeARelease=true','bStartedBeforeARelease=false')
rejects('candidate serial order',candidate)

with tempfile.TemporaryDirectory() as d:
    archive=Path(d)/'fixture.tar'
    with tarfile.open(archive,'w') as out:
        for name, text in zip(('fixture.txt','exact-events.txt','capture.txt'),specimen('baseline')[2:5]):
            raw=text.encode()
            info=tarfile.TarInfo(f'{RUN}/{name}'); info.size=len(raw)
            out.addfile(info,io.BytesIO(raw))
    assert set(v.read_tar(archive,RUN)) == {'fixture.txt','exact-events.txt','capture.txt'}
    try: v.read_tar(archive,'47c05835-33d3-40ad-8a81-d698edb5e2d2')
    except v.Invalid: pass
    else: raise AssertionError('stale archive accepted')
    archive.write_bytes(b'not-a-tar')
    try: v.read_tar(archive,RUN)
    except tarfile.TarError: pass
    else: raise AssertionError('bad tar accepted')

old=Path('/workspace/outputs/r12/preflight/baseline-run-3-artifact.zip')
if old.exists():
    with zipfile.ZipFile(old) as z:
        data=specimen('baseline')
        data[1]=z.read('android/keyguard-r12-admission-baseline/instrumentation.txt').decode()
        data[2]=z.read('android/keyguard-r12-admission-baseline/probe/files/keyguard-service-probe/r12-admission/fixture.txt').decode()
        rejects('actual 44613950007 failure',data)
print('PASS exact stock/candidate positive controls; 26 correlated failure, source, runner, cleanup and TAR controls')
