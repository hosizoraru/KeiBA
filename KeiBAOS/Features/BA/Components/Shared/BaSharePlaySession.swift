//
//  BaSharePlaySession.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/29.
//

import GroupActivities
import SwiftUI

struct BaSharePlayMediaSession: GroupActivity {
    static var activityIdentifier: String = "os.kei.KeiBAOS.shareplay-media"

    var title: String
    var mediaURL: URL
    var mediaKind: String

    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.type = .generic
        metadata.title = title
        return metadata
    }
}

struct BaSharePlayButton: View {
    let title: String
    let mediaURL: URL?
    let mediaKind: BaGuideMediaKind

    @State private var isSessionActive = false
    @State private var participantCount = 0

    var body: some View {
        if isSessionActive {
            Menu {
                Label("\(participantCount) participant\(participantCount == 1 ? "" : "s")", systemImage: "person.2.fill")
                Divider()
                Button("Leave") { isSessionActive = false }
            } label: {
                Label(BaL10n.string("ba.action.shareplay"), systemImage: "shareplay")
                    .foregroundStyle(.green)
            }
        } else {
            Button {
                Task { await startSharePlay() }
            } label: {
                Label(BaL10n.string("ba.action.shareplay"), systemImage: "shareplay")
            }
            .disabled(mediaURL == nil)
        }
    }

    private func startSharePlay() async {
        guard let mediaURL else { return }
        // SharePlay session requires FaceTime and GroupActivities entitlement.
        // Full implementation needs Xcode project configuration.
        isSessionActive = true
    }
}
