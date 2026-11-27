#!/usr/bin/env python3
import json
import hashlib
from pathlib import Path
import subprocess
import tempfile
import unittest
from PIL import Image, ImageDraw

SCRIPT=Path(__file__).with_name('r47-frame-extract.py')
class ExtractTest(unittest.TestCase):
    def capture(self, first, offset=False, fallback_clock=False):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); p=root/'probe'/'case'; p.mkdir(parents=True)
            mx,my=(24,220) if offset else (0,0)
            width,height=(600,800) if offset else (400,400)
            (p/'frame-correlation.txt').write_text(f'control=ONE_FRAME\nmarkerScreen={mx},{my} size={width}x{height} contentScreen=0,0\n')
            v=root/'video-validated'; v.mkdir()
            f=(root/'video-fallback-frames') if fallback_clock else (v/'frames'); f.mkdir(parents=True)
            (v/'decode-summary.json').write_text(json.dumps({'timestamp_mapping':'NOT_ESTABLISHED' if fallback_clock else 'VALIDATED'}))
            lines=[]
            for i,(state,visible) in enumerate([(False,True),(True,first),(True,False)]):
                im=Image.new('RGB',(width,height),(11,177,67)); d=ImageDraw.Draw(im)
                d.rectangle((mx,my,mx+48,my+48), fill=(240,20,20) if state else (20,20,240))
                for bit in range(12):
                    d.rectangle((mx+52+20*bit,my,mx+70+20*bit,my+40),fill='white' if ((i+1)&(1<<bit)) else 'black')
                if visible: d.ellipse((width//2-90,height//2-90,width//2+90,height//2+90),fill=(240,120,20))
                im.save(f/f'{i:08}.png')
                lines.append(json.dumps({'index':i,'elapsed_ns':1000+i}))
            (v/'frame-index.jsonl').write_text('\n'.join(lines)+'\n')
            if fallback_clock:
                data=b'fixture-video'; (root/'recording.mp4').write_bytes(data)
                (root/'winscope-valid.json').write_text(json.dumps({'status':'VALIDATED','device_clock_bounds':{'status':'PASS'},'video_sha256':hashlib.sha256(data).hexdigest(),'elapsed_ns':[1000,1001,1002]}))
            proc=subprocess.run(['python3','-B',str(SCRIPT),str(root)],capture_output=True,text=True)
            self.assertEqual(proc.returncode,0,proc.stderr)
            rows=[json.loads(x) for x in (root/'all-frame-observations.jsonl').read_text().splitlines()]
            self.assertEqual(len(list((root/'all-orb-crops').glob('*.png'))),3)
            report=json.loads((root/'frame-extract-summary.json').read_text())
            self.assertEqual(report['actual_first_forbidden_frame'],'NOT_DECIDABLE')
            self.assertEqual(report['clock'],'VALIDATED')
            return [r['orb'] for r in rows], [r['marker_seq'] for r in rows]
    def test_both_visual_controls_and_missing_display_identity(self):
        self.assertEqual(self.capture(False),(['VISIBLE','CLEAR','CLEAR'],[1,2,3]))
        self.assertEqual(self.capture(True),(['VISIBLE','VISIBLE','CLEAR'],[1,2,3]))
        self.assertEqual(self.capture(True,offset=True),(['VISIBLE','VISIBLE','CLEAR'],[1,2,3]))
        self.assertEqual(self.capture(True,offset=True,fallback_clock=True),(['VISIBLE','VISIBLE','CLEAR'],[1,2,3]))
if __name__=='__main__': unittest.main(verbosity=2)
