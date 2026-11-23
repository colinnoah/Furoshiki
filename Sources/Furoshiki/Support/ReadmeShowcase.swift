// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Furoshiki contributors

import AppKit
import SwiftUI

/// `Furoshiki --showcase <folder>` opens the real panel, Settings and setup
/// views one at a time, so `Tools/readme-screenshots.sh` can photograph them
/// for the README.
///
/// Each scene is announced in `<folder>/next.txt` as "<name> <window number>".
/// The script captures that window and deletes the file, and the next scene
/// follows; `<folder>/finished` marks the end. Preferences are overridden in
/// the volatile argument domain only, so nothing is written to disk, and the
/// app's services (event taps, permissions, the menu bar item) never start.
enum ReadmeShowcase {
    static func requestedFolder(in arguments: [String]) -> URL? {
        guard let index = arguments.firstIndex(of: "--showcase"),
              arguments.indices.contains(index + 1) else { return nil }
        return URL(fileURLWithPath: arguments[index + 1], isDirectory: true)
    }

    static func runAndExit(folder: URL) -> Never {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        override([DefaultsKey.language: AppLanguage.enUS.rawValue,
                  DefaultsKey.hasOnboarded: true])
        // Every feature this Mac can run, so each panel tab and list is full.
        let installable = AppFeature.allCases.filter { $0.installBlockedReason == nil }
        override(Dictionary(uniqueKeysWithValues: installable.map { ($0.availabilityKey, true as Any) }))
        // Kept on purpose, so Settings does not offer to uninstall the
        // features this fresh profile never switched on.
        override([DefaultsKey.featureHubKeptFeatures:
                    installable.map(\.rawValue).sorted().joined(separator: ",")])

        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        app.appearance = NSAppearance(named: .darkAqua)
        let runner = Runner(folder: folder, scenes: scenes)
        DispatchQueue.main.async {
            app.activate(ignoringOtherApps: true)
            runner.next()
        }
        app.run()
        exit(0)
    }

    /// Merges values into the argument domain, which outranks every other
    /// domain on read and is never saved.
    fileprivate static func override(_ values: [String: Any]) {
        var domain = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        domain.merge(values) { _, new in new }
        UserDefaults.standard.setVolatileDomain(domain, forName: UserDefaults.argumentDomain)
    }

    private static var scenes: [Scene] {
        [
            Scene(name: "panel-system") { panelWindow { MenuPanelFocus.shared.focus(PanelSectionID.system) } },
            Scene(name: "panel-utilities") { panelWindow { MenuPanelFocus.shared.focus(PanelSectionID.utilities) } },
            Scene(name: "panel-toggles") { panelWindow { MenuPanelFocus.shared.focus(PanelSectionID.toggles) } },
            Scene(name: "panel-features") { panelWindow { MenuPanelFocus.shared.showFeatureManager() } },
            Scene(name: "settings-features") { settingsWindow(.features) },
            Scene(name: "settings-switcher") { settingsWindow(.switcher) },
            Scene(name: "setup-features") { onboardingWindow(step: 1) },
            Scene(name: "setup-tour") { onboardingWindow(step: 3) },
        ]
    }

    // MARK: Windows

    /// The menu bar panel in a borderless window. The popover normally
    /// supplies the glass behind the panel; a visual effect view with the
    /// popover material stands in for it.
    private static func panelWindow(focus: () -> Void) -> NSWindow {
        MenuPanelFocus.shared.setPopoverVisible(true)
        focus()
        let host = NSHostingView(rootView: MenuPanelView())
        let backdrop = NSVisualEffectView()
        backdrop.material = .popover
        backdrop.blendingMode = .behindWindow
        backdrop.state = .active
        backdrop.maskImage = roundedMask(radius: 14)
        host.translatesAutoresizingMaskIntoConstraints = false
        backdrop.addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: backdrop.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: backdrop.trailingAnchor),
            host.topAnchor.constraint(equalTo: backdrop.topAnchor),
            host.bottomAnchor.constraint(equalTo: backdrop.bottomAnchor),
        ])
        let window = KeyableWindow(contentRect: NSRect(x: 0, y: 0, width: 332, height: 640),
                                   styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.contentView = backdrop
        window.isReleasedWhenClosed = false
        return window
    }

    private static func settingsWindow(_ page: SettingsPage) -> NSWindow {
        SettingsRouter.shared.request(FeatureSettingsDestination(page))
        let host = NSHostingController(rootView: SettingsView())
        host.sizingOptions = []
        let window = NSWindow(contentViewController: host)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.title = L10n.shared.s.settingsTitle
        window.setContentSize(NSSize(width: 960, height: 640))
        window.isReleasedWhenClosed = false
        return window
    }

    private static func onboardingWindow(step: Int) -> NSWindow {
        override([DefaultsKey.onboardingStep: step])
        let host = NSHostingController(rootView: OnboardingView(mode: .full) {})
        host.sizingOptions = .preferredContentSize
        let window = NSWindow(contentViewController: host)
        window.styleMask = [.titled, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        return window
    }

    private static func roundedMask(radius: CGFloat) -> NSImage {
        let size = NSSize(width: radius * 2 + 1, height: radius * 2 + 1)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }

    /// A borderless window cannot become key by default, and its switches
    /// then draw in the inactive gray instead of the accent color.
    private final class KeyableWindow: NSWindow {
        override var canBecomeKey: Bool { true }
        override var canBecomeMain: Bool { true }
    }

    // MARK: Runner

    private struct Scene {
        let name: String
        let makeWindow: () -> NSWindow
    }

    private final class Runner {
        let folder: URL
        var scenes: [Scene]
        var window: NSWindow?

        init(folder: URL, scenes: [Scene]) {
            self.folder = folder
            self.scenes = scenes
        }

        private var announcement: URL { folder.appendingPathComponent("next.txt") }

        func next() {
            window?.close()
            window = nil
            guard !scenes.isEmpty else {
                FileManager.default.createFile(atPath: folder.appendingPathComponent("finished").path,
                                               contents: Data())
                exit(0)
            }
            let scene = scenes.removeFirst()
            let window = scene.makeWindow()
            self.window = window
            fit(window)
            window.center()
            window.makeKeyAndOrderFront(nil)
            // Live readings, async images and measured scroll heights settle
            // first; the size is fitted again to what they measured.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self else { return }
                self.fit(window)
                window.center()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.announce(scene.name, window: window)
                }
            }
        }

        /// Borderless panel windows take the size their content asks for.
        private func fit(_ window: NSWindow) {
            guard window.styleMask == [.borderless], let content = window.contentView else { return }
            content.layoutSubtreeIfNeeded()
            let size = content.subviews.first?.fittingSize ?? content.fittingSize
            if size.width > 0, size.height > 0 { window.setContentSize(size) }
        }

        private func announce(_ name: String, window: NSWindow) {
            let pending = folder.appendingPathComponent("next.txt.pending")
            try? "\(name) \(window.windowNumber)\n".write(to: pending, atomically: true, encoding: .utf8)
            try? FileManager.default.moveItem(at: pending, to: announcement)
            waitForCapture(deadline: Date().addingTimeInterval(30))
        }

        /// The script deletes the announcement once the window is captured.
        private func waitForCapture(deadline: Date) {
            if !FileManager.default.fileExists(atPath: announcement.path) || Date() > deadline {
                next()
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.waitForCapture(deadline: deadline)
            }
        }
    }
}
