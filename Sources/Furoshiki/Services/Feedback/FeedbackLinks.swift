// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
// Modified for Furoshiki: feedback opens the repository's GitHub issue forms
// instead of posting to a feedback server.

import Foundation

/// The two kinds of feedback the app offers, each mapped to one of the
/// repository's issue forms in `.github/ISSUE_TEMPLATE`.
enum FeedbackKind: String, CaseIterable {
    case bug
    case feature

    var issueURL: URL {
        let template = self == .bug ? "bug_report.yml" : "feature_request.yml"
        var components = URLComponents(url: AppInfo.repositoryURL.appendingPathComponent("issues/new"),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "template", value: template)]
        return components.url!
    }
}
