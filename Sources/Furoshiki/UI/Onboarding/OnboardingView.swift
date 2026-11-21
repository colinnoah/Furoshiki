// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// First-run experience, also reachable later through Settings › About.
/// The person chooses what they want first; only then does the app explain and
/// request the permissions that choice actually needs.
enum OnboardingMode {
    case full

    func title(_ strings: Strings) -> String {
        strings.obStepWelcomeTitle
    }
}

enum OnboardingStep {
    case welcome, purpose, permissions, tour, done
}

struct OnboardingView: View {
    var mode: OnboardingMode = .full
    var onFinish: () -> Void

    @ObservedObject private var l10n = L10n.shared
    /// Persisted so the flow resumes where it stopped — macOS relaunches the
    /// app when Screen Recording is granted mid-onboarding.
    @AppStorage(DefaultsKey.onboardingStep) private var index = 0
    @State private var selectedFeatures: Set<AppFeature>
    /// The page inside the tour step. Continue and Back walk through it
    /// before they leave the step, so the tour is clicked through like the
    /// rest of the setup.
    @State private var tourPage = 0

    init(mode: OnboardingMode = .full, onFinish: @escaping () -> Void) {
        self.mode = mode
        self.onFinish = onFinish
        // Startup has already installed the first-run preset and any features
        // declared in the settings file. Show the selection Continue will save.
        let features = Set(AppFeature.allCases.filter(\.isAvailable))
        _selectedFeatures = State(initialValue: features)
    }

    private var setupPermissions: [AppPermission] {
        let permissions = Set(selectedFeatures.flatMap(\.onboardingPermissions))
        return [.accessibility, .screenRecording].filter { permissions.contains($0) }
    }
    private var steps: [OnboardingStep] {
        [.welcome, .purpose, .permissions, .tour, .done]
    }
    private var current: OnboardingStep { steps[min(max(0, index), steps.count - 1)] }

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable so a step taller than the window (the menu bar
            // metrics list outgrew it, issue #176) can never push the
            // navigation bar out of the fixed frame — without a scroll, the
            // footer was clipped away and the flow looked stuck.
            ScrollView {
                content
                    .frame(maxWidth: .infinity, alignment: .top)
            }

            Divider()
            navigationBar
        }
        .frame(width: 540, height: 600)
        .onAppear {
            if !steps.indices.contains(index) { index = 0 }
            // Onboarding narrates the permission trip itself; the floating
            // guide card would just double the voice.
            PermissionGuideOverlay.suppressed = true
        }
        .onDisappear {
            PermissionGuideOverlay.suppressed = false
        }
    }

    @ViewBuilder
    private var content: some View {
        switch current {
        case .welcome: WelcomeStep()
        case .purpose: PurposeStep(selectedFeatures: $selectedFeatures)
        case .permissions: SelectedPermissionsStep(features: selectedFeatures,
                                                   permissions: setupPermissions)
        case .tour: TourStep(page: $tourPage) {
            withAnimation(.easeInOut(duration: 0.2)) { index += 1 }
        }
        case .done: DoneStep()
        }
    }

    private var navigationBar: some View {
        HStack {
            Button(l10n.s.obBack) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if current == .tour && tourPage > 0 {
                        tourPage -= 1
                    } else {
                        index = max(0, index - 1)
                        if current == .tour { tourPage = TourStep.pageCount - 1 }
                    }
                }
            }
            .disabled(index == 0)

            Spacer()

            HStack(spacing: 6) {
                ForEach(steps.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == index ? Color.accentColor : Color.primary.opacity(0.15))
                        .frame(width: i == index ? 18 : 7, height: 7)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: index)
                }
            }

            Spacer()

            Button(primaryButtonTitle) {
                if index >= steps.count - 1 {
                    index = 0
                    onFinish()
                } else if current == .tour && tourPage < TourStep.pageCount - 1 {
                    withAnimation(.easeInOut(duration: 0.25)) { tourPage += 1 }
                } else {
                    if current == .purpose {
                        FeatureRuntime.shared.replaceAvailable(
                            with: selectedFeatures,
                            enabling: FeaturePreset.allCases
                                .filter { $0.installableFeatures.isSubset(of: selectedFeatures) }
                                .flatMap(\.enableKeys))
                    }
                    withAnimation(.easeInOut(duration: 0.2)) { index += 1 }
                    if current == .tour { tourPage = 0 }
                }
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var primaryButtonTitle: String {
        if index >= steps.count - 1 { return l10n.s.obStart }
        return l10n.s.obContinue
    }
}

