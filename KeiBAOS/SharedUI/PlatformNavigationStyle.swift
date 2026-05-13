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
        navigationBarTitleDisplayMode(.large)
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
}
