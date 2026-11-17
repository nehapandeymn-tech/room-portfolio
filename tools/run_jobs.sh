#!/bin/bash
# usage: tools/run_jobs.sh [jobs.tsv]  -- runs Codex image jobs, 6 at a time, skipping outputs that already exist
cd "$(dirname "$0")/.." || exit 1
P=$(pwd); JOBS=${1:-tools/jobs.tsv}; MAX=6
while IFS=$'\t' read -r kind out text; do
  [ -z "$kind" ] && continue
  [ -f "$out" ] && continue
  name=$(basename "$out" .png)
  KIND="$kind" OUT="$P/$out" TEXT="$text" python3 - > "tools/logs/$name.prompt" <<'PY'
import os
t=open(f"tools/prompts/{os.environ['KIND']}.txt").read()
t=t.replace("OUTPATH",os.environ["OUT"])
for k in ("LIGHTING","AREA","SUBJECT"): t=t.replace(k+": "+k, k+": "+os.environ["TEXT"])
print(t)
PY
  ( codex exec --skip-git-repo-check -s workspace-write "$(cat "tools/logs/$name.prompt")" -i assets/room/day.png -i refs/01-brush-desk.png </dev/null > "tools/logs/$name.log" 2>&1; echo "done $out" ) &
  while [ "$(jobs -rp | wc -l)" -ge "$MAX" ]; do sleep 2; done
done < "$JOBS"
wait
ls -la assets/room assets/zones assets/sprites
