#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Furoshiki contributors

# Installs or updates Furoshiki from the latest build on GitHub:
#
#   curl -fsSL https://raw.githubusercontent.com/colinnoah/Furoshiki/main/install.sh | bash
#
# A file a browser downloads carries macOS's quarantine flag, which makes
# Gatekeeper stop a build that Apple has not notarized ("Open Anyway").
# curl sets no such flag, so the app opens directly. The script checks the
# download's checksum and the app's code signature before it replaces
# anything, quits a running Furoshiki first and starts the new one after.
#
# Environment overrides:
#   FUROSHIKI_DMG_URL   another disk image to install (with FUROSHIKI_SHA256_URL)
#   FUROSHIKI_DEST      install folder, default /Applications
#   FUROSHIKI_NO_OPEN=1 do not start the app afterwards

# Everything runs inside main, so a download cut off halfway executes nothing.
main() {
    set -euo pipefail

    local repo="colinnoah/Furoshiki"
    local base="https://github.com/$repo/releases/download/latest-build"
    local dmg_url="${FUROSHIKI_DMG_URL:-$base/Furoshiki.dmg}"
    local sha_url="${FUROSHIKI_SHA256_URL:-$base/Furoshiki.dmg.sha256}"
    local dest_dir="${FUROSHIKI_DEST:-/Applications}"
    local bundle_id="io.github.colinnoah.furoshiki"
    local app_name="Furoshiki.app"

    say() { printf '\033[1m▸ %s\033[0m\n' "$*"; }
    fail() { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

    [[ "$(uname -s)" == "Darwin" ]] || fail "Furoshiki runs on macOS only."
    local major
    major="$(sw_vers -productVersion | cut -d. -f1)"
    (( major >= 14 )) || fail "Furoshiki needs macOS 14 or newer (this Mac has $(sw_vers -productVersion))."
    [[ "$(uname -m)" == "arm64" ]] || fail "Furoshiki needs a Mac with Apple silicon."

    # Globals, not locals: the EXIT trap runs after main has returned.
    FUROSHIKI_WORK="$(mktemp -d)"
    FUROSHIKI_MOUNT=""
    local work="$FUROSHIKI_WORK"
    cleanup() {
        local mount="$FUROSHIKI_MOUNT" work="$FUROSHIKI_WORK"
        if [[ -n "$mount" ]]; then hdiutil detach "$mount" -quiet -force 2>/dev/null || true; fi
        rm -rf "$work"
    }
    trap cleanup EXIT

    say "Downloading Furoshiki…"
    curl -fL --progress-bar --retry 3 -o "$work/Furoshiki.dmg" "$dmg_url" \
        || fail "The download failed. Check your internet connection and try again."
    if curl -fsSL --retry 3 -o "$work/Furoshiki.dmg.sha256" "$sha_url"; then
        local expected actual
        expected="$(awk '{print $1; exit}' "$work/Furoshiki.dmg.sha256")"
        actual="$(shasum -a 256 "$work/Furoshiki.dmg" | awk '{print $1}')"
        [[ -n "$expected" && "$expected" == "$actual" ]] \
            || fail "The download is damaged (checksum mismatch). Please try again."
    else
        fail "Could not download the checksum to verify the disk image."
    fi

    say "Checking the app…"
    local mount="$work/mount"
    mkdir "$mount"
    hdiutil attach "$work/Furoshiki.dmg" -nobrowse -readonly -quiet -mountpoint "$mount" \
        || fail "The disk image could not be opened."
    FUROSHIKI_MOUNT="$mount"
    local source="$mount/$app_name"
    [[ -d "$source" ]] || fail "The disk image does not contain $app_name."
    codesign --verify --deep --strict "$source" 2>/dev/null \
        || fail "The app's code signature is not valid. Nothing was installed."
    local identifier
    identifier="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$source/Contents/Info.plist" 2>/dev/null || true)"
    [[ "$identifier" == "$bundle_id" ]] || fail "The disk image contains a different app ($identifier)."
    local version
    version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$source/Contents/Info.plist" 2>/dev/null || echo "?")"

    # Quit a running copy so the files can be replaced, then wait for it.
    if pgrep -xq Furoshiki; then
        say "Quitting the running Furoshiki…"
        osascript -e "tell application id \"$bundle_id\" to quit" >/dev/null 2>&1 || true
        local tries=0
        while pgrep -xq Furoshiki && (( tries < 50 )); do sleep 0.2; tries=$((tries + 1)); done
        if pgrep -xq Furoshiki; then pkill -x Furoshiki || true; sleep 1; fi
    fi

    # Install without administrator rights when the folder allows it. A
    # function rather than an array: macOS's bash 3.2 treats an empty array
    # as unbound under set -u.
    local use_sudo=0
    mkdir -p "$dest_dir" 2>/dev/null || true
    if [[ ! -w "$dest_dir" ]] || { [[ -e "$dest_dir/$app_name" ]] && [[ ! -w "$dest_dir/$app_name" ]]; }; then
        say "Your password is needed to write to $dest_dir."
        use_sudo=1
    fi
    as_needed() { if (( use_sudo )); then sudo "$@"; else "$@"; fi; }

    say "Installing Furoshiki $version into $dest_dir…"
    local stage="$dest_dir/.$app_name.install-new"
    as_needed rm -rf "$stage"
    as_needed ditto "$source" "$stage"
    as_needed xattr -cr "$stage" 2>/dev/null || true
    as_needed rm -rf "$dest_dir/$app_name"
    as_needed mv "$stage" "$dest_dir/$app_name"
    if (( use_sudo )); then
        sudo chown -R "$(id -u):$(id -g)" "$dest_dir/$app_name" 2>/dev/null || true
    fi

    hdiutil detach "$mount" -quiet 2>/dev/null || true
    FUROSHIKI_MOUNT=""

    printf '\033[32m✓ Furoshiki %s is installed.\033[0m\n' "$version"
    if [[ "${FUROSHIKI_NO_OPEN:-0}" != "1" ]]; then
        open "$dest_dir/$app_name"
        echo "  Look for the cloth bundle at the top right of your menu bar."
    fi
    echo "  To update later, run the same command again."
}

main "$@"
