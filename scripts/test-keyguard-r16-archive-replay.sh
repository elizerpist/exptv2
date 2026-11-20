#!/usr/bin/env bash
# Replays the four original recordings without inventing visual class or ROI.
set -uo pipefail
root=$(git rev-parse --show-toplevel)
out="$root/android/keyguard-r16-archive-replay"
temp="${RUNNER_TEMP:?runner temporary directory required}/r16-originals"
[[ ! -e "$out" && ! -e "$temp" ]] || exit 1
mkdir -p "$out" "$temp"
url=https://media.githubusercontent.com/media/elizerpist/exptv2/f6f34ae9b6a5657ea0f52bc10cb922d399c950c9/r15-evidence/r15-run-44759137322.zip
printf 'archive=%s\napplication_source=536987c2345bf0c0cc2cb297b68c7227a0aed3c8\nharness_source=%s\n' "$url" "$(git rev-parse HEAD)" > "$out/identity.txt"
curl --fail --location --silent --show-error "$url" -o "$temp/original.zip" || exit 1
printf '%s  %s\n' 24223b97452a3f8ac702cb93e4029faeece7c30dce2f8a2586e5fabe0c66ebf0 "$temp/original.zip" | sha256sum -c | tee "$out/archive-sha256.txt" || exit 1
python3 - "$temp/original.zip" "$temp" <<'PY' || exit 1
import pathlib, sys, zipfile
archive, temp = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
labels = ('block-1-stock', 'block-1-candidate', 'block-2-candidate', 'block-2-stock')
with zipfile.ZipFile(archive) as z:
    for label in labels:
        member = f'android/keyguard-r15-comparison/{label}/recording.mp4'
        (temp / f'{label}.mp4').write_bytes(z.read(member))
PY
result=0
for label in block-1-stock block-1-candidate block-2-candidate block-2-stock; do
  python3 "$root/scripts/keyguard-r15-video.py" --video "$temp/$label.mp4" --out "$out/$label" --stream --selected 0 > "$out/$label.stdout" 2> "$out/$label.stderr" || result=1
done
python3 - "$out" <<'PY' || result=1
import hashlib, json, pathlib, sys
out = pathlib.Path(sys.argv[1])
expected = {
 'block-1-stock': (181, '915ffd12c02523265e2887d93fe85dde080186ea49f908977d2c0cefd7c6bfe1'),
 'block-1-candidate': (162, '33e821cf6c7c51075822e08af4da554c260ff38aa2a5925a1c7ade98a3507dca'),
 'block-2-candidate': (174, '5435139a2721db1f9c363f85f1333fbafd67c9c349716db6eed0bb8bbda8385d'),
 'block-2-stock': (178, 'ec9a80e1dd6d4f13fd02d31062a7f60ecc1be53d960c7cb774f4199e4c60c69d'),
}
records=[]
for label,(count,digest) in expected.items():
    data=json.loads((out/label/'decode-summary.json').read_text())
    assert data['frame_count']==count and data['video_sha256']==digest and data['timestamp_mapping']=='VALIDATED'
    assert data['roi'] is None and data['visual_qualification']=='NOT_ESTABLISHED'
    assert len((out/label/'frame-index.jsonl').read_text().splitlines())==count
    records.append({'label':label,'frames':count,'video_sha256':digest,'timestamp_mapping':'VALIDATED','visual_class':'UNCLASSIFIED'})
(out/'replay-verdict.json').write_text(json.dumps(records,indent=2)+'\n')
print(json.dumps(records,indent=2))
PY
printf 'result=%s\nmatched_pairs_created=0\n' "$([[ $result == 0 ]] && printf PASS || printf FAIL)" > "$out/status.txt"
exit "$result"
