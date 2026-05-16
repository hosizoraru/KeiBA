//
//  BaMusicControlStyle.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import SwiftUI

struct BaMusicControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.smooth(duration: 0.16), value: configuration.isPressed)
    }
}
