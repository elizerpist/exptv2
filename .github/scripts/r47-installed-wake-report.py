#!/usr/bin/env python3
"""Keep each wake and each retained record; never infer missing optical output."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path

KINDS = {'R44_WAKE','R44_READ','R44_END','R44_9_OUTCOME','R44_9_ADMISSION','R44_6_SAMPLE','R45_LIFECYCLE'}

def records(path):
    text=path.read_text()
    wakes={}
    for original in text.splitlines():
        line=original.strip(); parts=line.split()
        if not parts or parts[0] not in KINDS: continue
        fields={}
        for item in parts[1:]:
            if '=' in item:
                key,value=item.split('=',1); fields[key]=value
        wake=fields.get('wake')
        if not wake or not wake.isdigit(): continue
        wakes.setdefault(wake,{}).setdefault(parts[0],[]).append(fields)
    return {'sha256':hashlib.sha256(path.read_bytes()).hexdigest(), 'time_base':'uptimeMs',
            'optical_visibility':'UNOBSERVED',
            'wakes':{key:wakes[key] for key in sorted(wakes,key=int)}}

def main():
    p=argparse.ArgumentParser(); p.add_argument('direct',type=Path); p.add_argument('wa',type=Path); p.add_argument('output',type=Path)
    a=p.parse_args()
    result={'scope':'existing signed-profile installed UI probes; synthetic emulator; not physical phone',
            'direct':records(a.direct),'wa':records(a.wa)}
    a.output.write_text(json.dumps(result,indent=2,sort_keys=True)+'\n')
    for route in ('direct','wa'):
        for wake,fields in result[route]['wakes'].items():
            for outcome in fields.get('R44_9_OUTCOME',[]):
                print(route, 'wake='+wake, 'arm='+outcome.get('arm','UNOBSERVED'),
                      'backend='+outcome.get('backend','UNOBSERVED'), 'issue='+outcome.get('issue','UNOBSERVED'),
                      'frame='+outcome.get('frame','UNOBSERVED'), 'terminal='+outcome.get('terminal','UNOBSERVED'))
if __name__=='__main__': main()
