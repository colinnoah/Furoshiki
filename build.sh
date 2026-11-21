#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Vorssaint

# Builds Furoshiki, assembles the .app bundle, signs it and (with --install)
# installs it into /Applications.
#
# The bundle is staged in a temporary directory outside ~/Documents: folders synced
# by File Provider gain xattrs (com.apple.provenance etc.) that invalidate codesign.
set -euo pipefail
cd "$(dirname "$0")"

# The icon catalog and the bundle are staged in temp dirs; sweep both however
# the script ends.
ICON_TMP=""
STAGE_TMP=""

cleanup() {
    [[ -n "$ICON_TMP" ]] && rm -rf "$ICON_TMP"
    [[ -n "$STAGE_TMP" ]] && rm -rf "$STAGE_TMP"
    return 0
}
trap cleanup EXIT
# zsh runs the EXIT trap when the script is hung up, but not when it is
# interrupted or terminated; route those through exit so a Ctrl-C partway
# into the build sweeps like any other ending.
trap 'exit 1' INT TERM HUP

# Flags: --dev builds the local-only "Furoshiki (Developer)" variant (its own
# bundle id, so it coexists with the official app); --install puts it in /Applications.
DEV=0
INSTALL=0
TEST=0
TEST_ARGS=()
for arg in "$@"; do
    case "$arg" in
        --dev)     DEV=1 ;;
        --install) INSTALL=1 ;;
        --test)    TEST=1 ;;
        --test-suite=*) TEST=1; TEST_ARGS+=("--suite=${arg#*=}") ;;
        --list-tests) TEST=1; TEST_ARGS+=(--list) ;;
    esac
done

if (( DEV )); then
    APP_NAME="Furoshiki (Developer)"
    EXECUTABLE="FuroshikiDeveloper"
    APP_BUNDLE_ID="io.github.colinnoah.furoshiki.dev"
    BUILD_VARIANT_FLAGS=(-D FUROSHIKI_DEVELOPMENT)
    APP_OPTIMIZATION_FLAGS=(-Onone)
    BUILD_CONFIGURATION="debug"
else
    APP_NAME="Furoshiki"
    EXECUTABLE="Furoshiki"
    APP_BUNDLE_ID="io.github.colinnoah.furoshiki"
    BUILD_VARIANT_FLAGS=()
    APP_OPTIMIZATION_FLAGS=(-O)
    BUILD_CONFIGURATION="release"
fi
FAN_HELPER_ID="$APP_BUNDLE_ID.fan-control"
# Now Playing is read through /usr/bin/perl loading this library; see
# Sources/NowPlayingAdapter. Staged under Contents/Frameworks, signed on its own.
NOW_PLAYING_ADAPTER_ID="$APP_BUNDLE_ID.now-playing"
NOW_PLAYING_ADAPTER="libFuroshikiNowPlaying.dylib"
TARGET="arm64-apple-macosx14.0"
ENTITLEMENTS="Resources/Furoshiki.entitlements"
LEGACY_IDENTITY="Furoshiki Utils Signing"

developer_id_identity() {
    security find-identity -v -p codesigning 2>/dev/null \
        | grep 'Developer ID Application' \
        | head -1 \
        | sed -E 's/.*"(.*)".*/\1/' || true
}

# A find-identity listing also names certificates codesign then rejects (an
# expired one fails the build with errSecInternalComponent), and -v excludes
# every self-signed one; ask codesign itself with a throwaway copy of /bin/echo.
legacy_identity_installed() {
    local probe signed=1
    # A locked keychain still lists its identities but cannot sign with them,
    # and this one is locked after every reboot; unlock it before asking.
    security unlock-keychain -p furoshiki-signing \
        "$HOME/Library/Keychains/furoshiki-signing.keychain-db" 2>/dev/null || true
    probe="$(mktemp)"
    cp /bin/echo "$probe"
    /usr/bin/codesign --force --strip-disallowed-xattrs --sign "$LEGACY_IDENTITY" "$probe" \
        >/dev/null 2>&1 && signed=0
    rm -f "$probe"
    return $signed
}

# Any build that lands in /Applications needs a stable signature, not just the
# Developer one: macOS ties Accessibility and Screen Recording grants to the
# exact binary hash, so an ad-hoc rebuild orphans them while System Settings
# keeps showing them as granted, and no new prompt ever appears. A plain
# --install strands them under the released bundle id, on the app the user
# actually relies on. When no identity is installed, create the stable local one
# up front instead of falling through to ad-hoc — setup-signing.sh is free,
# offline and idempotent. Gating on the install rather than the variant keeps
# this off CI, where neither ci.yml nor release.yml passes --install.
if (( DEV || INSTALL )) && [[ -z "$(developer_id_identity)" ]] \
    && ! legacy_identity_installed; then
    echo "▸ No signing identity installed; creating the stable local one…"
    if ! ./Tools/setup-signing.sh; then
        echo "  ⚠ Tools/setup-signing.sh failed; signing ad-hoc instead." >&2
        echo "    Accessibility and Screen Recording grants will not survive rebuilds:" >&2
        echo "    System Settings will show them as granted while the app is not trusted." >&2
        echo "    After fixing the identity, clear the stale grant once with:" >&2
        echo "      tccutil reset Accessibility $APP_BUNDLE_ID" >&2
    fi
fi

codesign_with_timestamp_retry() {
    local attempt
    for attempt in 1 2 3; do
        if /usr/bin/codesign "$@"; then
            return 0
        fi
        if (( attempt < 3 )); then
            echo "  Developer ID signing failed; retrying ($((attempt + 1))/3)"
            sleep "$attempt"
        fi
    done
    return 1
}

write_swift_output_file_map() {
    local output_file="$1"
    local object_dir="$2"
    shift 2
    local source artifact

    {
        print -r -- "{"
        print -r -- "  \"\": {"
        print -r -- "    \"swift-dependencies\": \"$object_dir/master.swiftdeps\""
        print -r -- "  }"
        for source in "$@"; do
            artifact="${source//\//__}"
            artifact="${artifact%.swift}"
            print -r -- ","
            print -r -- "  \"$source\": {"
            print -r -- "    \"object\": \"$object_dir/$artifact.o\","
            print -r -- "    \"swift-dependencies\": \"$object_dir/$artifact.swiftdeps\""
            print -r -- "  }"
        done
        print -r -- "}"
    } > "$output_file"
}

