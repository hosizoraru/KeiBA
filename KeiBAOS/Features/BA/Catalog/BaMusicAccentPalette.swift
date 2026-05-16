//
//  BaMusicAccentPalette.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import SwiftUI

enum BaMusicAccentPalette {
    static let fallback = Color.accentColor

    private static let colors: [Color] = [
        .blue,
        .cyan,
        .teal,
        .green,
        .mint,
        .indigo,
        .purple,
        .pink,
        .orange,
    ]

    static func color(for track: BaMusicTrack?) -> Color {
        guard let track else { return fallback }
        return colors[stableIndex(for: "\(track.id)|\(track.title)")]
    }

    private static func stableIndex(for seed: String) -> Int {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for scalar in seed.unicodeScalars {
            hash ^= UInt64(scalar.value)
            hash &*= 1_099_511_628_211
        }
        return Int(hash % UInt64(colors.count))
    }
}

extension BaMusicTrack {
    var musicAccentColor: Color {
        BaMusicAccentPalette.color(for: self)
    }
}
