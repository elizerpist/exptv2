"""Reprocess the immutable R52 archive's MP4 sample map and matched marker receipts."""

import csv
import hashlib
import io
import json
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
import zipfile

from r53_mp4 import from_file
from r53_video import probe_video

EXPECTED_ARCHIVE = "f1a008b1dc1bf47138a0cdc6df411368443b2f251a44cf558c2d2b7dd917832c"
BLOCKS = (("block1-50", 201, 202), ("block2-0", 207, 208), ("block3-0", 359, 360),
          ("block4-50", 335, 336), ("block5-OFF", None, None))


def replay(raw):
    if hashlib.sha256(raw).hexdigest() != EXPECTED_ARCHIVE:
        raise ValueError("unexpected baseline archive")
    reports = []
    with TemporaryDirectory() as temporary, zipfile.ZipFile(io.BytesIO(raw)) as archive:
        path = Path(temporary) / "raw.mp4"
        for block, positive, absent in BLOCKS:
            media = archive.read(f"experiment/{block}.mp4")
            path.write_bytes(media)
            _, pts, extent = probe_video(path)
            metadata = from_file(path, pts)
            report = dict(block=block, extent=extent, count=len(pts),
                          mp4_sha256=hashlib.sha256(media).hexdigest(),
                          metadata_locations=metadata.locations,
                          max_pts_error_ns=metadata.max_pts_error_ns,
                          max_legacy_error_ns=metadata.max_legacy_error_ns,
                          maximum_gap_ns=max(b-a for a, b in zip(metadata.elapsed_ns, metadata.elapsed_ns[1:])),
                          old_first_frame_verdict="INCONCLUSIVE", source_image_age_ns=None)
            if positive is not None:
                trials = json.loads(archive.read(f"experiment/{block}-trials.json"))
                action = next(row for row in trials if row["route"] == "unlock")
                start, end = action["action_bracket_ns"]
                markers = csv.DictReader(io.StringIO(archive.read(f"experiment/{block}-markers.csv").decode()))
                local = next(int(row["ts"]) for row in markers if row["name"] == "FluviR52.localHide"
                             and start <= int(row["ts"]) <= end + 5_000_000_000)
                report.update(
                    retained_orb_positive_index=positive, retained_next_absent_index=absent,
                    local_hide_ns=local, retained_positive_recorder_minus_local_ns=metadata.elapsed_ns[positive]-local,
                    retained_absence_recorder_minus_local_ns=metadata.elapsed_ns[absent]-local,
                )
            reports.append(report)
    return dict(archive_sha256=EXPECTED_ARCHIVE, reports=reports)


if __name__ == "__main__":
    print(json.dumps(replay(sys.stdin.buffer.read()), indent=2))
