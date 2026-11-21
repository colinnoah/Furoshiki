// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
// Modified for Furoshiki: one button in setup asks for every missing permission.

import AppKit
import AVFoundation
import Combine
import UserNotifications

/// Asks for every permission that is still missing, one at a time, so a
/// single button can cover them all without stacking system dialogs and
/// System Settings panes on top of each other.
///
/// The dialog-based permissions go first, each waiting for its answer. The
/// ones granted in System Settings follow: each waits until it is granted or
/// the person comes back to the app, so the next pane never covers the one
/// they are still working in. Full Disk Access comes last because it only
/// opens its pane. A permission macOS will not ask for again (denied before)
/// is skipped; its row keeps the button to open System Settings.
final class PermissionBatchRequest: ObservableObject {
    static let shared = PermissionBatchRequest()

    @Published private(set) var isRunning = false

    /// The order the flow asks in: dialogs first, System Settings last.
    static let order: [AppPermission] = [
        .notifications, .calendar, .camera, .microphone,
        .accessibility, .screenRecording, .fullDiskAccess,
    ]

    private var queue: [AppPermission] = []
    private var waiting: AnyCancellable?
    private var activation: NSObjectProtocol?
    private let pollingDemandID = UUID()

    private init() {}

    /// Whether the flow would ask for this permission right now.
    static func canRequest(_ permission: AppPermission,
                           in permissions: Permissions = .shared) -> Bool {
        switch permission {
        case .accessibility: return !permissions.accessibility
        case .screenRecording: return !permissions.screenRecording
        case .fullDiskAccess: return !permissions.fullDiskAccess
        case .notifications: return permissions.notifications == .undetermined
        case .calendar: return permissions.calendarAccess == .notDetermined
            || permissions.calendarAccess == .writeOnly
        case .camera: return permissions.camera == .undetermined
        case .microphone: return permissions.microphone == .undetermined
        case .filesAndFolders, .automationFinder, .automationPlayback, .audioCapture,
             .appManagement:
            return false
        }
    }

    static var hasRequestablePermissions: Bool {
        order.contains { canRequest($0) }
    }

    func start() {
        guard !isRunning else { return }
        Permissions.shared.refresh()
        queue = Self.order.filter { Self.canRequest($0) }
        guard !queue.isEmpty else { return }
        isRunning = true
        // Keeps the Accessibility and Screen Recording state fresh while the
        // flow waits on them, whatever the visible UI does meanwhile.
        Permissions.shared.setActivePermissionSurface(pollingDemandID, visible: true)
        next()
    }

    private func next() {
        stopWaiting()
        guard isRunning else { return }
        guard !queue.isEmpty else {
            finish()
            return
        }
        let permission = queue.removeFirst()
        // A dialog answered earlier in the flow may have settled this one.
        guard Self.canRequest(permission) else {
            next()
            return
        }
        request(permission)
    }

    private func request(_ permission: AppPermission) {
        let permissions = Permissions.shared
        switch permission {
        case .notifications:
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] _, _ in
                DispatchQueue.main.async {
                    Permissions.shared.refresh()
                    self?.next()
                }
            }
        case .calendar:
            permissions.requestCalendar()
            waiting = permissions.$requestingCalendar
                .dropFirst()
                .filter { !$0 }
                .first()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.next() }
        case .camera:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
                DispatchQueue.main.async {
                    Permissions.shared.refresh()
                    self?.next()
                }
            }
        case .microphone:
            permissions.requestMicrophone { [weak self] _ in self?.next() }
        case .accessibility:
            permissions.requestAccessibility()
            waitForSystemSettings(permissions.$accessibility)
        case .screenRecording:
            permissions.requestScreenRecording()
            waitForSystemSettings(permissions.$screenRecording)
        case .fullDiskAccess:
            permissions.requestFullDiskAccess()
            finish()
        case .filesAndFolders, .automationFinder, .automationPlayback, .audioCapture,
             .appManagement:
            next()
        }
    }

    /// Moves on once the permission is granted, or once the person returns to
    /// the app from System Settings without granting it.
    private func waitForSystemSettings(_ granted: Published<Bool>.Publisher) {
        waiting = granted
            .filter { $0 }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.next() }
        activation = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.next()
            }
    }

    private func stopWaiting() {
        waiting?.cancel()
        waiting = nil
        if let activation {
            NotificationCenter.default.removeObserver(activation)
            self.activation = nil
        }
    }

    private func finish() {
        stopWaiting()
        queue = []
        isRunning = false
        Permissions.shared.setActivePermissionSurface(pollingDemandID, visible: false)
    }
}
