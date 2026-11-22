#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Furoshiki contributors

# Publishes the DMG that CI just built as the rolling "latest-build"
# pre-release, the one install.sh downloads. Runs on pushes to main only.
#
# It stays a pre-release on purpose: the in-app updater reads the latest
# regular release and installs only builds notarized by Apple, so a
# self-signed build must not show up there as an update.
#
# Needs GH_TOKEN (contents: write), GH_REPO and GITHUB_SHA from the workflow.
set -euo pipefail
cd "$(dirname "$0")/.."

TAG="latest-build"
: "${GH_REPO:?GH_REPO is required}"
: "${GITHUB_SHA:?GITHUB_SHA is required}"

shopt -s nullglob
dmgs=(dist/Furoshiki-*.dmg)
(( ${#dmgs[@]} == 1 )) || { echo "Expected one dist/Furoshiki-*.dmg, found ${#dmgs[@]}" >&2; exit 1; }

VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' Resources/Info.plist)"

# A fixed asset name gives install.sh one URL that always points at the newest build.
cp "${dmgs[0]}" dist/Furoshiki.dmg
(cd dist && shasum -a 256 Furoshiki.dmg > Furoshiki.dmg.sha256)

TITLE="Furoshiki $VERSION (latest build)"
NOTES="$(cat <<EOF
Furoshiki $VERSION, build $BUILD, from commit ${GITHUB_SHA:0:7}.

Install or update from Terminal:

\`\`\`
curl -fsSL https://raw.githubusercontent.com/$GH_REPO/main/install.sh | bash
\`\`\`

This build is signed with the project's own certificate, not notarized by Apple. The command above downloads it without the quarantine flag, so it opens without the Open Anyway step. The DMG below works too, but macOS then asks you to confirm in System Settings > Privacy & Security.

What changed: see [CHANGELOG.md](https://github.com/$GH_REPO/blob/main/CHANGELOG.md).
EOF
)"

if gh release view "$TAG" >/dev/null 2>&1; then
    # Move the tag to this commit, then refresh the text and the files.
    gh api -X PATCH "repos/$GH_REPO/git/refs/tags/$TAG" -f sha="$GITHUB_SHA" -F force=true >/dev/null
    gh release edit "$TAG" --prerelease --title "$TITLE" --notes "$NOTES"
else
    gh release create "$TAG" --prerelease --target "$GITHUB_SHA" --title "$TITLE" --notes "$NOTES"
fi
gh release upload "$TAG" dist/Furoshiki.dmg dist/Furoshiki.dmg.sha256 --clobber
echo "✓ Published $TITLE"
