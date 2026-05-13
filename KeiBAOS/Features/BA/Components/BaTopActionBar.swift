//
//  BaTopActionBar.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaTopActionBar: View {
    let onPresentSheet: (BaPresentedSheet) -> Void

    var body: some View {
        Button {
            onPresentSheet(.notifications)
        } label: {
            Label(BaPresentedSheet.notifications.title, systemImage: BaPresentedSheet.notifications.systemImage)
        }
        .labelStyle(.iconOnly)
        .accessibilityLabel(Text(BaPresentedSheet.notifications.title))

        Menu {
            Button {
                onPresentSheet(.editOffice)
            } label: {
                Label(BaPresentedSheet.editOffice.menuTitle, systemImage: BaPresentedSheet.editOffice.systemImage)
            }

            Divider()

            Button {
                onPresentSheet(.debugTools)
            } label: {
                Label(BaPresentedSheet.debugTools.menuTitle, systemImage: BaPresentedSheet.debugTools.systemImage)
            }
        } label: {
            Label(String(localized: "ba.action.more.title"), systemImage: "ellipsis.circle")
        }
        .labelStyle(.iconOnly)
        .accessibilityLabel(Text(String(localized: "ba.action.more.title")))
    }
}
