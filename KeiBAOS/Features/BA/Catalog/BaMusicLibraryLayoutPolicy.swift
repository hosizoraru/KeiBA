//
//  BaMusicLibraryLayoutPolicy.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import Foundation

nonisolated enum BaMusicLibraryPlatform: Equatable, Sendable {
    case touch
    case desktop

    static var current: BaMusicLibraryPlatform {
        #if os(macOS)
            .desktop
        #else
            .touch
        #endif
    }
}

nonisolated enum BaMusicLibraryLayoutStyle: Equatable, Sendable {
    case stacked
    case split
}

nonisolated enum BaMusicLibraryNavigationChrome: Equatable, Sendable {
    case sidebar
    case topBar
    case other
}

nonisolated enum BaMusicNowPlayingHeroLayout: Equatable, Sendable {
    case automatic
    case stacked
    case sideBySide
}

nonisolated enum BaMusicLibraryLayoutPolicy {
    static func layoutStyle(
        for metrics: BaAdaptiveMetrics,
        platform: BaMusicLibraryPlatform = .current,
        navigationChrome: BaMusicLibraryNavigationChrome = .other
    ) -> BaMusicLibraryLayoutStyle {
        switch platform {
        case .touch:
            guard navigationChrome == .topBar else { return .stacked }
            return metrics.containerWidth >= 980 ? .split : .stacked
        case .desktop:
            return metrics.containerWidth >= 760 ? .split : .stacked
        }
    }

    static func contentMaxWidth(
        for metrics: BaAdaptiveMetrics,
        platform: BaMusicLibraryPlatform = .current,
        navigationChrome: BaMusicLibraryNavigationChrome = .other
    ) -> CGFloat? {
        switch layoutStyle(for: metrics, platform: platform, navigationChrome: navigationChrome) {
        case .split:
            return 1_180
        case .stacked:
            switch metrics.widthClass {
            case .compact:
                return nil
            case .regular:
                return 820
            case .expanded:
                return platform == .desktop ? 960 : 900
            }
        }
    }

    static func heroColumnWidth(for metrics: BaAdaptiveMetrics) -> CGFloat {
        min(max(metrics.containerWidth * 0.34, 336), 430)
    }

    static func automaticHeroLayout(
        for metrics: BaAdaptiveMetrics,
        presentation: BaMusicNowPlayingPresentation
    ) -> BaMusicNowPlayingHeroLayout {
        switch presentation {
        case .inline:
            return .stacked
        case .full:
            return metrics.containerWidth >= 760 ? .sideBySide : .stacked
        }
    }
}
