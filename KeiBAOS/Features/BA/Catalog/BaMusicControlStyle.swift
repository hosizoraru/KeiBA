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
            .baPressFeedback(isPressed: configuration.isPressed, scale: 0.94)
    }
}
