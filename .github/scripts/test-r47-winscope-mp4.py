#!/usr/bin/env python3
import importlib.util,struct,unittest
from pathlib import Path
spec=importlib.util.spec_from_file_location('clock',Path(__file__).with_name('r47-winscope-mp4.py'))
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

def box(kind,body): return struct.pack('>I4s',len(body)+8,kind)+body
def metadata(data,offset=8):
 hdlr=box(b'hdlr',b'\0'*8+b'meta'+b'\0'*4)
 stsd=box(b'stsd',b'\0'*4+struct.pack('>I',1)+struct.pack('>I4s',8,b'mett'))
 stsz=box(b'stsz',b'\0'*4+struct.pack('>III',0,1,len(data)))
 stsc=box(b'stsc',b'\0'*4+struct.pack('>IIII',1,1,1,1))
 stco=box(b'stco',b'\0'*4+struct.pack('>II',1,offset))
 stbl=box(b'stbl',stsd+stsz+stsc+stco)
 moov=box(b'moov',box(b'trak',box(b'mdia',hdlr+box(b'minf',stbl))))
 return box(b'mdat',data)+moov

def sample(values): return m.MAGIC+struct.pack('<IqI',2,1234,len(values))+struct.pack('<'+'Q'*len(values),*values)
class ClockTest(unittest.TestCase):
 def test_track_and_timestamp_validation(self):
  data=sample([9_000_000_000,9_100_000_000,9_200_000_000]); found=m.metadata_samples(metadata(data))
  self.assertEqual(found,[(8,data)])
  value=m.validate(found[0][1],[0,100_000_000,200_000_000]);self.assertEqual(value['frames'],3);self.assertEqual(value['max_relative_error_ns'],0)
 def test_bad_offset_cannot_scan_arbitrary_magic(self):
  with self.assertRaisesRegex(ValueError,'metadata_outside_mdat'): m.metadata_samples(metadata(sample([1]),offset=999999))
 def test_count_clock_and_order_fail_closed(self):
  data=sample([9_000_000_000,9_100_000_000,9_200_000_000])
  with self.assertRaisesRegex(ValueError,'frame_count_mismatch'): m.validate(data,[0,1])
  with self.assertRaisesRegex(ValueError,'frame_clock_mapping_mismatch'): m.validate(data,[0,100_000_000,210_000_000])
  with self.assertRaisesRegex(ValueError,'non_monotonic_frames'): m.validate(sample([4,3]),[0,1])
 def test_duplicate_or_truncated_boxes_fail(self):
  with self.assertRaisesRegex(ValueError,'required_box_moov'):m.metadata_samples(box(b'mdat',sample([1])))
  with self.assertRaisesRegex(ValueError,'invalid_box_size'):m.metadata_samples(b'\x00\x00\xff\xffmdat')
if __name__=='__main__':unittest.main(verbosity=2)
