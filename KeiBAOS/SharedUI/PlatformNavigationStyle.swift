//
//  PlatformNavigationStyle.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

extension View {
    @ViewBuilder
    func platformLargeNavigationTitle() -> some View {
        #if os(iOS)
            modifier(PlatformLargeNavigationTitleModifier())
        #else
            self
        #endif
    }

    @ViewBuilder
    func platformInlineNavigationTitle() -> some View {
        #if os(iOS)
            navigationBarTitleDisplayMode(.inline)
        #else
            self
        #endif
    }

    @ViewBuilder
    func platformInsetGroupedListStyle() -> some View {
        #if os(iOS)
            listStyle(.insetGrouped)
        #else
            listStyle(.inset)
        #endif
    }

    @ViewBuilder
    func platformAdaptiveTabViewStyle() -> some View {
        #if os(iOS)
            tabViewStyle(.sidebarAdaptable)
        #else
            self
        #endif
    }
}

#if os(iOS)
private struct PlatformLargeNavigationTitleModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        content.navigationBarTitleDisplayMode(horizontalSizeClass == .regular ? .inline : .large)
    }
}
#endif
