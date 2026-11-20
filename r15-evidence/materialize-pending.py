#!/usr/bin/env python3
"""Bind incomplete/failed rows to their own existing single-method evidence."""
import argparse,importlib.util,sys,zipfile
from pathlib import Path
sys.dont_write_bytecode=True
base=Path('/workspace/outputs/r15-continuation');app=Path('/workspace/r15-continuation-app')
spec=importlib.util.spec_from_file_location('case',app/'scripts/keyguard-r15-case-manifest.py');case=importlib.util.module_from_spec(spec);spec.loader.exec_module(case)
source='536987c2345bf0c0cc2cb297b68c7227a0aed3c8';rawroot=base/'pending-materialization-raw';outroot=base/'materialized-pending'
def take(z,member,path):
 path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(z.read(member));return path
def emit(path,prefix,app_root,row,route,scope,run,job,fixture_for):
 raw=rawroot/(row+'-'+route);out=outroot/(row+'-'+route)
 with zipfile.ZipFile(path) as z:
  members={'identity':prefix+'/identity.txt','process':prefix+'/process-identity.txt','transcript':prefix+'/instrumentation.txt','app_before':app_root+'/installed-app-sha256.txt','test_before':app_root+'/installed-test-sha256.txt','app_after':prefix+'/installed-app-after-sha256.txt','test_after':prefix+'/installed-test-after-sha256.txt'}
  data={k:take(z,n,raw/k) for k,n in members.items()};uid=case.key_values(data['identity'].read_text())['run_uuid']
  fixture=take(z,fixture_for(prefix,uid),raw/'fixture.txt')
  args=argparse.Namespace(source=source,scope=scope,row=row,route=route,run_id=run,job_id=job,fixture=fixture,run_metadata=base/'preflight'/f'run-{run}.json',out=out,capture=None,report=[],**data)
  _,errors=case.make(args);print(row,route,'PASS' if not errors else 'FAIL:'+','.join(errors),flush=True)
for route,label,run,job in [('SURFACE_LIVE','live',44757516332,136361052168),('SURFACE_STATIC','static',44757517210,136361052923),('LEGACY_R11','legacy',44757516622,136361051838)]:
 root='android/keyguard-r12-candidate-r12_'+label
 for name,row,sub in [('first_composite_fixture','r12_real_service_first_composite','first-composite'),('privacy_fixture','r12_real_service_privacy_downgrade','privacy-downgrade'),('holder_fixture','r12_holder_lifecycle_races','holder-generation')]:
  emit(base/f'run-{run}/artifact.zip',root+'/'+name,root,row,route,'r12_'+label,run,job,lambda p,u,s=sub:p+'/probe/files/keyguard-service-probe/r15-contract/'+u+'/'+s+'/fixture.txt')
root='android/keyguard-r12-candidate-r12_contract';zpath=base/'run-44757517198/artifact.zip'
emit(zpath,root+'/r12_ordered',root,'r12_ordered','LEGACY_R11','r12_contract',44757517198,136361053242,lambda p,u:p+'/probe/files/keyguard-service-probe/r12-admission/'+u+'/fixture.txt')
emit(zpath,root+'/r12_occlusion',root,'r12_occlusion','LEGACY_R11','r12_contract',44757517198,136361053242,lambda p,u:p+'/probe/files/keyguard-service-probe/fixture.txt')
for artifact,label,row,job in [('14640568475','exclusion','r14_exclusion',136364358907),('14639399199','fresh-main','r14_fresh_main',136364358688),('14638994595','late-only','r14_late_only',136364358744),('14639708651','real-return','r14_real_occlusion',136364358741),('14640682486','terminal-stale','r14_terminal_stale',136364358975)]:
 root='android/keyguard-r14-candidate/'+label
 emit(base/'run-44758461466/archives'/f'{artifact}.zip',root,root,row,'SURFACE_LIVE','r14_recovery_candidate',44758461466,job,lambda p,u,l=label:p+'/probe/files/keyguard-service-probe/r14/'+u+'/'+l+'/fixture.txt')
