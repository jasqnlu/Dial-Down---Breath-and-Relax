#!/bin/bash
# Runs one or more exercise scripts headless, encodes each rendered frame
# sequence to mp4, and copies the mp4 into Resources/Animations/.
# Usage: _batch_run.sh exercise_name1 exercise_name2 ...
set -e
REPO="/Users/jasonlu/Desktop/X-Code Projects/Breath - Relax & Stretch"
BLENDER=/Applications/Blender.app/Contents/MacOS/Blender
GEN="$REPO/Tools/blender/generated/exercises"
ANIM="$REPO/Breath - Relax & Stretch/Resources/Animations"

for name in "$@"; do
  echo "=== $name ==="
  "$BLENDER" -b --python "$REPO/Tools/blender/exercises/${name}.py" 2>&1 | tail -5 || true
  frames="$GEN/_demo_frames_${name}"
  if [ ! -d "$frames" ]; then
    echo "FAILED: no frames dir for $name"
    continue
  fi
  swift "$REPO/Tools/blender/encode_mp4.swift" "$frames" "$GEN/${name}.mp4" 30 512 640
  cp "$GEN/${name}.mp4" "$ANIM/${name}.mp4"
  echo "=== $name done: $(ls -la "$ANIM/${name}.mp4" | awk '{print $5}') bytes ==="
done