// MARK: - Step 1: welcome & language

private struct WelcomeStep: View {
    @ObservedObject private var l10n = L10n.shared

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Theme.spaceGradient
                VStack(spacing: 10) {
                    BrandMark(width: 130)
                    Text(AppInfo.name)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                    Text(l10n.s.obStepWelcomeBody)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 12)
            }
            .frame(height: 220)

            VStack(alignment: .leading, spacing: 16) {
                Picker(l10n.s.obLanguageLabel, selection: $l10n.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                // A menu (not segmented): with nine languages a segmented control
                // would overflow, and several names are in their own script.
                .pickerStyle(.menu)

                featureRow(icon: "bolt.fill",
                           title: l10n.s.obWelcomeBullet1Title,
                           text: l10n.s.obWelcomeBullet1Body)
                featureRow(icon: "gauge.with.dots.needle.50percent",
                           title: l10n.s.obWelcomeBullet2Title,
                           text: l10n.s.obWelcomeBullet2Body)
                featureRow(icon: "rectangle.on.rectangle",
                           title: l10n.s.obWelcomeBullet3Title,
                           text: l10n.s.obWelcomeBullet3Body)
            }
            .padding(24)
        }
    }

    private func featureRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.spaceGradient)
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(text)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Purpose step

/// Presets are quick starts that add to the selection instead of replacing
/// it: a preset reads as ticked while all of its features are selected,
/// ticking it adds them and unticking removes only its own. Features picked
/// by hand or by another preset stay, so the person can combine bundles and
/// switch between everything they installed. The catalog below allows an
/// exact choice, and its header can select every installable feature at
/// once. Both use the Features hub's own names and descriptions so setup
/// stays consistent with what the person can change later.
private struct PurposeStep: View {
    @ObservedObject private var l10n = L10n.shared
    @Binding var selectedFeatures: Set<AppFeature>

    private var hub: FeatureHubStrings { FeatureStrings.hub(l10n.language) }

    var body: some View {
        VStack(spacing: 16) {
            StepHeader(icon: "sparkles.rectangle.stack",
                       title: l10n.s.obPurposeTitle,
                       subtitle: l10n.s.obPurposeBody)

            VStack(spacing: 8) {
                ForEach(FeaturePreset.allCases) { preset in
                    bundleCard(preset)
                }
            }
            .padding(.horizontal, 28)

            HStack {
                Text(hub.tabFeatures.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                Spacer()
                Text(String(format: hub.activeCountFormat,
                            selectedFeatures.count, FeatureRuntime.shared.installableCount))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                selectAllButton
            }
            .padding(.horizontal, 28)

            // Eager, like the Features hub (#2311, #2642): a lazy stack nested
            // here re-estimated the cards below the fold on every scroll step
            // and re-anchored the viewport until the app hung.
            VStack(spacing: 14) {
                ForEach(FeatureGroup.allCases, id: \.self) { group in
                    VStack(alignment: .leading, spacing: 7) {
                        Text(groupTitle(group))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(AppFeature.features(in: group), id: \.self) { feature in
                            featureCard(feature)
                        }
                    }
                }
            }
            .padding(.horizontal, 28)

            Text(l10n.s.obPurposeSkip)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.bottom, 12)

            Spacer()
        }
    }

    private func name(_ preset: FeaturePreset) -> String {
        switch preset {
        case .essential: return hub.presetEssentialName
        case .windows: return hub.presetWindowsName
        case .battery: return hub.presetBatteryName
        }
    }