finalize_installed_bundle_after_child() {
    local bundle="$1"
    local helper="$bundle/Contents/Library/LaunchServices/$FAN_HELPER_ID"
    local adapter="$bundle/Contents/Frameworks/$NOW_PLAYING_ADAPTER"
    local devid
    devid="$(developer_id_identity)"

    echo "▸ Finalizing installed signature…"
    sleep 3
    if [[ -n "$devid" ]]; then
        [[ -f "$helper" ]] && codesign_with_timestamp_retry --force --strip-disallowed-xattrs \
            --options runtime --timestamp --identifier "$FAN_HELPER_ID" --sign "$devid" "$helper"
        [[ -f "$adapter" ]] && codesign_with_timestamp_retry --force --strip-disallowed-xattrs \
            --options runtime --timestamp --identifier "$NOW_PLAYING_ADAPTER_ID" --sign "$devid" "$adapter"
        codesign_with_timestamp_retry --force --strip-disallowed-xattrs --options runtime --timestamp \
            --entitlements "$ENTITLEMENTS" --sign "$devid" "$bundle"
    elif legacy_identity_installed; then
        [[ -f "$helper" ]] && /usr/bin/codesign --force --strip-disallowed-xattrs \
            --identifier "$FAN_HELPER_ID" --sign "$LEGACY_IDENTITY" "$helper"
        [[ -f "$adapter" ]] && /usr/bin/codesign --force --strip-disallowed-xattrs \
            --identifier "$NOW_PLAYING_ADAPTER_ID" --sign "$LEGACY_IDENTITY" "$adapter"
        /usr/bin/codesign --force --strip-disallowed-xattrs --sign "$LEGACY_IDENTITY" "$bundle"
    else
        [[ -f "$helper" ]] && /usr/bin/codesign --force --strip-disallowed-xattrs \
            --identifier "$FAN_HELPER_ID" --sign - "$helper"
        [[ -f "$adapter" ]] && /usr/bin/codesign --force --strip-disallowed-xattrs \
            --identifier "$NOW_PLAYING_ADAPTER_ID" --sign - "$adapter"
        /usr/bin/codesign --force --strip-disallowed-xattrs --sign - "$bundle"
    fi
    [[ -f "$helper" ]] && /usr/bin/codesign --verify --strict "$helper"
    [[ -f "$adapter" ]] && /usr/bin/codesign --verify --strict "$adapter"
    /usr/bin/codesign --verify --deep --strict "$bundle"
    echo "✓ Signature ready: $bundle"
}

if (( INSTALL && ! TEST )) && [[ "${FUROSHIKI_INSTALL_CHILD:-0}" != "1" ]]; then
    FUROSHIKI_INSTALL_CHILD=1 "$0" "$@"
    child_status=$?
    if (( child_status != 0 )); then
        exit "$child_status"
    fi
    finalize_installed_bundle_after_child "/Applications/$APP_NAME.app"
    exit 0
fi

# Prefer the macOS 26 SDK when present: the 27 SDK turns SwiftUI property wrappers
# into macros (SwiftUIMacros plugin) that the Command Line Tools cannot load yet.
PINNED_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk"
if [[ -n "${DEVELOPER_DIR:-}" ]]; then
    SDK="$(xcrun --show-sdk-path)"
elif [[ -d "$PINNED_SDK" ]]; then
    SDK="$PINNED_SDK"
else
    SDK="$(xcrun --show-sdk-path)"
fi
SDK_COMPAT_FLAGS=()
VM_STATISTICS_COMPAT_FLAGS=(-I Sources/VMStatisticsCompat)
HID_EVENT_SYSTEM_FLAGS=(-I Sources/HIDEventSystem)
CORE_AUDIO_TAP_FLAGS=(-I Sources/CoreAudioTapCompat)
GIF_CODEC_FLAGS=(-I Sources/RecorderGIFCodec)
GIF_CODEC_OBJECTS=(build/objects/recorder-gif-codec/RecorderGIFCodec.o
                   build/objects/recorder-gif-codec/cgif_raw.o)
if [[ "$SDK" == "$PINNED_SDK" ]]; then
    # Swift 6.4 can read the SDK 26 interfaces when given their compiler version.
    SDK_COMPAT_FLAGS=(-Xfrontend -interface-compiler-version -Xfrontend 6.3.2)
fi

