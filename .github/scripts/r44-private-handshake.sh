#!/usr/bin/env bash
set -euo pipefail
[[ "$R44_STAGE_NONCE" =~ ^[a-f0-9]{16}$ ]]
[[ "$APP_SHA" =~ ^[a-f0-9]{40}$ && "$CANDIDATE_SHA256" =~ ^[a-f0-9]{64}$ ]]
out="$RUNNER_TEMP/r44-update"
mkdir -p "$out"
key_ref="refs/heads/artifact/r44-stage-key-$R44_STAGE_NONCE"
stage_ref="refs/heads/artifact/r44-stage-data-$R44_STAGE_NONCE"
cd "$GITHUB_WORKSPACE/orchestrator"
test -z "$(git ls-remote origin "$key_ref" "$stage_ref")"
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$out/private.pem" >/dev/null 2>&1
openssl pkey -in "$out/private.pem" -pubout -out "$out/public.pem" >/dev/null 2>&1
public_sha=$(sha256sum "$out/public.pem" | cut -d' ' -f1)
blob=$(git hash-object -w "$out/public.pem")
tree=$(printf '100644 blob %s\tpublic.pem\n' "$blob" | git mktree)
commit=$(git -c user.name='Fluvi Fixture' -c user.email='fluvi-fixture@users.noreply.github.com' \
  commit-tree "$tree" -m "artifact: temporary R44 update public key [skip ci]" -m "run=$GITHUB_RUN_ID nonce=$R44_STAGE_NONCE")
git push origin "$commit:$key_ref"
printf 'keyCommit=%s\npublicKeySha256=%s\nnonce=%s\n' "$commit" "$public_sha" "$R44_STAGE_NONCE" > "$out/handshake.txt"
stage_commit=""
for _ in $(seq 1 150); do
  stage_commit=$(git ls-remote origin "$stage_ref" | awk '{print $1}')
  [[ -n "$stage_commit" ]] && break
  sleep 3
done
[[ "$stage_commit" =~ ^[a-f0-9]{40}$ ]]
git fetch --no-tags origin "$stage_ref"
test "$(git rev-parse FETCH_HEAD)" = "$stage_commit"
git show FETCH_HEAD:manifest.json > "$out/stage-manifest.json"
git show FETCH_HEAD:key.enc > "$out/key.enc"
python3 - "$out/stage-manifest.json" "$APP_SHA" "$CANDIDATE_SHA256" "$CANDIDATE_SIZE" "$public_sha" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
assert m['source']==sys.argv[2]
assert m['candidate_sha256']==sys.argv[3]
assert m['candidate_size']==int(sys.argv[4])
assert m['public_key_sha256']==sys.argv[5]
PY
stage_size=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["cipher_size"])' "$out/stage-manifest.json")
stage_sha=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["cipher_sha256"])' "$out/stage-manifest.json")
[[ "$stage_sha" =~ ^[a-f0-9]{64}$ && "$stage_size" =~ ^[0-9]+$ ]]
curl -fLsS --retry 3 "https://media.githubusercontent.com/media/elizerpist/exptv2/$stage_commit/r44.zstpatch.enc" -o "$out/stage.enc"
test "$(wc -c < "$out/stage.enc")" -eq "$stage_size"
printf '%s  %s\n' "$stage_sha" "$out/stage.enc" | sha256sum -c -
openssl pkeyutl -decrypt -inkey "$out/private.pem" -in "$out/key.enc" -out "$out/key.txt" \
  -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256
chmod 600 "$out/key.txt"
openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass "file:$out/key.txt" -in "$out/stage.enc" -out "$out/r44.zstpatch"
if [[ "${R44_BASELINE:-}" == r47 ]]; then
  base_url='https://media.githubusercontent.com/media/elizerpist/exptv2/d6f121d2ed2e0830597c5bbac26b3cc10a87a870/Fluvi_R47_HUMAN_af20365a5ec9.apk'
  base_sha=74c39c4930261363721ed875f0c3889b2cc6f69f7a2fcb2086728e2464d597ea
elif [[ "${R44_BASELINE:-}" == r46 ]]; then
  base_url='https://media.githubusercontent.com/media/elizerpist/exptv2/87149a537c3cb4ccfa730d8838a36b4242595e7a/fluvi_R46_SAMPLE_ONLY_HUMAN_fd74df605779.apk'
  base_sha=6a4fecb359ce8de81035366a12e93dafe027689d2226a84d0091ee14d6cdca1f
else
  base_url='https://media.githubusercontent.com/media/elizerpist/exptv2/47ba86e432b7027ea9c786270211d1d8b5b8edf2/fluvi_R43_HUMAN_0732bee6a2bc.apk'
  base_sha=4abcfd4f0b929919c1102a76155d061a721112b8efac5c5ee7c293d3c198b166
fi
curl -fLsS --retry 3 "$base_url" -o "$out/r43.apk"
printf '%s  %s\n' "$base_sha" "$out/r43.apk" | sha256sum -c -
zstd -q -d --patch-from="$out/r43.apk" -f "$out/r44.zstpatch" -o "$out/r44.apk"
test "$(wc -c < "$out/r44.apk")" -eq "$CANDIDATE_SIZE"
printf '%s  %s\n' "$CANDIDATE_SHA256" "$out/r44.apk" | sha256sum -c -
rm -f "$out/private.pem" "$out/key.txt" "$out/r44.zstpatch" "$out/stage.enc"
printf 'stageCommit=%s\nprivateFixture=decryptedAndVerified\n' "$stage_commit" >> "$out/handshake.txt"
