#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Furoshiki contributors

# Photographs the app for the README: starts the built app in showcase mode
# (see Sources/Furoshiki/Support/ReadmeShowcase.swift), captures each window
# it announces and leaves one PNG per scene in the output folder.
#
#   ./build.sh && ./Tools/readme-screenshots.sh [output-folder]
#
# screencapture needs the Screen Recording permission for the shell that runs
# it. GitHub's macOS runners grant it to bash.
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="${1:-build/readme-screenshots}"
APP="build/stage/Furoshiki.app"
[[ -d "$APP" ]] || { echo "Build the app first: ./build.sh" >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

# Through open, so the app is its own responsible process: started from a
# shell, TCC would end it the moment a view touched Bluetooth, since the
# shell has no usage description for it. -W keeps open alive until it quits.
open -W -n "$APP" --args --showcase "$OUT" &
PID=$!
trap 'kill "$PID" 2>/dev/null || true; pkill -f -- "--showcase $OUT" 2>/dev/null || true' EXIT

deadline=$((SECONDS + 300))
while kill -0 "$PID" 2>/dev/null; do
    if [[ -f "$OUT/next.txt" ]]; then
        read -r name window < "$OUT/next.txt"
        screencapture -x -l"$window" "$OUT/$name.png"
        echo "captured $name"
        rm -f "$OUT/next.txt"
    fi
    if (( SECONDS > deadline )); then
        echo "Timed out waiting for the showcase" >&2
        exit 1
    fi
    sleep 0.2
done
wait "$PID" || true

[[ -f "$OUT/finished" ]] || { echo "The showcase stopped before its last scene" >&2; exit 1; }
rm -f "$OUT/finished"
ls -l "$OUT"
