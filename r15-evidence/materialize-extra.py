#!/usr/bin/env python3
"""Materialize only qualifying UUID-bound samples from original Actions ZIPs."""
import argparse, importlib.util, sys, zipfile
from pathlib import Path
sys.dont_write_bytecode=True
base=Path('/workspace/outputs/r15-continuation')
app=Path('/workspace/r15-continuation-app')
spec=importlib.util.spec_from_file_location('case',app/'scripts/keyguard-r15-case-manifest.py')
case=importlib.util.module_from_spec(spec);spec.loader.exec_module(case)
source='536987c2345bf0c0cc2cb297b68c7227a0aed3c8'
rawroot=base/'extra-materialization-raw';outroot=base/'materialized-extra'
rawroot.mkdir(exist_ok=True);outroot.mkdir(exist_ok=True)
def take(z,member,path):
    path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(z.read(member));return path
def build(z,prefix,app_root,raw):
    files={'identity':prefix+'/identity.txt','process':prefix+'/process-identity.txt','transcript':prefix+'/instrumentation.txt','app_before':app_root+'/installed-app-sha256.txt','test_before':app_root+'/installed-test-sha256.txt','app_after':prefix+'/installed-app-after-sha256.txt','test_after':prefix+'/installed-test-after-sha256.txt'}
    data={k:take(z,m,raw/k) for k,m in files.items()}
    return data,case.key_values(data['identity'].read_text())['run_uuid']
def emit(zpath,prefix,app_root,row,route,scope,run,job,report_kind=None):
    print('attempt',row,route,flush=True)
    raw=rawroot/(row+'-'+route);out=outroot/(row+'-'+route)
    with zipfile.ZipFile(zpath) as z:
        data,uid=build(z,prefix,app_root,raw)
        if report_kind:
            root=prefix+'/probe/files/keyguard-service-probe/r14/'+uid+'/'+report_kind
            reports=[take(z,root+'/'+mode+'-report.txt',raw/(mode+'-report.txt')) for mode in (['LIGHT','FULL'] if route=='LIGHT_FULL' else [route])]
            fixture=reports[0];capture=None
        else:
            root=prefix+'/probe/files/keyguard-service-probe/r12-timing/'+uid
            fixture=take(z,root+'/fixture.txt',raw/'fixture.txt');capture=take(z,root+'/capture.txt',raw/'capture.txt');reports=[]
        args=argparse.Namespace(source=source,scope=scope,row=row,route=route,run_id=run,job_id=job,fixture=fixture,run_metadata=base/'preflight'/f'run-{run}.json',out=out,capture=capture,report=reports,**data)
        c,e=case.make(args)
        print(row,route,'PASS' if not e else 'FAIL:'+','.join(e),flush=True)
for mode in ['LIGHT','FULL']:
    emit(base/'run-44758461466/archives/14639464073.zip','android/keyguard-r14-candidate/r15-combined-recovery','android/keyguard-r14-candidate/r15-combined-recovery','r14_pressure',mode,'r14_recovery_candidate',44758461466,136364359228,'combined-pressure')
emit(base/'run-44758461466/archives/14639897873.zip','android/keyguard-r14-candidate/pressure-combined','android/keyguard-r14-candidate/pressure-combined','r12_pressure','LIGHT_FULL','r14_recovery_candidate',44758461466,136364358828,'existing-pressure')
for route,label,run,job in [('SURFACE_LIVE','live',44757516332,136361052168),('SURFACE_STATIC','static',44757517210,136361052923),('LEGACY_R11','legacy',44757516622,136361051838)]:
    root='android/keyguard-r12-candidate-r12_'+label
    emit(base/f'run-{run}/artifact.zip',root+'/timing',root,'r12_natural_timing',route,'r12_'+label,run,job)
