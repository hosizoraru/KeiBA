//
//  BaTopActionBar.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaTopActionBar: View {
    let onAction: (BaQuickAction) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(BaQuickAction.allCases) { action in
                LiquidGlassIconButton(
                    systemImage: action.systemImage,
                    accessibilityLabel: action.title,
                    tint: action.tint,
                    size: 36
                ) {
                    onAction(action)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}
