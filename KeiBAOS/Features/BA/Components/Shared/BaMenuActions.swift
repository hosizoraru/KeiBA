//
//  BaMenuActions.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import SwiftUI

// Stored only to defer Menu mutations until dismissal finishes; execution remains on MainActor.
struct BaDelayedMenuAction: @unchecked Sendable {
    private let run: @MainActor () -> Void

    init(_ run: @escaping @MainActor () -> Void) {
        self.run = run
    }

    @MainActor
    func callAsFunction() {
        run()
    }
}

@MainActor
enum BaMenuActionDispatcher {
    static func perform(_ action: @escaping @MainActor () -> Void) {
        perform(BaDelayedMenuAction(action))
    }

    static func perform(_ action: BaDelayedMenuAction) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            action()
        }
    }
}

struct BaMenuActionButton: View {
    let title: String
    let systemImage: String
    let action: BaDelayedMenuAction

    init(
        title: String,
        systemImage: String,
        action: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = BaDelayedMenuAction(action)
    }

    var body: some View {
        Button {
            BaMenuActionDispatcher.perform(action)
        } label: {
            Label(title, systemImage: systemImage)
        }
    }
}

struct BaMenuToggleButton: View {
    let title: String
    let isOn: Bool
    let action: BaDelayedMenuAction

    init(
        title: String,
        isOn: Bool,
        action: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.isOn = isOn
        self.action = BaDelayedMenuAction(action)
    }

    var body: some View {
        Button {
            BaMenuActionDispatcher.perform(action)
        } label: {
            Label(title, systemImage: isOn ? "checkmark" : "circle")
        }
    }
}