    private func caption(_ preset: FeaturePreset) -> String {
        switch preset {
        case .essential: return hub.presetEssentialDesc
        case .windows: return hub.presetWindowsDesc
        case .battery: return hub.presetBatteryDesc
        }
    }

    /// Every feature this Mac can install, the same gate the catalog rows use.
    private var installableFeatures: Set<AppFeature> {
        Set(AppFeature.allCases.filter { $0.installBlockedReason == nil })
    }

    private var allSelected: Bool {
        installableFeatures.isSubset(of: selectedFeatures)
    }

    /// Selects every installable feature, or clears the selection once all
    /// of them are chosen, with the hub's own install-all wording.
    private var selectAllButton: some View {
        Button(allSelected ? hub.uninstallAllButton : hub.installAllButton) {
            selectedFeatures = allSelected ? [] : installableFeatures
        }
        .buttonStyle(.borderless)
        .font(.caption.weight(.semibold))
    }

    private func bundleCard(_ preset: FeaturePreset) -> some View {
        let selected = preset.installableFeatures.isSubset(of: selectedFeatures)
        return Button {
            if selected {
                selectedFeatures.subtract(preset.features)
            } else {
                selectedFeatures.formUnion(preset.installableFeatures)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: preset.symbolName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 26)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name(preset))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(caption(preset))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary.opacity(0.45))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.05))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(selected ? Color.accentColor.opacity(0.45) : .clear,
                                  lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(name(preset)). \(caption(preset))")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .animation(.easeOut(duration: 0.15), value: selected)
    }

    private func featureCard(_ feature: AppFeature) -> some View {
        let selected = selectedFeatures.contains(feature)
        // The picker writes availability through the same runtime gate as the
        // hub, so a feature this Mac cannot run would silently stay off after
        // being ticked here. It is shown and refused instead, exactly as the
        // hub row does it.
        let blocked = feature.installBlockedReason
        let card = Button {
            if selected {
                selectedFeatures.remove(feature)
                if feature == .notch {
                    selectedFeatures.subtract(AppFeature.dynamicIslandExtensions)
                }
            } else {
                selectedFeatures.formUnion(feature.initialInstallGroup)
            }
        } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selected
                          ? AnyShapeStyle(Theme.spaceGradient)
                          : AnyShapeStyle(Color.secondary.opacity(0.16)))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: feature.symbolName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(selected ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                            .accessibilityHidden(true)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(feature.hubTitle(l10n.s, hub: hub))
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(feature.hubDescription(hub))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary.opacity(0.45))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selected ? Color.accentColor.opacity(0.09) : Color.primary.opacity(0.035))
            )
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(blocked != nil)
        .opacity(blocked == nil ? 1 : 0.4)
        .saturation(blocked == nil ? 1 : 0)
        .accessibilityLabel("\(feature.hubTitle(l10n.s, hub: hub)). \(feature.hubDescription(hub))"
                            + (blocked.map { ". \($0)" } ?? ""))
        .accessibilityAddTraits(selected ? .isSelected : [])
        // .help() never fires on a disabled control, so the tooltip sits on a
        // wrapper outside it, the same way the Features hub row does it.
        return HStack(spacing: 0) { card }.help(blocked ?? "")
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

