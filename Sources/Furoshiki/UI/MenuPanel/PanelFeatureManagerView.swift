// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
// Modified for Furoshiki: every feature can be switched and set up from the panel.

import SwiftUI

/// The panel's feature manager: every feature, grouped like the Features hub,
/// with a switch to install or uninstall it and a gear that opens its own
/// settings. It shares the hub's runtime, so a change here shows in the hub,
/// the panel tabs and the menu bar at once.
struct PanelFeatureManagerView: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @State private var showsAll = false

    private var hub: FeatureHubStrings { FeatureStrings.hub(l10n.language) }
    private var text: TourStrings { FeatureStrings.tour(l10n.language) }

    /// The groups with something to show under the current filter, in the
    /// hub's order.
    private var groups: [PanelFeatureGroupEntry] {
        _ = features.revision
        return FeatureGroup.allCases.compactMap { group in
            let list = AppFeature.features(in: group).filter { showsAll || $0.isAvailable }
            return list.isEmpty ? nil : PanelFeatureGroupEntry(group: group, features: list)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker(hub.pageTitle, selection: $showsAll) {
                Text(text.managerInstalledTab).tag(false)
                Text(text.managerAllTab).tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .controlSize(.small)

            Text(text.managerIntro)
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if groups.isEmpty {
                Text(text.managerEmpty)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .panelCard()
            }

            ForEach(groups, id: \.group) { entry in
                VStack(alignment: .leading, spacing: 5) {
                    Text(groupTitle(entry.group).uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .kerning(0.5)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                    VStack(spacing: 0) {
                        ForEach(entry.features, id: \.self) { feature in
                            PanelFeatureManagerRow(feature: feature, hub: hub, text: text)
                            if feature != entry.features.last {
                                Divider().padding(.leading, 41)
                            }
                        }
                    }
                    .panelCard(padded: false)
                }
            }

            Button {
                SettingsRouter.shared.request(FeatureSettingsDestination(.features))
                appDelegate()?.openSettingsWindow()
            } label: {
                Label(text.managerOpenHub, systemImage: "square.grid.2x2")
                    .font(.system(size: 11.5, weight: .medium))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
        .animation(.easeOut(duration: 0.2), value: showsAll)
    }

    private func groupTitle(_ group: FeatureGroup) -> String {
        switch group {
        case .windowsDock: return hub.groupWindowsDock
        case .mouseKeyboard: return hub.groupMouseKeyboard
        case .clipboardFiles: return hub.groupClipboardFiles
        case .sound: return hub.groupSound
        case .energyDisplay: return hub.groupEnergyDisplay
        case .tools: return hub.groupTools
        case .dynamicIsland: return FeatureStrings.notch(l10n.language).title
        case .monitor: return hub.groupMonitor
        }
    }
}

private struct PanelFeatureGroupEntry {
    let group: FeatureGroup
    let features: [AppFeature]
}

private struct PanelFeatureManagerRow: View {
    @ObservedObject private var l10n = L10n.shared
    @State private var hovering = false
    let feature: AppFeature
    let hub: FeatureHubStrings
    let text: TourStrings

    private var title: String { feature.hubTitle(l10n.s, hub: hub) }
    private var installed: Bool { feature.isAvailable }
    /// Only a feature this Mac cannot run and that is not installed yet is
    /// locked, the same rule as the hub row.
    private var blockedReason: String? { installed ? nil : feature.installBlockedReason }

    private var installation: Binding<Bool> {
        Binding(
            get: { feature.isAvailable },
            set: { install in
                withAnimation(.easeOut(duration: 0.22)) {
                    FeatureRuntime.shared.setAvailable([feature], install)
                }
            })
    }

    var body: some View {
        HStack(spacing: PanelRowMetrics.iconSpacing) {
            Image(systemName: feature.symbolName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(installed ? Color.accentColor : Color.secondary)
                .frame(width: PanelRowMetrics.iconWidth)
                .accessibilityHidden(true)

            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(installed ? Color.primary : Color.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                if feature.isBeta {
                    PanelBetaBadge(text: l10n.s.betaBadge)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if installed && feature.hasNavigableSettingsDestination {
                Button {
                    SettingsRouter.shared.request(feature.settingsDestination, sidebarFeature: feature)
                    appDelegate()?.openSettingsWindow()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11.5, weight: .medium))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(hovering ? Color.primary : Color.secondary)
                .help(text.managerSettingsHelp)
                .accessibilityLabel("\(text.managerSettingsHelp), \(title)")
            }

            Toggle(title, isOn: installation)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
                .disabled(blockedReason != nil)
                .accessibilityLabel(title)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .help(blockedReason ?? feature.hubDescription(hub))
    }
}
