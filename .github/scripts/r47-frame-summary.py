#!/usr/bin/env python3
"""Conservative case report from retained video/crop observations."""
import importlib.util
import json
import re
import sys
from pathlib import Path

root=Path(sys.argv[1]); target=root/'frame-correlation-verdict.json'
spec=importlib.util.spec_from_file_location('verdict',Path(__file__).with_name('r47-frame-verdict.py'))
v=importlib.util.module_from_spec(spec); spec.loader.exec_module(v)

def read(method):
    directory=root/method
    summary_file=directory/'frame-extract-summary.json'
    summary=json.loads(summary_file.read_text()) if summary_file.exists() else {}
    path=directory/'all-frame-observations.jsonl'
    rows=[json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []
    logs=list(directory.glob('probe/**/frame-correlation.txt'))+list(directory.glob('probe/**/r47-prepared-visual.txt'))
    log=logs[0].read_text() if len(logs)==1 else ''
    scene='PASS' if any(row['state']=='ALLOWED' and row['orb']=='VISIBLE' for row in rows) and len(summary.get('orb_bounds',[]))==4 else 'UNOBSERVED'
    values={}
    for label,key in [('RESTRICTION','restriction_elapsed_ns'),('CONCEAL_BEGIN','conceal_enter_elapsed_ns'),('CONCEAL_RETURN','conceal_return_elapsed_ns')]:
        match=re.search(r'^'+label+r' elapsedNs=(\d+)',log,re.MULTILINE)
        if match: values[key]=int(match.group(1))
    owner={}
    match=re.search(r'targetWindow=(\d+).*attachment=(\d+) orbGeneration=(\d+)',log)
    if match: owner=dict(zip(('window','attachment','orb_generation'),map(int,match.groups())))
    return {'capture_clock':summary.get('clock','UNOBSERVED'),'scene_calibration':scene,'frames':rows,
            'times':values,'owner':owner,'first_screenshot':{},'raw_summary':summary,
            'first_sample_line':next((line for line in log.splitlines() if line.startswith('firstAfterHide=')),'UNOBSERVED')}

clean=read('controlClean'); one=read('controlOneFrame')
controls={'clean':v.control_verdict(clean,'clean'),'one_frame':v.control_verdict(one,'one_frame')}
result={'control_status':controls,'cases':{}}
for name in ('directFirstSample','waFirstSample','directPendingDraw','waPendingDraw','directRapidRelock','waRapidRelock'):
    case=read(name); decision=v.observation(case,controls)
    result['cases'][name]={'verdict':decision,'first_sample_line':case['first_sample_line'],
                           'raw_summary':case['raw_summary'],'times':case['times'],'owner':case['owner']}
target.write_text(json.dumps(result,indent=2,sort_keys=True)+'\n')
print(json.dumps(result,sort_keys=True))
