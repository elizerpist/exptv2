#!/usr/bin/env python3
import io,json,subprocess,tarfile,tempfile,unittest
from pathlib import Path
SCRIPT=Path(__file__).with_name('r47-paired-native-report.py')
class Compare(unittest.TestCase):
 def test_missing_is_not_pass(self):
  with tempfile.TemporaryDirectory() as tmp:
   root=Path(tmp)
   def make(path,xml):
    data=xml.encode(); info=tarfile.TarInfo('build/app/outputs/androidTest-results/connected/debug/result.xml'); info.size=len(data)
    with tarfile.open(path,'w:gz') as archive: archive.addfile(info,io.BytesIO(data))
   b=root/'b.tgz';c=root/'c.tgz';output=root/'out.json'
   make(b,'<testsuite><testcase classname="C" name="old"><failure message="x"/></testcase><testcase classname="C" name="same"/></testsuite>')
   make(c,'<testsuite><testcase classname="C" name="new"/><testcase classname="C" name="same"><failure/></testcase></testsuite>')
   subprocess.run(['python3','-B',str(SCRIPT),str(b),str(c),str(output)],check=True,stdout=subprocess.DEVNULL)
   data=json.loads(output.read_text()); self.assertEqual(data['comparison']['C#old']['candidate']['status'],'NOT_RUN')
   self.assertEqual(data['comparison']['C#same']['candidate']['status'],'FAIL'); self.assertEqual(data['summary']['baseline']['fail'],1)
if __name__=='__main__': unittest.main(verbosity=2)
