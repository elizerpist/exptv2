#!/usr/bin/env python3
"""Extract a validated Android screenrecord Winscope v2 MP4 metadata sample.

Some ffprobe builds expose a `mett` stream but omit its packets. Do not scan
for an arbitrary byte signature: traverse the ISO BMFF track sample tables,
require exactly one metadata sample in a real mdat box, then independently
check frame count, ordering and every elapsed/PTS interval.
"""
from __future__ import annotations
import argparse
import decimal
import hashlib
import json
import struct
import subprocess
from pathlib import Path

MAGIC=b'#VV1NSC0PET1ME2#'

def boxes(data: bytes, start: int, end: int):
    if not 0<=start<=end<=len(data): raise ValueError('box_bounds')
    pos=start
    while pos<end:
        if end-pos<8: raise ValueError('short_box')
        size,kind=struct.unpack_from('>I4s',data,pos); header=8
        if size==1:
            if end-pos<16: raise ValueError('short_extended_box')
            size=struct.unpack_from('>Q',data,pos+8)[0]; header=16
        elif size==0: size=end-pos
        if size<header or pos+size>end: raise ValueError('invalid_box_size')
        yield kind,pos+header,pos+size
        pos+=size

def single(items, kind):
    matches=[(start,end) for typ,start,end in items if typ==kind]
    if len(matches)!=1: raise ValueError('required_box_'+kind.decode(errors='replace'))
    return matches[0]

def u32(data, pos, end):
    if pos+4>end: raise ValueError('short_fullbox')
    return struct.unpack_from('>I',data,pos)[0]

def metadata_samples(data: bytes):
    top=list(boxes(data,0,len(data)))
    mdats=[(s,e) for t,s,e in top if t==b'mdat']
    moov=single(top,b'moov'); result=[]
    for typ,ts,te in boxes(data,*moov):
        if typ!=b'trak': continue
        track=list(boxes(data,ts,te))
        mdia=single(track,b'mdia'); md=list(boxes(data,*mdia))
        hs,he=single(md,b'hdlr')
        if hs+12>he: raise ValueError('short_hdlr')
        if data[hs+8:hs+12]!=b'meta': continue
        minf=single(md,b'minf'); stbl=single(list(boxes(data,*minf)),b'stbl'); table=list(boxes(data,*stbl))
        ds,de=single(table,b'stsd')
        if u32(data,ds+4,de)!=1 or ds+16>de: raise ValueError('metadata_stsd')
        entry_size,entry_type=struct.unpack_from('>I4s',data,ds+8)
        if entry_type!=b'mett' or entry_size<8 or ds+8+entry_size>de: continue
        zs,ze=single(table,b'stsz'); sample_size=u32(data,zs+4,ze); count=u32(data,zs+8,ze)
        if count!=1: raise ValueError('metadata_sample_count')
        if sample_size==0: sample_size=u32(data,zs+12,ze)
        cs,ce=single(table,b'stsc')
        if u32(data,cs+4,ce)!=1 or cs+20>ce: raise ValueError('metadata_stsc')
        first,per,description=struct.unpack_from('>III',data,cs+8)
        if (first,per,description)!=(1,1,1): raise ValueError('metadata_chunk_mapping')
        offsets=[(t,s,e) for t,s,e in table if t in (b'stco',b'co64')]
        if len(offsets)!=1: raise ValueError('metadata_offsets')
        kind,os_,oe=offsets[0]
        if u32(data,os_+4,oe)!=1: raise ValueError('metadata_chunk_count')
        step=8 if kind==b'co64' else 4
        if os_+8+step>oe: raise ValueError('short_metadata_offset')
        offset=struct.unpack_from('>Q' if step==8 else '>I',data,os_+8)[0]
        if not any(s<=offset and offset+sample_size<=e for s,e in mdats): raise ValueError('metadata_outside_mdat')
        result.append((offset,data[offset:offset+sample_size]))
    return result

def validate(sample: bytes, pts: list[int], tolerance_ns=2_000_000):
    if len(sample)<32 or sample[:16]!=MAGIC: raise ValueError('winscope_magic')
    version,offset,count=struct.unpack_from('<IqI',sample,16)
    if version!=2 or count<=0 or count>1_000_000 or len(sample)!=32+8*count: raise ValueError('winscope_header')
    if count!=len(pts): raise ValueError('frame_count_mismatch')
    elapsed=list(struct.unpack_from(f'<{count}Q',sample,32))
    if any(b<=a for a,b in zip(elapsed,elapsed[1:])) or any(b<=a for a,b in zip(pts,pts[1:])): raise ValueError('non_monotonic_frames')
    deviations=[abs((e-elapsed[0])-(p-pts[0])) for e,p in zip(elapsed,pts)]
    if max(deviations,default=0)>tolerance_ns: raise ValueError('frame_clock_mapping_mismatch')
    return {'realtime_minus_elapsed_ns':offset,'frames':count,'max_relative_error_ns':max(deviations,default=0),'elapsed_ns':elapsed}

def validate_uptime_bounds(elapsed, before_text, after_text, tolerance_ns=20_000_000):
    before=int(decimal.Decimal(before_text.split()[0])*1_000_000_000)
    after=int(decimal.Decimal(after_text.split()[0])*1_000_000_000)
    if not elapsed or before<0 or after<before or elapsed[0]<before-tolerance_ns or elapsed[-1]>after+tolerance_ns:
        raise ValueError('device_clock_bounds_mismatch')
    return {'status':'PASS','before_ns':before,'after_ns':after,'rounding_tolerance_ns':tolerance_ns}

def inspect(path: Path):
    data=path.read_bytes(); candidates=[(offset,s) for offset,s in metadata_samples(data) if s.startswith(MAGIC)]
    if len(candidates)!=1: raise ValueError('winscope_track_missing_or_ambiguous')
    probe=subprocess.run(['ffprobe','-v','error','-select_streams','v:0','-show_frames','-show_entries',
        'frame=best_effort_timestamp_time','-of','json',str(path)],capture_output=True,text=True,check=True)
    rows=json.loads(probe.stdout)['frames']
    pts=[int(decimal.Decimal(row['best_effort_timestamp_time'])*1_000_000_000) for row in rows]
    result=validate(candidates[0][1],pts)
    result.update(status='VALIDATED',metadata_sample_offset=candidates[0][0],video_bytes=len(data),
                  video_sha256=hashlib.sha256(data).hexdigest(),frame_pts_ns=pts,
                  note='Screenrecord capture time is not a screenshot or physical presentation frame ID.')
    return result

def main():
    p=argparse.ArgumentParser();p.add_argument('video',type=Path);p.add_argument('output',type=Path)
    p.add_argument('--before',type=Path);p.add_argument('--after',type=Path);a=p.parse_args()
    try:
        if (a.before is None)!=(a.after is None): raise ValueError('device_clock_bounds_incomplete')
        result=inspect(a.video)
        if a.before is not None:
            result['device_clock_bounds']=validate_uptime_bounds(result['elapsed_ns'],a.before.read_text(),a.after.read_text())
        a.output.write_text(json.dumps(result,sort_keys=True)+'\n')
        print(json.dumps({k:v for k,v in result.items() if k not in ('elapsed_ns','frame_pts_ns')},sort_keys=True))
    except (ValueError,KeyError,IndexError,decimal.InvalidOperation,struct.error,subprocess.SubprocessError,OSError) as e:
        a.output.write_text(json.dumps({'status':'NOT_ESTABLISHED','reason':str(e)})+'\n')
        print('NOT_ESTABLISHED',str(e));raise SystemExit(1)
if __name__=='__main__': main()
