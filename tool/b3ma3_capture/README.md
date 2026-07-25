# B3M-A3 capture and comparison

Run Flutter golden capture and verification only inside Ubuntu proot:

```sh
cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree

proot-distro login ubuntu -- bash -lc '
  cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree &&
  /home/flutteruser/flutter/bin/flutter test \
    --update-goldens \
    --dart-define=B3MA3_CAPTURE_GOLDENS=true \
    test/widget_test.dart \
    --plain-name "captures production Balance expanded and collapsed evidence"
'

proot-distro login ubuntu -- bash -lc '
  cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree &&
  /home/flutteruser/flutter/bin/flutter test \
    --dart-define=B3MA3_CAPTURE_GOLDENS=true \
    test/widget_test.dart \
    --plain-name "captures production Balance expanded and collapsed evidence"
'
```

Create one 50% mean overlay, one side-by-side image, AE/RMSE metrics, and
SHA-256 identities from an equal-sized reference/app pair:

```sh
tool/b3ma3_capture/compare_b3ma3.sh \
  docs/superpowers/evidence/screenshots/b3ma3-reference-expanded.png \
  test/goldens/b3ma3_app_expanded.png \
  docs/superpowers/evidence/screenshots/b3ma3-expanded
```

The script requires ImageMagick 7 and rejects missing inputs or unequal image
dimensions. ImageMagick returns status 1 for a valid nonzero comparison; the
script treats that as a metric result, not a command failure.

The exact HTML reference selector is inside iframe `#exactB3MFrame` at
`[data-stage2-alternative="today-time-rail-permanent"]`. The repository does
not currently contain an end-to-end browser screenshot driver, so recapturing
that selector remains a separate manual/browser-controlled step.