private struct SelectedPermissionsStep: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var permissionState = Permissions.shared
    @ObservedObject private var batchRequest = PermissionBatchRequest.shared
    @State private var showingOtherPermissions = false
    let features: Set<AppFeature>
    let permissions: [AppPermission]

    private var hub: FeatureHubStrings { FeatureStrings.hub(l10n.language) }
    private var otherPermissions: [AppPermission] {
        AppPermission.allCases.filter { !permissions.contains($0) }
    }

    var body: some View {
        VStack(spacing: 18) {
            StepHeader(icon: "key.horizontal.fill",
                       title: hub.tabPermissions,
                       subtitle: hub.permissionsIntro)

            // One button for everything still missing. The flow asks one
            // permission at a time, so dialogs and System Settings panes
            // never stack up.
            if batchRequest.isRunning || PermissionBatchRequest.hasRequestablePermissions {
                Button {
                    PermissionBatchRequest.shared.start()
                } label: {
                    HStack(spacing: 8) {
                        if batchRequest.isRunning {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "checkmark.shield")
                        }
                        Text(hub.requestAllButton)
                    }
                    .frame(minWidth: 180)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(batchRequest.isRunning)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(hub.onboardingSelectedPermissionsTitle)
                    .font(.headline)

                if permissions.isEmpty {
                    Label(hub.onboardingNoSelectedPermissions,
                          systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(permissions.enumerated()), id: \.offset) { index, permission in
                            if index > 0 { Divider().padding(.vertical, 12) }
                            VStack(alignment: .leading, spacing: 8) {
                                PermissionRow(kind: permission == .accessibility
                                              ? .accessibility : .screenRecording)
                                Text(permission.explainer(hub))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(String(format: hub.usedByFormat,
                                            featureNames(for: permission)))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
            .padding(.horizontal, 28)

            DisclosureGroup(isExpanded: $showingOtherPermissions) {
                VStack(alignment: .leading, spacing: 14) {
                    PermissionsPortalSections(hub: hub,
                                              visiblePermissions: otherPermissions)
                }
                .padding(.top, 12)
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(hub.onboardingOtherPermissionsTitle)
                        .font(.headline)
                    Text(hub.onboardingOtherPermissionsCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
            .padding(.horizontal, 28)

            Text(l10n.s.permissionRestartNote)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Spacer()
        }
    }

    private func featureNames(for permission: AppPermission) -> String {
        features
            .filter { $0.onboardingPermissions.contains(permission) }
            .map { $0.hubTitle(l10n.s, hub: hub) }
            // Localized: a plain sort orders by Unicode scalar, which throws
            // every accented name past Z. On the first screen someone sees,
            // in a language with accents, that reads as a list in no order.
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .joined(separator: ", ")
    }
}

// MARK: - Done

private struct DoneStep: View {
    @ObservedObject private var l10n = L10n.shared

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Theme.spaceGradient
                VStack(spacing: 14) {
                    BrandMark(width: 150)
                    Text(l10n.s.obStepDoneTitle)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                    Text(l10n.s.obStepDoneBody)
                        .font(.system(size: 12.5))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(height: 300)

            VStack(spacing: 10) {
                Image(systemName: "menubar.arrow.up.rectangle")
                    .font(.system(size: 26))
                    .foregroundStyle(.secondary)
                Text(l10n.s.obDoneHint)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
            }
            .padding(.top, 36)

            Spacer()
        }
    }
}

// MARK: - Step 4: tour

/// A short click-through of where things live: the menu bar icon, the panel
/// tabs, the feature manager and Settings. Each page draws a small sketch of
/// the real control with the part to look at outlined.
struct TourStep: View {
    static let pageCount = 4

    @Binding var page: Int
    var onSkip: () -> Void
    @ObservedObject private var l10n = L10n.shared

    private var text: TourStrings { FeatureStrings.tour(l10n.language) }

    private var pageTitle: String {
        switch page {
        case 0: return text.tourMenuBarTitle
        case 1: return text.tourTabsTitle
        case 2: return text.tourFeaturesTitle
        default: return text.tourSettingsTitle
        }
    }

    private var pageBody: String {
        switch page {
        case 0: return text.tourMenuBarBody
        case 1: return text.tourTabsBody
        case 2: return text.tourFeaturesBody
        default: return text.tourSettingsBody
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            StepHeader(icon: "map.fill", title: text.tourTitle, subtitle: text.tourSubtitle)

            TourIllustration(page: page)
                .frame(width: 420, height: 196)
                .id(page)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(String(format: text.tourStepFormat, page + 1, Self.pageCount))
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text(pageTitle)
                    .font(.system(size: 15, weight: .bold))
                Text(pageBody)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 48, alignment: .top)
            }
            .padding(.horizontal, 56)
            .accessibilityElement(children: .combine)

            HStack(spacing: 8) {
                ForEach(0..<Self.pageCount, id: \.self) { index in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { page = index }
                    } label: {
                        Circle()
                            .fill(index == page ? Color.accentColor : Color.primary.opacity(0.18))
                            .frame(width: 8, height: 8)
                            .padding(4)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(format: text.tourStepFormat, index + 1, Self.pageCount))
                }
            }

            Button(text.tourSkip, action: onSkip)
                .buttonStyle(.link)
                .font(.system(size: 11.5))
        }
        .padding(.bottom, 16)
    }
}

/// The sketch for one tour page. Only shapes and the app's own symbols, so it
/// follows the language, the appearance and the accent color.
private struct TourIllustration: View {
    let page: Int
    @ObservedObject private var l10n = L10n.shared

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.spaceGradient)
            switch page {
            case 0: menuBarSketch
            case 1: panelSketch(highlight: .tabs)
            case 2: panelSketch(highlight: .features)
            default: panelSketch(highlight: .settings)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Menu bar

    private var menuBarSketch: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 11, weight: .semibold))
                Capsule().frame(width: 34, height: 5).opacity(0.35)
                Capsule().frame(width: 26, height: 5).opacity(0.35)
                Spacer()
                Image(systemName: "wifi").font(.system(size: 10.5))
                Image(systemName: "battery.75").font(.system(size: 11))
                BrandMark(width: 24, tint: .white)
                    .frame(width: 26, height: 16)
                    .tourHighlight(cornerRadius: 6)
                Text(Date(), format: .dateTime.hour().minute()).font(.system(size: 10.5, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 26)
            .background(Color.black.opacity(0.35))

            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Image(systemName: "cursorarrow.click.2")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .padding(.trailing, 62)
                        .padding(.top, 2)
                    miniPanel(highlight: nil)
                        .frame(width: 150, height: 120)
                        .padding(.trailing, 40)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Panel

    private enum Highlight { case tabs, features, settings }

    private func panelSketch(highlight: Highlight) -> some View {
        HStack(spacing: 18) {
            miniPanel(highlight: highlight)
                .frame(width: 190, height: 168)
            if highlight == .settings {
                settingsWindowSketch
                    .frame(width: 168, height: 128)
            }
        }
    }

    private var tabSymbols: [String] {
        Array(PanelSectionID.allCases.prefix(7).map(\.symbolName))
    }

    private func miniPanel(highlight: Highlight?) -> some View {
        let s = l10n.s
        let hub = FeatureStrings.hub(l10n.language)
        let compact = highlight == nil
        return VStack(spacing: compact ? 5 : 7) {
            BrandMark(width: compact ? 18 : 24, tint: .white)
                .frame(height: compact ? 10 : 14)
            HStack(spacing: 0) {
                ForEach(Array(tabSymbols.enumerated()), id: \.offset) { index, symbol in
                    Image(systemName: symbol)
                        .font(.system(size: compact ? 6.5 : 8.5, weight: .semibold))
                        .foregroundStyle(index == 0 ? Color.accentColor : Color.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: compact ? 13 : 18)
            .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Color.white.opacity(0.08)))
            .tourHighlight(cornerRadius: 6, active: highlight == .tabs)

            VStack(spacing: compact ? 4 : 6) {
                ForEach(0..<(compact ? 3 : 4), id: \.self) { row in
                    HStack(spacing: 5) {
                        Circle().fill(Color.accentColor.opacity(0.8))
                            .frame(width: compact ? 5 : 7, height: compact ? 5 : 7)
                        Capsule().fill(Color.white.opacity(0.35))
                            .frame(width: CGFloat([58, 44, 66, 50][row]) * (compact ? 0.7 : 1), height: compact ? 3 : 4)
                        Spacer(minLength: 0)
                        if highlight == .features {
                            Image(systemName: "gearshape")
                                .font(.system(size: 7))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        Capsule()
                            .fill(row == 2 ? Color.white.opacity(0.25) : Color.accentColor)
                            .frame(width: compact ? 11 : 15, height: compact ? 6 : 8)
                            .overlay(alignment: row == 2 ? .leading : .trailing) {
                                Circle().fill(.white)
                                    .frame(width: compact ? 4.5 : 6, height: compact ? 4.5 : 6)
                                    .padding(1)
                            }
                    }
                }
            }
            .padding(compact ? 5 : 7)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white.opacity(0.06)))

            if !compact {
                HStack(spacing: 4) {
                    footerChip(s.panelSettings, symbol: "gearshape", active: highlight == .settings)
                    footerChip(hub.pageTitle, symbol: "square.grid.2x2", active: highlight == .features)
                    footerChip(s.panelQuit, symbol: "power", active: false)
                }
            }
        }
        .padding(compact ? 7 : 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.7)
        )
    }

    private func footerChip(_ title: String, symbol: String, active: Bool) -> some View {
        HStack(spacing: 2) {
            Image(systemName: symbol)
            Text(title).lineLimit(1).minimumScaleFactor(0.6)
        }
        .font(.system(size: 7, weight: .medium))
        .foregroundStyle(active ? Color.white : Color.white.opacity(0.7))
        .frame(maxWidth: .infinity)
        .frame(height: 15)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(active ? Color.accentColor.opacity(0.55) : Color.white.opacity(0.08))
        )
        .tourHighlight(cornerRadius: 5, active: active)
    }

    private var settingsWindowSketch: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 3) {
                    ForEach([Color.red, .yellow, .green], id: \.self) { color in
                        Circle().fill(color.opacity(0.85)).frame(width: 5, height: 5)
                    }
                }
                .padding(.bottom, 4)
                ForEach(0..<6, id: \.self) { row in
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(row == 1 ? Color.accentColor : Color.white.opacity(0.4))
                            .frame(width: 7, height: 7)
                        Capsule().fill(Color.white.opacity(row == 1 ? 0.7 : 0.3))
                            .frame(width: CGFloat([30, 36, 26, 32, 28, 34][row]), height: 3.5)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(width: 62, alignment: .leading)
            .frame(maxHeight: .infinity)
            .background(Color.white.opacity(0.06))

            VStack(alignment: .leading, spacing: 7) {
                Capsule().fill(Color.white.opacity(0.7)).frame(width: 52, height: 5)
                ForEach(0..<4, id: \.self) { row in
                    HStack {
                        Capsule().fill(Color.white.opacity(0.3))
                            .frame(width: CGFloat([46, 38, 52, 34][row]), height: 3.5)
                        Spacer(minLength: 0)
                        Capsule().fill(row == 3 ? Color.white.opacity(0.25) : Color.accentColor)
                            .frame(width: 13, height: 7)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(10)
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.7)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct TourHighlight: ViewModifier {
    let cornerRadius: CGFloat
    let active: Bool
    @State private var pulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay {
            if active {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white, lineWidth: 1.6)
                    .padding(-3)
                    .shadow(color: Color.accentColor.opacity(0.9), radius: pulsing ? 6 : 2)
                    .scaleEffect(pulsing && !reduceMotion ? 1.06 : 1)
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                            pulsing = true
                        }
                    }
            }
        }
    }
}

private extension View {
    func tourHighlight(cornerRadius: CGFloat, active: Bool = true) -> some View {
        modifier(TourHighlight(cornerRadius: cornerRadius, active: active))
    }
}

// MARK: - Shared header

private struct StepHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.spaceGradient)
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text(title)
                .font(.system(size: 19, weight: .bold))
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 48)
        }
        .padding(.top, 30)
    }
}

private extension FeaturePreset {
    /// The preset's features this Mac can install, through the same gate as
    /// the catalog rows, so a bundle with an unsupported feature can still
    /// read as fully picked.
    var installableFeatures: Set<AppFeature> {
        features.filter { $0.installBlockedReason == nil }
    }
}