# The defaults migrations under test need a real UserDefaults suite, and every
# suite leaves an empty plist in ~/Library/Preferences. The tests already clear
# the domains, but cfprefsd writes the emptied file back out around the time the
# process that owned it exits, so only a caller that outlives the run can remove
# them. `PreferenceNamespaceTests` scans every compiled Swift test file against
# these namespaces, which keeps this sweep complete without a second list.
discard_test_preferences() {
    local preferences="${1:-$HOME/Library/Preferences}" name attempt
    local survivors=0 quiet_passes=0
    # cfprefsd can recreate an emptied domain after the first removal. Require
    # two quiet checks, but keep a hard limit so persistent failures still fail CI.
    for attempt in {1..10}; do
        for name in "vorss.tests." "io.github.colinnoah.furoshiki.tests."; do
            rm -f "$preferences"/$name*.plist(N)
        done
        rm -f "$preferences/metrics-tests.plist"
        sleep 0.2
        survivors=$(find "$preferences" -maxdepth 1 \
            \( -name "vorss.tests.*.plist" -o -name "io.github.colinnoah.furoshiki.tests.*.plist" \
               -o -name "metrics-tests.plist" \) 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$survivors" == "0" ]]; then
            quiet_passes=$((quiet_passes + 1))
            if (( quiet_passes == 2 )); then return 0; fi
        else
            quiet_passes=0
        fi
    done
    echo "✗ test preferences did not settle in $preferences ($survivors remaining)" >&2
    return 1
}

# Standalone automated tests: pure contracts plus isolated disk, subprocess,
# keyboard-data and media fixtures. No application windows or device capture.
mkdir -p build/objects/recorder-gif-codec
xcrun clang -O3 -std=c99 -target "$TARGET" -isysroot "$SDK" \
    -c Sources/RecorderGIFCodec/RecorderGIFCodec.c -o "$GIF_CODEC_OBJECTS[1]"
xcrun clang -O3 -std=c99 -target "$TARGET" -isysroot "$SDK" \
    -c Sources/RecorderGIFCodec/vendor/cgif/cgif_raw.c -o "$GIF_CODEC_OBJECTS[2]"

if (( TEST )); then
    python3 Tests/generate_sources.py
    TEST_OBJECT_DIR="build/objects/tests"
    mkdir -p "$TEST_OBJECT_DIR"
    TEST_SOURCES=(
        Sources/Furoshiki/Services/Media/MediaSupport.swift
        Sources/Furoshiki/Core/QuitProtectionSupport.swift
        Sources/Furoshiki/Core/QuitProtectionStrings.swift
        Sources/Furoshiki/Core/Defaults.swift
        Sources/Furoshiki/Core/NotchStrings.swift
        Sources/Furoshiki/Core/NotchTourStrings.swift
        Sources/Furoshiki/Core/NotchEditorStrings.swift
        Sources/Furoshiki/UI/Settings/NotchSettingsTabRow.swift
        Sources/Furoshiki/Core/NotchActivityStrings.swift
        Sources/Furoshiki/Services/Notch/NotchTimerSupport.swift
        Sources/Furoshiki/Services/Notch/NotchAppFullscreen.swift
        Sources/Furoshiki/Services/Notch/NotchTimerAlert.swift
        Sources/Furoshiki/UI/Notch/NotchIslandAlert.swift
        Sources/Furoshiki/Services/Notch/NotchAccessorySupport.swift
        Sources/Furoshiki/Services/Notch/NotchAccessoryConnectionMonitor.swift
        Sources/Furoshiki/Services/QuickTools/CameraPreviewSupport.swift
        Sources/Furoshiki/Core/NotchMusicExtrasStrings.swift
        Sources/Furoshiki/Core/NotchClipboardSizeStrings.swift
        Sources/Furoshiki/Services/Notch/NotchLyricsSupport.swift
        Sources/Furoshiki/Services/Notch/NotchQueueSupport.swift
        Sources/Furoshiki/Services/Notch/NotchPreferredPlayer.swift
        Sources/Furoshiki/Core/NotchFilesStrings.swift
        Sources/Furoshiki/Core/NotchWatchStrings.swift
        Sources/Furoshiki/Services/Notch/NotchWatchSupport.swift
        Sources/Furoshiki/Core/NotchMascotStrings.swift
        Sources/Furoshiki/Services/Notch/NotchMascotSupport.swift
        Sources/Furoshiki/Services/CommandBar/CommandBarDropletMotion.swift
        Sources/Furoshiki/Services/Notch/NotchFileToolsSupport.swift
        Sources/Furoshiki/Services/Notch/NotchDownloadSupport.swift
        Sources/Furoshiki/Services/Notch/NotchDownloadProgressObserver.swift
        Sources/Furoshiki/Core/NotchCalendarStrings.swift
        Sources/Furoshiki/Core/NotchNotificationStrings.swift
        Sources/Furoshiki/Core/NotchGestureStrings.swift
        Sources/Furoshiki/Core/NotchAgentStrings.swift
        Sources/Furoshiki/Core/CodexAccountStrings.swift
        Sources/Furoshiki/Core/ClaudeAccountStrings.swift
        Sources/Furoshiki/Services/Notch/NotchAgentSupport.swift
        Sources/Furoshiki/Core/NotchLockScreenStrings.swift
        Sources/Furoshiki/Services/Notch/NotchLockScreenSupport.swift
        Sources/Furoshiki/Services/AgentUsage/AgentUsageModels.swift
        Sources/Furoshiki/Services/AgentUsage/AgentPricing.swift
        Sources/Furoshiki/Services/AgentUsage/AgentLogObject.swift
        Sources/Furoshiki/Services/AgentUsage/AgentLogParser.swift
        Sources/Furoshiki/Services/AgentUsage/Harness/AgentHarnessReader.swift
        Sources/Furoshiki/Services/AgentUsage/Harness/ClaudeReader.swift
        Sources/Furoshiki/Services/AgentUsage/Harness/CodexReader.swift
        Sources/Furoshiki/Services/AgentUsage/Harness/OpenCodeReader.swift
        Sources/Furoshiki/Services/AgentUsage/Harness/CopilotReader.swift
        Sources/Furoshiki/Services/AgentUsage/AgentUsageSummary.swift
        Sources/Furoshiki/Services/AgentUsage/AgentUsageStore.swift
        Sources/Furoshiki/Services/AgentUsage/AgentUsageArchive.swift
        Sources/Furoshiki/Services/AgentUsage/AgentClaudeAppUsage.swift
        Sources/Furoshiki/Services/AgentUsage/AgentCLIConversation.swift
        Sources/Furoshiki/Services/AgentUsage/AgentClaudeServer.swift
        Sources/Furoshiki/Services/AgentUsage/ClaudeAccountProfile.swift
        Sources/Furoshiki/Services/AgentUsage/AgentCodexServer.swift
        Sources/Furoshiki/Services/AgentUsage/CodexAccountLimits.swift
        Sources/Furoshiki/Services/AgentUsage/CodexProfileLimitsService.swift
        Sources/Furoshiki/Services/AgentUsage/AgentOpenCodeReader.swift
        Sources/Furoshiki/Services/Notch/NotchGestureSupport.swift
        Sources/Furoshiki/Services/Notch/NotchSectionPaging.swift
        Sources/Furoshiki/Services/Notch/NotchSliderEditing.swift
        Sources/Furoshiki/Services/Notch/NotchNotificationSupport.swift
        Sources/Furoshiki/Services/Notch/NotchNotificationReaderCore.swift
        Sources/Furoshiki/Services/Notch/NotchCalendarSupport.swift
        Sources/Furoshiki/Services/Notch/NotchKeepAwakeSupport.swift
        Sources/Furoshiki/Services/Notch/NotchSupport.swift
        Sources/Furoshiki/Services/Notch/NotchMenuBarSpace.swift
        Sources/Furoshiki/Services/Notch/NotchAudioLevelSupport.swift
        Sources/Furoshiki/Services/Notch/NotchVolumeKeyGate.swift
        Sources/Furoshiki/Services/Notch/NotchMusicSupport.swift
        Sources/Furoshiki/UI/Notch/NotchDecorativeClock.swift
        Sources/Furoshiki/Services/Notch/NotchBrowserArtworkSupport.swift
        Sources/Furoshiki/UI/Notch/NotchEqualizerBars.swift
        Sources/Furoshiki/UI/Notch/NotchScrollEdgeFade.swift
        Sources/Furoshiki/UI/Notch/NotchAgentAnimationView.swift
        Sources/Furoshiki/UI/WindowVisibilityReader.swift
        Sources/Furoshiki/Services/Notch/NotchMusicAutomationSupport.swift
        Sources/Furoshiki/Services/Notch/NotchMusicAutomation.swift
        Sources/Furoshiki/Services/Notch/NotchPlaybackSource.swift
        Sources/Furoshiki/Services/Notch/NotchPlaybackCommand.swift
        Sources/Furoshiki/Services/Notch/NotchMusicCommandWriter.swift
        Sources/Furoshiki/Core/FeatureCatalog.swift
        Sources/Furoshiki/Core/FeaturePresets.swift
        Sources/Furoshiki/Core/FeatureHubStrings.swift
        Sources/Furoshiki/Core/MixerScreenSharingStrings.swift
        Sources/Furoshiki/Core/ShortcutSettingsStrings.swift
        Sources/Furoshiki/Core/SwitcherShortcutStrings.swift
        Sources/Furoshiki/Core/SettingsBackupSupport.swift
        Sources/Furoshiki/Core/BackupStrings.swift
        Sources/Furoshiki/Core/SnippetStrings.swift
        Sources/Furoshiki/Core/AlertSoundStrings.swift
        Sources/Furoshiki/Core/BrightnessStrings.swift
        Sources/Furoshiki/Core/MediaImageStrings.swift
        Sources/Furoshiki/Core/QuickToggleStrings.swift
        Sources/Furoshiki/Core/ScreenshotStrings.swift
        Sources/Furoshiki/Core/RecentCaptureStrings.swift
        Sources/Furoshiki/Core/RecorderStrings.swift
        Sources/Furoshiki/Core/CameraPreviewStrings.swift
        Sources/Furoshiki/Core/WallpaperStrings.swift
        Sources/Furoshiki/Services/Wallpaper/WallpaperSupport.swift
        Sources/Furoshiki/UI/MenuPanel/WallpaperThumbnailView.swift
        Sources/Furoshiki/Core/ScratchpadStrings.swift
        Sources/Furoshiki/Core/FinderRenameStrings.swift
        Sources/Furoshiki/Core/CommandBarStrings.swift
        Sources/Furoshiki/Core/FeedbackStrings.swift
        Sources/Furoshiki/Core/RadialMenuStrings.swift
        Sources/Furoshiki/Core/MenuBarAppearanceStrings.swift
        Sources/Furoshiki/Core/AppAppearance.swift
        Sources/Furoshiki/Core/AppearanceStrings.swift
        Sources/Furoshiki/Core/GeneralSettingsStrings.swift
        Sources/Furoshiki/Core/SettingsPageStrings.swift
        Sources/Furoshiki/Core/BatteryTimeStrings.swift
        Sources/Furoshiki/Core/CPUCoreStrings.swift
        Sources/Furoshiki/Core/MonitorLayoutStrings.swift
        Sources/Furoshiki/Core/KeepAwakeStrings.swift
        Sources/Furoshiki/Core/BluetoothSleepStrings.swift
        Sources/Furoshiki/Core/PermissionGuideStrings.swift
        Sources/Furoshiki/Core/FanControlStrings.swift
        Sources/Furoshiki/Core/ConnectedDevicesStrings.swift
        Sources/Furoshiki/Services/FanControl/FanControlSupport.swift
        Sources/Furoshiki/Services/FanControl/FanControlResumeSupport.swift
        Sources/Furoshiki/Services/Snippets/TextSnippetSupport.swift
        Sources/Furoshiki/Services/RadialMenu/RadialMenuSupport.swift
        Sources/Furoshiki/Services/QuickTools/ScratchpadSupport.swift
        Sources/Furoshiki/Services/QuickTools/ScratchpadStore.swift
        Sources/Furoshiki/Services/KillProcess/KillProcessSupport.swift
        Sources/Furoshiki/Services/Recorder/RecorderSupport.swift
        Sources/Furoshiki/Services/Recorder/RecorderSampleTiming.swift
        Sources/Furoshiki/Services/Recorder/RecorderWriter.swift
        Sources/Furoshiki/Services/Recorder/RecorderCaptureEngine.swift
        Sources/Furoshiki/Core/RecorderExportStrings.swift
        Sources/Furoshiki/Core/RecorderExportFormatStrings.swift
        Sources/Furoshiki/Services/Recorder/RecorderComposer.swift
        Sources/Furoshiki/Services/Recorder/RecorderComposerPlan.swift
        Sources/Furoshiki/Services/Recorder/RecorderCursorSprite.swift
        Sources/Furoshiki/Services/Recorder/RecorderTextRenderer.swift
        Sources/Furoshiki/Services/Recorder/RecorderImageRenderer.swift
        Sources/Furoshiki/Services/Recorder/RecorderExporter.swift
        Sources/Furoshiki/Services/Recorder/RecorderGIFClipboard.swift
        Sources/Furoshiki/Services/Recorder/RecorderGIFWriter.swift
        Sources/Furoshiki/Services/Recorder/RecorderFastGIFWriter.swift
        Sources/Furoshiki/Services/Recorder/RecorderGIFWorkspace.swift
        Sources/Furoshiki/Services/Recorder/RecorderComposition.swift
        Sources/Furoshiki/Services/PrivateFileStore.swift
        Sources/Furoshiki/Services/Recorder/RecorderTakeStore.swift
        Sources/Furoshiki/Services/Recorder/RecorderPresetImageStore.swift
        Sources/Furoshiki/Services/Recorder/RecorderMotion.swift
        Sources/Furoshiki/Services/Recorder/RecorderPointerTrack.swift
        Sources/Furoshiki/Services/Recorder/RecorderTypingTrack.swift
        Sources/Furoshiki/Services/Recorder/RecorderTimeline.swift
        Sources/Furoshiki/Services/Recorder/RecorderTextOverlay.swift
        Sources/Furoshiki/Services/Recorder/RecorderImageOverlay.swift
        Sources/Furoshiki/Services/Recorder/RecorderBlurRegion.swift
        Sources/Furoshiki/Services/Recorder/RecorderEditDocument.swift
        Sources/Furoshiki/Core/AppInfo.swift
        Sources/Furoshiki/Core/GlobalShortcut.swift
        Sources/Furoshiki/Core/SymbolicHotKeys.swift
        Sources/Furoshiki/Services/SystemShortcutTakeoverSupport.swift
        Sources/Furoshiki/Core/Localization.swift
        Sources/Furoshiki/Core/Localizations/Strings+*.swift
        Sources/Furoshiki/Core/FeatureStrings.swift
        Sources/Furoshiki/Core/KillProcessStrings.swift
        Sources/Furoshiki/Core/PortManagerStrings.swift
        Sources/Furoshiki/Core/WhatsAppDownloadStrings.swift
        Sources/Furoshiki/Core/WhatsAppOrganizerStrings.swift
        Sources/Furoshiki/Core/ReleaseNotes.swift
        Sources/Furoshiki/Core/ReleaseDigest.swift
        Sources/Furoshiki/Core/ReleaseChangeAliases.swift
        Sources/Furoshiki/Core/WhatsNewStrings.swift
        Sources/Furoshiki/Core/URLCleaning.swift
        Sources/Furoshiki/Services/URLCleanerLinkMetadata.swift
        Sources/Furoshiki/Services/GeneralPasteboardAccess.swift
        Sources/Furoshiki/Services/Clipboard/ClipboardHistoryWrite.swift
        Sources/Furoshiki/Services/Audio/AirPlayRouteManager.swift
        Sources/Furoshiki/Services/Audio/MixerRoutingSupport.swift
        Sources/Furoshiki/Services/Audio/MusicLaunchSupport.swift
        Sources/Furoshiki/Services/Bluetooth/BluetoothSleepSupport.swift
        Sources/Furoshiki/UI/MenuPanel/MixerPercentNativeTextField.swift
        Sources/Furoshiki/UI/MenuPanel/MixerAppDragSource.swift
        Sources/Furoshiki/Services/Audio/BoostLimiter.swift
        Sources/Furoshiki/Services/Audio/MixerRender.swift
        Sources/Furoshiki/Services/Audio/PreciseVolumeRollerSupport.swift
        Sources/Furoshiki/Services/DockPreview/DockPreviewSupport.swift
        Sources/Furoshiki/Services/DockPreview/DockAutohideHold.swift
        Sources/Furoshiki/Services/SpacesOrder/SpacesOrderHold.swift
        Sources/Furoshiki/Services/Homebrew/HomebrewSupport.swift
        Sources/Furoshiki/Services/Homebrew/HomebrewEnvironment.swift
        Sources/Furoshiki/Services/Homebrew/HomebrewManager.swift
        Sources/Furoshiki/UI/HomebrewOperationStatusView.swift
        Sources/Furoshiki/Services/AppUpdates/AppUpdatesSupport.swift
        Sources/Furoshiki/Services/AppUpdates/AppUpdateFeedSupport.swift
        Sources/Furoshiki/Core/AppUpdateStrings.swift
        Sources/Furoshiki/Core/DiskImageInstallerStrings.swift
        Sources/Furoshiki/Services/DiskImageInstaller/DiskImageInstallerSupport.swift
        Sources/Furoshiki/UI/NonModalAlert.swift
        Sources/Furoshiki/Services/Clipboard/ClipboardHistorySupport.swift
        Sources/Furoshiki/Core/ColorValue.swift
        Sources/Furoshiki/Services/Clipboard/ClipboardAutoClearSupport.swift
        Sources/Furoshiki/Services/AutoQuit/AutoQuitSupport.swift
        Sources/Furoshiki/Core/AutoQuitDockAppsStrings.swift
        Sources/Furoshiki/Services/Shelf/ShelfSupport.swift
        Sources/Furoshiki/Services/Shelf/ShelfFilePromiseTransfer.swift
        Sources/Furoshiki/Core/ShelfPromiseDeliveryStrings.swift
        Sources/Furoshiki/Services/Finder/FinderRenameSupport.swift
        Sources/Furoshiki/Services/Update/UpdateInstallerSupport.swift
        Sources/Furoshiki/Services/Update/UpdateServiceSupport.swift
        Sources/Furoshiki/Services/InstalledApps.swift
        Sources/Furoshiki/Services/LaunchAtLoginSupport.swift
        Sources/Furoshiki/UI/Settings/SettingsSearchSupport.swift
        Sources/Furoshiki/UI/Settings/SettingsSidebarSupport.swift
        Sources/Furoshiki/UI/Settings/FeatureVisibilitySupport.swift
        Sources/Furoshiki/UI/Onboarding/WhatsNewSupport.swift
        Sources/Furoshiki/UI/Settings/SettingsWindow.swift
        Sources/Furoshiki/Core/SettingsNavigationStrings.swift
        Sources/Furoshiki/App/MenuBarSpacingSupport.swift
        Sources/Furoshiki/App/MenuBarAllowanceSupport.swift
        Sources/Furoshiki/App/ReopenRequestSupport.swift
        Sources/Furoshiki/App/StatusItemAnchorSupport.swift
        Sources/Furoshiki/Services/DockClick/DockClickSupport.swift
        Sources/Furoshiki/Services/Finder/CutPasteProgressSupport.swift
        Sources/Furoshiki/Services/Finder/CutPastePrivilegeSupport.swift
        Sources/Furoshiki/Services/Finder/FinderPasteImageSupport.swift
        Sources/Furoshiki/Services/MiddleClick/MiddleClickSupport.swift
        Sources/Furoshiki/Services/MouseNavigation/MouseNavigationSupport.swift
        Sources/Furoshiki/Services/MouseNavigation/MouseNavigationKeys.swift
        Sources/Furoshiki/Services/MouseButtons/MouseButtonShortcutSupport.swift
        Sources/Furoshiki/Services/MouseButtons/MouseSpacesGestureSupport.swift
        Sources/Furoshiki/Services/MouseClickDebounce/MouseClickDebounceSupport.swift
        Sources/Furoshiki/Services/MouseExceptions/MouseAppExceptionSupport.swift
        Sources/Furoshiki/Services/MouseExceptions/MouseAppExceptions.swift
        Sources/Furoshiki/Services/WindowServerSupport.swift
        Sources/Furoshiki/Services/WindowMaximizerSupport.swift
        Sources/Furoshiki/Core/MouseButtonStrings.swift
        Sources/Furoshiki/Core/MouseClickDebounceStrings.swift
        Sources/Furoshiki/Core/MouseExceptionStrings.swift
        Sources/Furoshiki/Core/ClipboardIgnoredAppsStrings.swift
        Sources/Furoshiki/Core/ClipboardRetentionStrings.swift
        Sources/Furoshiki/Core/WindowLayoutIgnoredAppsStrings.swift
        Sources/Furoshiki/Services/WindowLayout/WindowLayoutIgnoredApps.swift
        Sources/Furoshiki/Core/WindowPreviewExclusionStrings.swift
        Sources/Furoshiki/Core/WindowMaximizerExclusionStrings.swift
        Sources/Furoshiki/Core/DiskExclusionStrings.swift
        Sources/Furoshiki/Core/SwitcherAppRulesStrings.swift
        Sources/Furoshiki/Services/QuickTools/QuickToolsSupport.swift
        Sources/Furoshiki/Services/CommandBar/CommandBarSupport.swift
        Sources/Furoshiki/Services/CommandBar/CommandBarPreferences.swift
        Sources/Furoshiki/Services/CommandBar/CommandBarMath.swift
        Sources/Furoshiki/Services/CommandBar/CommandBarUnits.swift
        Sources/Furoshiki/Services/CommandBar/CommandBarColors.swift
        Sources/Furoshiki/Services/CommandBar/CommandBarEmoji.swift
        Sources/Furoshiki/Services/CommandBar/CommandBarLinks.swift
        Sources/Furoshiki/Services/CommandBar/CommandBarDates.swift
        Sources/Furoshiki/Services/CommandBar/CommandBarRowShortcuts.swift
        Sources/Furoshiki/Services/CommandBar/CommandBarSystemSettingsSupport.swift
        Sources/Furoshiki/Services/CommandBar/CommandBarFileSearchSupport.swift
        Sources/Furoshiki/Services/CommandBar/CommandBarQueryMemory.swift
        Sources/Furoshiki/Services/SpotlightNamesSupport.swift
        Sources/Furoshiki/Services/QuickTools/MicMuteSupport.swift
        Sources/Furoshiki/Services/QuickTools/QuickTogglesSupport.swift
        Sources/Furoshiki/Services/QuickTools/ScreenshotCapturePolicy.swift
        Sources/Furoshiki/Services/QuickTools/ScreenshotSupport.swift
        Sources/Furoshiki/Services/QuickTools/ScreenshotCanvasSupport.swift
        Sources/Furoshiki/Services/QuickTools/ScreenshotImageImport.swift
        Sources/Furoshiki/Services/Media/MediaImageProcessing.swift
        Sources/Furoshiki/Services/QuickTools/ScreenshotImageFile.swift
        Sources/Furoshiki/UI/Settings/ScreenCaptureToolPicker.swift
        Sources/Furoshiki/UI/Settings/MonitorToken.swift
        Sources/Furoshiki/Services/QuickTools/ScreenshotRenderer.swift
        Sources/Furoshiki/Services/QuickTools/ScreenshotImageLayerRendering.swift
        Sources/Furoshiki/Services/QuickTools/RecentCaptureStore.swift
        Sources/Furoshiki/Services/QuickTools/WindowActivationPolicy.swift
        Sources/Furoshiki/Services/KeyboardDebounce/KeyboardDebounceSupport.swift
        Sources/Furoshiki/Services/SuperKey/SuperKeySupport.swift
        Sources/Furoshiki/Services/SuperKey/SuperKeyMappingGuard.swift
        Sources/Furoshiki/Core/SuperKeyStrings.swift
        Sources/Furoshiki/Core/InputSourceSelection.swift
        Sources/Furoshiki/Services/SessionActivity.swift
        Sources/Furoshiki/Services/SessionActivitySupport.swift
        Sources/Furoshiki/Services/EventTimestamp.swift
        Sources/Furoshiki/Services/OwnKeyEvent.swift
        Sources/Furoshiki/Services/ScrollWheelSupport.swift
        Sources/Furoshiki/Services/HorizontalWheelScrolling.swift
        Sources/Furoshiki/Services/SmoothScrollSupport.swift
        Sources/Furoshiki/Services/MouseAcceleration/MouseAccelerationSupport.swift
        Sources/Furoshiki/Services/FocusFollowsMouse/FocusFollowsMouseSupport.swift
        Sources/Furoshiki/Services/AssistiveKeyboard.swift
        Sources/Furoshiki/Services/Switcher/SwitcherModels.swift
        Sources/Furoshiki/Services/Switcher/WindowServerCaptureQueue.swift
        Sources/Furoshiki/Services/Switcher/SwitcherSupport.swift
        Sources/Furoshiki/Services/Switcher/SpaceHopSupport.swift
        Sources/Furoshiki/Services/Switcher/WindowUseOrder.swift
        Sources/Furoshiki/Services/Switcher/WindowEnumeratorAccessibilityPrefetch.swift
        Sources/Furoshiki/Services/Metrics/MetricFormat.swift
        Sources/Furoshiki/Services/Metrics/VMStatisticsDecoder.swift
        Sources/Furoshiki/Services/KeepAwakeAutomationSupport.swift
        Sources/Furoshiki/Services/SudoersSupport.swift
        Sources/Furoshiki/Services/Metrics/BatteryTimeSupport.swift
        Sources/Furoshiki/Services/Metrics/BatteryPowerSupport.swift
        Sources/Furoshiki/Services/BoundedProcessRunner.swift
        Sources/Furoshiki/Services/DetachedProcess.swift
        Sources/Furoshiki/Services/ShellSupport.swift
        Sources/Furoshiki/Services/PortManager/PortManagerSupport.swift
        Sources/Furoshiki/Services/Metrics/NetworkProcessSupport.swift
        Sources/Furoshiki/Services/Metrics/NetworkSampler.swift
        Sources/Furoshiki/Services/Metrics/NetworkAddressService.swift
        Sources/Furoshiki/Services/Metrics/SpeedTest.swift
        Sources/Furoshiki/Services/Metrics/PeripheralBatterySampler.swift
        Sources/Furoshiki/Services/Metrics/PeripheralBatterySupport.swift
        Sources/Furoshiki/Services/Metrics/DiskSupport.swift
        Sources/Furoshiki/Services/Metrics/MonitorSamplingPolicy.swift
        Sources/Furoshiki/Services/Metrics/USBDeviceSampler.swift
        Sources/Furoshiki/Services/Metrics/CPUCoreSampler.swift
        Sources/Furoshiki/Services/Metrics/MaxCapacityProbe.swift
        Sources/Furoshiki/Services/Metrics/TemperatureSensorSelector.swift
        Sources/Furoshiki/Services/Metrics/SustainedAlertGate.swift
        Sources/Furoshiki/Services/WindowLayout/WindowLayoutSupport.swift
        Sources/Furoshiki/Services/WindowLayout/WindowStageManagerSupport.swift
        Sources/Furoshiki/Core/WindowStageManagerStrings.swift
        Sources/Furoshiki/Core/WindowEdgeSnapRestoreStrings.swift
        Sources/Furoshiki/Services/WindowLayout/WindowGestureSupport.swift
        Sources/Furoshiki/Core/WindowDirectionalStrings.swift
        Sources/Furoshiki/Core/PointerDisplayStrings.swift
        Sources/Furoshiki/Core/GraphScaleStrings.swift
        Sources/Furoshiki/Core/NotchLowBatteryStrings.swift
        Sources/Furoshiki/Services/CleaningMode/CleaningUnlockCounter.swift
        Sources/Furoshiki/Services/CleaningMode/CleaningMouseReleaseGate.swift
        Sources/Furoshiki/Services/Display/ExtraBrightnessSupport.swift
        Sources/Furoshiki/Services/Display/BrightnessSupport.swift
        Sources/Furoshiki/Services/Display/MonitorVolumeKeySettings.swift
        Sources/Furoshiki/Services/Display/LidDimmingSupport.swift
        Sources/Furoshiki/Services/Cleaner/CleanerSupport.swift
        Sources/Furoshiki/Services/Cleaner/CleanerPolicy.swift
        Sources/Furoshiki/Services/Cleaner/CleanerSchedule.swift
        Sources/Furoshiki/Services/Uninstall/UninstallerSupport.swift
        Sources/Furoshiki/Services/ManagedDownloads/WhatsAppDownloadSupport.swift
        Sources/Furoshiki/Core/SecureInputSupport.swift
        Tests/*.swift
        build/generated-tests/*.swift
    )
    TEST_OUTPUT_FILE_MAP="$TEST_OBJECT_DIR/output-file-map.json"
    write_swift_output_file_map "$TEST_OUTPUT_FILE_MAP" "$TEST_OBJECT_DIR" "${TEST_SOURCES[@]}"
    echo "▸ Building & running tests against $(basename "$SDK")…"
    swiftc -Onone -incremental -enable-batch-mode -j "$(sysctl -n hw.logicalcpu)" \
        -module-name FuroshikiTests -output-file-map "$TEST_OUTPUT_FILE_MAP" \
        -target "$TARGET" -sdk "$SDK" "${SDK_COMPAT_FLAGS[@]}" \
        "${VM_STATISTICS_COMPAT_FLAGS[@]}" "${CORE_AUDIO_TAP_FLAGS[@]}" "${GIF_CODEC_FLAGS[@]}" \
        "${TEST_SOURCES[@]}" "${GIF_CODEC_OBJECTS[@]}" -o build/metrics-tests
    test_status=0
    ./build/metrics-tests "${TEST_ARGS[@]}" || test_status=$?
    if (( ${#TEST_ARGS} == 0 )); then
        ./Tests/PreferenceCleanupTests.sh || test_status=1
        ./Tests/UninstallSpacesTests.sh || test_status=1
        ./Tests/DeveloperInstallIsolationTests.sh || test_status=1
    fi
    discard_test_preferences || test_status=1
    exit $test_status
fi

echo "▸ Compiling ($BUILD_CONFIGURATION) against $(basename "$SDK")…"
APP_SOURCES=(Sources/Furoshiki/**/*.swift)
if (( ! DEV )); then
    # A release starts from an empty build directory, so nothing an earlier
    # build left behind (an old icon catalog, a staged bundle) can reach it.
    # Only the compiler's incremental records stay: they rebuild whatever
    # changed since, and a fresh checkout has none.
    find build -mindepth 1 -maxdepth 1 ! -name objects -exec rm -rf {} + 2>/dev/null || true
fi
APP_OBJECT_DIR="build/objects/$EXECUTABLE"
mkdir -p build "$APP_OBJECT_DIR"
APP_OUTPUT_FILE_MAP="$APP_OBJECT_DIR/output-file-map.json"
write_swift_output_file_map "$APP_OUTPUT_FILE_MAP" "$APP_OBJECT_DIR" "${APP_SOURCES[@]}"
# Without -j the driver compiles one file at a time, and without batch mode
# each file's compiler parses the whole module again: a clean release took a
# quarter of an hour. Batches share that work and run on every core, and the
# optimization stays per file, as before.
swiftc "${APP_OPTIMIZATION_FLAGS[@]}" -incremental -enable-batch-mode -j "$(sysctl -n hw.logicalcpu)" \
    -output-file-map "$APP_OUTPUT_FILE_MAP" \
    -target "$TARGET" -sdk "$SDK" "${SDK_COMPAT_FLAGS[@]}" "${VM_STATISTICS_COMPAT_FLAGS[@]}" "${HID_EVENT_SYSTEM_FLAGS[@]}" \
    "${CORE_AUDIO_TAP_FLAGS[@]}" "${GIF_CODEC_FLAGS[@]}" \
    "${BUILD_VARIANT_FLAGS[@]}" \
    "${APP_SOURCES[@]}" "${GIF_CODEC_OBJECTS[@]}" -o "build/$EXECUTABLE"
xcrun dyld_info -imports "build/$EXECUTABLE" | awk -f Tests/AudioTapImports.awk

echo "▸ Compiling protected fan helper…"
swiftc -O -target "$TARGET" -sdk "$SDK" "${SDK_COMPAT_FLAGS[@]}" "${BUILD_VARIANT_FLAGS[@]}" \
    Sources/Furoshiki/Services/FanControl/FanControlSupport.swift \
    Sources/Furoshiki/Services/FanControl/FanControlXPC.swift \
    Sources/Furoshiki/Services/SystemMonitor/SMCClient.swift \
    Sources/Furoshiki/Services/Metrics/TemperatureSensorSelector.swift \
    Sources/Furoshiki/Services/FanControl/FanControlHardware.swift \
    Sources/FanControlHelper/main.swift \
    -o "build/$FAN_HELPER_ID"
"build/$FAN_HELPER_ID" --selftest

echo "▸ Compiling Now Playing adapter…"
swiftc -O -target "$TARGET" -sdk "$SDK" "${SDK_COMPAT_FLAGS[@]}" -emit-library \
    -module-name FuroshikiNowPlaying \
    Sources/NowPlayingAdapter/NowPlayingAdapter.swift \
    Sources/NowPlayingAdapter/NowPlayingQueue.swift \
    Sources/NowPlayingAdapter/NowPlayingSelection.swift \
    Sources/Furoshiki/Services/Notch/NotchPlaybackSource.swift \
    Sources/Furoshiki/Services/Notch/NotchPlaybackCommand.swift \
    -o "build/$NOW_PLAYING_ADAPTER"

echo "▸ Generating app icon…"
swift Tools/MakeIcon.swift build/AppIcon.iconset
xattr -c -r build/AppIcon.iconset build/AppIcon.icns build/MenuBarIcon.png build/MenuBarIcon@2x.png build/BrandMark.png 2>/dev/null || true
ACTOOL_BIN="$(xcrun --find actool 2>/dev/null || true)"
ICON_TMP="$(mktemp -d)"
ADAPTIVE_SKIP=""
if [[ -z "$ACTOOL_BIN" ]]; then
    ADAPTIVE_SKIP="actool not found (adaptive icons need Xcode 26+)"
else
    echo "▸ Compiling adaptive icon catalog…"
    # actool crashes on File Provider-synced paths, so compile a local copy.
    ditto "Resources/Brand/AppIcon.icon" "$ICON_TMP/AppIcon.icon"
    # Xcode 27 beta actool requires the --compile target directory to already exist.
    mkdir -p "$ICON_TMP/catalog"
    if "$ACTOOL_BIN" "$ICON_TMP/AppIcon.icon" \
            --compile "$ICON_TMP/catalog" \
            --app-icon AppIcon \
            --platform macosx \
            --target-device mac \
            --minimum-deployment-target 14.0 \
            --enable-on-demand-resources NO \
            --output-partial-info-plist "$ICON_TMP/partial-info.plist" \
            >"$ICON_TMP/actool.log" 2>&1 && [[ -s "$ICON_TMP/catalog/Assets.car" ]]; then
        mv "$ICON_TMP/catalog/Assets.car" build/Assets.car
    else
        ADAPTIVE_SKIP="actool could not compile the catalog"
    fi
fi
if [[ -n "$ADAPTIVE_SKIP" ]]; then
    cp "$ICON_TMP/actool.log" build/actool-failure.log 2>/dev/null || true
    echo "  adaptive icon skipped: $ADAPTIVE_SKIP (Dock falls back to AppIcon.icns)"
fi
echo "▸ Assembling and signing bundle…"
STAGE_TMP="$(mktemp -d)"
STAGE="$STAGE_TMP/$APP_NAME.app"
mkdir -p "$STAGE/Contents/MacOS" "$STAGE/Contents/Resources" \
    "$STAGE/Contents/Library/LaunchDaemons" "$STAGE/Contents/Library/LaunchServices"
cp "build/$EXECUTABLE" "$STAGE/Contents/MacOS/$EXECUTABLE"
cp "build/$FAN_HELPER_ID" "$STAGE/Contents/Library/LaunchServices/$FAN_HELPER_ID"
mkdir -p "$STAGE/Contents/Frameworks"
cp "build/$NOW_PLAYING_ADAPTER" "$STAGE/Contents/Frameworks/$NOW_PLAYING_ADAPTER"
cp Resources/now-playing.pl "$STAGE/Contents/Resources/now-playing.pl"
cp Resources/agent-prices.json "$STAGE/Contents/Resources/agent-prices.json"
cp Resources/io.github.colinnoah.furoshiki.fan-control.plist \
    "$STAGE/Contents/Library/LaunchDaemons/$FAN_HELPER_ID.plist"
cp Resources/Info.plist "$STAGE/Contents/Info.plist"
cp CHANGELOG.md "$STAGE/Contents/Resources/CHANGELOG.md"
for lproj in Resources/*.lproj(N); do
    cp -R "$lproj" "$STAGE/Contents/Resources/"
done
if (( DEV )); then
    # A distinct identity so the Developer build installs and runs next to the
    # official app, with its own permissions, preferences and login item.
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $APP_BUNDLE_ID" "$STAGE/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_NAME" "$STAGE/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" "$STAGE/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $EXECUTABLE" "$STAGE/Contents/Info.plist"
    FAN_PLIST="$STAGE/Contents/Library/LaunchDaemons/$FAN_HELPER_ID.plist"
    /usr/libexec/PlistBuddy -c "Set :Label $FAN_HELPER_ID" "$FAN_PLIST"
    /usr/libexec/PlistBuddy -c "Set :BundleProgram Contents/Library/LaunchServices/$FAN_HELPER_ID" "$FAN_PLIST"
    /usr/libexec/PlistBuddy -c "Delete :MachServices:io.github.colinnoah.furoshiki.fan-control" "$FAN_PLIST"
    /usr/libexec/PlistBuddy -c "Add :MachServices:$FAN_HELPER_ID bool true" "$FAN_PLIST"
    # Stamp the source commit + build time so the running dev app shows (in About)
    # exactly which code it was compiled from. Lets you verify it matches HEAD before
    # testing, instead of unknowingly running a stale build. Dev-only; never shipped.
    SHA="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
    [[ -n "$(git status --porcelain 2>/dev/null)" ]] && SHA="$SHA-dirty"
    /usr/libexec/PlistBuddy -c "Add :FuroshikiBuildCommit string '$SHA · $(date '+%Y-%m-%d %H:%M')'" "$STAGE/Contents/Info.plist"
    echo "  stamped dev build: $SHA"
fi
FAN_HELPER_VERSION="$(
    export LC_ALL=C
    /usr/bin/shasum -a 256 \
        "$STAGE/Contents/Library/LaunchServices/$FAN_HELPER_ID" \
        "$STAGE/Contents/Library/LaunchDaemons/$FAN_HELPER_ID.plist" \
        | /usr/bin/awk '{print $1}' | /usr/bin/shasum -a 256 \
        | /usr/bin/awk '{print $1}'
)"
/usr/libexec/PlistBuddy -c "Add :FuroshikiFanControlHelperVersion string '$FAN_HELPER_VERSION'" \
    "$STAGE/Contents/Info.plist"
printf 'APPL????' > "$STAGE/Contents/PkgInfo"
cp build/AppIcon.icns "$STAGE/Contents/Resources/AppIcon.icns"
cp Sources/RecorderGIFCodec/vendor/cgif/LICENSE "$STAGE/Contents/Resources/cgif-LICENSE.txt"
cp build/MenuBarIcon.png build/MenuBarIcon@2x.png build/BrandMark.png "$STAGE/Contents/Resources/"
if [[ -f build/Assets.car ]]; then
    cp build/Assets.car "$STAGE/Contents/Resources/Assets.car"
fi
if [[ -d Resources/Gifs ]]; then
    mkdir -p "$STAGE/Contents/Resources/Gifs"
    cp Resources/Gifs/*.gif "$STAGE/Contents/Resources/Gifs/"
fi
if ! cmp -s Resources/Gifs/highlights-notch.gif "$STAGE/Contents/Resources/Gifs/highlights-notch.gif"; then
    echo "Dynamic Island tour GIF is missing or differs from the bundled copy" >&2
    exit 1
fi
if [[ -d Resources/Images ]]; then
    mkdir -p "$STAGE/Contents/Resources/Images"
    cp Resources/Images/* "$STAGE/Contents/Resources/Images/"
fi
xattr -c -r "$STAGE" 2>/dev/null || true

# Signing, in order of preference:
#   1. Developer ID Application — the real, Apple-issued identity used for
#      notarized releases. Signed with the hardened runtime (required for
#      notarization), the app's entitlements and a secure timestamp. Gives a
#      stable, team-based designated requirement, so permissions persist across
#      updates AND Gatekeeper shows no "unverified developer" warning.
#   2. "Furoshiki Utils Signing" — the legacy stable self-signed identity, kept
#      as a fallback so contributors without a Developer ID still get a constant
#      designated requirement across their local builds.
#   3. Ad-hoc — fresh clone with no identity at all.
DEVID="$(developer_id_identity)"
codesign_app() {
    local target="$1"
    if [[ -n "$DEVID" ]]; then
        codesign_with_timestamp_retry --force --strip-disallowed-xattrs --options runtime --timestamp \
            --entitlements "$ENTITLEMENTS" --sign "$DEVID" "$target"
    elif legacy_identity_installed; then
        codesign --force --strip-disallowed-xattrs --sign "$LEGACY_IDENTITY" "$target"
    else
        codesign --force --strip-disallowed-xattrs --sign - "$target"
    fi
}

codesign_fan_helper() {
    local target="$1"
    if [[ -n "$DEVID" ]]; then
        codesign_with_timestamp_retry --force --strip-disallowed-xattrs --options runtime --timestamp \
            --identifier "$FAN_HELPER_ID" --sign "$DEVID" "$target"
    elif legacy_identity_installed; then
        codesign --force --strip-disallowed-xattrs --identifier "$FAN_HELPER_ID" \
            --sign "$LEGACY_IDENTITY" "$target"
    else
        codesign --force --strip-disallowed-xattrs --identifier "$FAN_HELPER_ID" --sign - "$target"
    fi
}

codesign_now_playing_adapter() {
    local target="$1"
    if [[ -n "$DEVID" ]]; then
        codesign_with_timestamp_retry --force --strip-disallowed-xattrs --options runtime --timestamp \
            --identifier "$NOW_PLAYING_ADAPTER_ID" --sign "$DEVID" "$target"
    elif legacy_identity_installed; then
        codesign --force --strip-disallowed-xattrs --identifier "$NOW_PLAYING_ADAPTER_ID" \
            --sign "$LEGACY_IDENTITY" "$target"
    else
        codesign --force --strip-disallowed-xattrs --identifier "$NOW_PLAYING_ADAPTER_ID" --sign - "$target"
    fi
}

sign_bundle() {
    local bundle="$1"
    local executable="$bundle/Contents/MacOS/$EXECUTABLE"
    local helper="$bundle/Contents/Library/LaunchServices/$FAN_HELPER_ID"
    local adapter="$bundle/Contents/Frameworks/$NOW_PLAYING_ADAPTER"

    if [[ -n "$DEVID" ]]; then
        echo "  signing with Developer ID (hardened runtime): $DEVID"
    elif legacy_identity_installed; then
        echo "  signing with legacy self-signed identity: $LEGACY_IDENTITY"
    else
        echo "  signing ad-hoc (no identity installed — run Tools/setup-signing.sh)"
    fi
    [[ -f "$helper" ]] && codesign_fan_helper "$helper"
    [[ -f "$adapter" ]] && codesign_now_playing_adapter "$adapter"
    codesign_app "$bundle"

    # If local filesystem metadata invalidates the first signature, sign once
    # more. The installed Developer bundle is signed again after the final copy.
    if ! codesign --verify --deep --strict "$bundle" >/dev/null 2>&1; then
        echo "  re-signing after filesystem metadata settled"
        xattr -c -r "$bundle" 2>/dev/null || true
        [[ -f "$helper" ]] && codesign_fan_helper "$helper"
        [[ -f "$adapter" ]] && codesign_now_playing_adapter "$adapter"
        codesign_app "$bundle"
    fi
    [[ -f "$executable" ]] && codesign --verify --strict "$executable"
    [[ -f "$helper" ]] && codesign --verify --strict "$helper"
    [[ -f "$adapter" ]] && codesign --verify --strict "$adapter"
    codesign --verify --deep --strict "$bundle"
}

sign_installed_bundle() {
    local bundle="$1"
    wait_for_install_metadata "$bundle"
    sign_bundle "$bundle"
}

sign_bundle "$STAGE"

process_is_running() {
    local proc="$1"
    if (( ${#proc} > 15 )); then
        pgrep -f "/Contents/MacOS/$proc" >/dev/null 2>&1
    else
        pgrep -x "$proc" >/dev/null 2>&1
    fi
}

stop_process() {
    local proc="$1"
    if (( ${#proc} > 15 )); then
        pkill -f "/Contents/MacOS/$proc" 2>/dev/null || true
    else
        pkill -x "$proc" 2>/dev/null || true
    fi
    for _ in {1..50}; do
        if ! process_is_running "$proc"; then
            return 0
        fi
        sleep 0.1
    done
    echo "✗ $proc is still running — quit it and retry" >&2
    return 1
}

wait_for_install_metadata() {
    local bundle="$1"
    local missing
    for _ in {1..50}; do
        missing=0
        while IFS= read -r file; do
            if ! xattr -p com.apple.provenance "$file" >/dev/null 2>&1; then
                missing=1
                break
            fi
        done < <(find "$bundle/Contents" -type f ! -path "*/_CodeSignature/*")
        if (( missing == 0 )); then
            return 0
        fi
        sleep 0.1
    done
}

# Installed development builds only need the copy in /Applications. Retaining
# another app in each checkout pollutes application search with stale builds.
if (( DEV )); then
    for old_bundle in "build/stage/$APP_NAME.app" "build/stage.noindex/$APP_NAME.app"; do
        if [[ -d "$old_bundle" ]]; then
            /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
                -u "$PWD/$old_bundle" >/dev/null 2>&1 || true
            rm -rf "$old_bundle"
        fi
    done
fi

if (( !DEV || !INSTALL )); then
    STAGE_DIRECTORY="build/stage"
    (( DEV )) && STAGE_DIRECTORY="build/stage.noindex"
    mkdir -p "$STAGE_DIRECTORY"
    BUILD_STAGE="$STAGE_DIRECTORY/$APP_NAME.app"
    rm -rf "$BUILD_STAGE"
    ditto --noextattr --noqtn "$STAGE" "$BUILD_STAGE"
    xattr -c -r "$BUILD_STAGE" 2>/dev/null || true
    if ! codesign --verify --deep --strict "$BUILD_STAGE" >/dev/null 2>&1; then
        if xattr -lr "$BUILD_STAGE" 2>/dev/null | grep -Eq 'com\.apple\.(FinderInfo|ResourceFork|provenance|fileprovider)'; then
            echo "  staging copy has local filesystem metadata; temp bundle was verified"
        else
            codesign --verify --deep --strict "$BUILD_STAGE"
        fi
    fi
    echo "✓ Bundle ready: $BUILD_STAGE"
fi

if (( INSTALL )); then
    echo "▸ Installing into /Applications…"
    stop_process "$EXECUTABLE"
    # Only an official install replaces the pre-rename official apps. The
    # Developer variant must coexist with them just as it does with Furoshiki.
    if (( ! DEV )); then
        for legacy in "Vorss:Vorss" "Furoshiki Utils:FuroshikiUtils"; do
            name="${legacy%%:*}"; proc="${legacy##*:}"
            if [[ -d "/Applications/$name.app" ]]; then
                stop_process "$proc"
                rm -rf "/Applications/$name.app"
                echo "  (legacy $name.app removed)"
            fi
        done
    fi
    INSTALL_DEST="/Applications/$APP_NAME.app"
    rm -rf "$INSTALL_DEST"
    ditto --noextattr --noqtn "$STAGE" "$INSTALL_DEST"
    sign_installed_bundle "$INSTALL_DEST"
    echo "✓ Installed: $INSTALL_DEST"
fi
