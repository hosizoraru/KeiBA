//
//  AppBackground.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct AppBackground: View {
    var body: some View {
        ZStack {
            baseColor
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.035),
                    Color.clear,
                    Color.cyan.opacity(0.025)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    private var baseColor: Color {
#if os(macOS)
        Color(nsColor: .windowBackgroundColor)
#elseif os(visionOS)
        Color.clear
#else
        Color(uiColor: .systemGroupedBackground)
#endif
    }
}
