#!/usr/bin/env python3
"""Compare exact named JUnit results without conflating absent tests with passes."""
from __future__ import annotations
import argparse
import json
import tarfile
import xml.etree.ElementTree as ET
from pathlib import Path


def load(path: Path) -> dict:
    result = {'tests':{}, 'xml_files':[], 'service_status':'UNOBSERVED'}
    if not path.exists(): return result
    with tarfile.open(path,'r:gz') as archive:
        for item in archive:
            if not item.isfile(): continue
            if item.name.endswith('.xml') and 'androidTest-results/connected' in item.name:
                stream=archive.extractfile(item)
                try: root=ET.parse(stream).getroot()
                except ET.ParseError: continue
                result['xml_files'].append(item.name)
                for case in root.iter('testcase'):
                    key=case.get('classname','?')+'#'+case.get('name','?')
                    failures=[f for kind in ('failure','error') for f in case.findall(kind)]
                    status='FAIL' if failures else 'SKIP' if case.find('skipped') is not None else 'PASS'
                    result['tests'][key]={'status':status,'time':case.get('time'),
                        'failure':(failures[0].get('message','') if failures else '')[:600]}
            if item.name.endswith('keyguard-lower-environment/runtime-status.txt'):
                result['runtime_status']=archive.extractfile(item).read().decode(errors='replace')
            if 'keyguard-service-evidence/' in item.name and item.name.endswith('instrumentation.txt'):
                body=archive.extractfile(item).read().decode(errors='replace')
                result['service_status']='PASS' if 'OK (2 tests)' in body else 'FAIL_OR_INCOMPLETE'
                result['service_lines']=[line for line in body.splitlines() if 'FAILURES!!!' in line or 'Tests run:' in line or line.startswith('OK (')]
    return result

p=argparse.ArgumentParser(); p.add_argument('baseline',type=Path); p.add_argument('candidate',type=Path); p.add_argument('out',type=Path)
a=p.parse_args(); baseline=load(a.baseline); candidate=load(a.candidate)
keys=set(baseline['tests'])|set(candidate['tests'])
comparison={name:{'baseline':baseline['tests'].get(name,{'status':'NOT_RUN'}),
                  'candidate':candidate['tests'].get(name,{'status':'NOT_RUN'})}
            for name in sorted(keys)}
summary={}
for label, arm in [('baseline',baseline),('candidate',candidate)]:
    statuses=[item['status'] for item in arm['tests'].values()]
    summary[label]={'tests':len(statuses),'pass':statuses.count('PASS'),'fail':statuses.count('FAIL'),
                    'skip':statuses.count('SKIP'),'xml_files':arm['xml_files'],
                    'service':arm['service_status'],'runtime_status':arm.get('runtime_status','UNOBSERVED')}
output={'summary':summary,'comparison':comparison}
a.out.write_text(json.dumps(output,indent=2,sort_keys=True)+'\n')
print(json.dumps(summary,sort_keys=True))
for name,item in comparison.items():
    b=item['baseline']['status']; c=item['candidate']['status']
    if b!='PASS' or c!='PASS': print(f'{b:7} {c:7} {name}')
