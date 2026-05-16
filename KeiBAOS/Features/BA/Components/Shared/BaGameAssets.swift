//
//  BaGameAssets.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import SwiftUI

nonisolated enum BaGameAsset: String, Codable, Hashable {
    case schale = "BASchale"
    case actionPoint = "BAAP"
    case actionPointTight = "BAAPTight"
    case cafeAP = "BACafeAP"
    case cafeCoupon = "BACafeCoupon"
    case arenaCoin = "BAArenaCoin"
    case lobbyWork = "BALobbyWork"
    case dailyReward = "BADailyReward"
    case guideMission = "BAGuideMission"
    case guideMissionAlt = "BAGuideMissionAlt"
    case tabProfile = "BATabProfile"
    case tabSkill = "BATabSkill"
    case tabBGM = "BATabBGM"
    case tabPlay = "BATabPlay"
    case tabSimulate = "BATabSimulate"
    case weaponStarBadge = "BAWeaponStarBadge"
}

struct BaGameAssetIcon: View {
    let asset: BaGameAsset
    var size: CGFloat
    var renderingMode: Image.TemplateRenderingMode?
    var tint: Color?

    init(
        _ asset: BaGameAsset,
        size: CGFloat,
        renderingMode: Image.TemplateRenderingMode? = .original,
        tint: Color? = nil
    ) {
        self.asset = asset
        self.size = size
        self.renderingMode = renderingMode
        self.tint = tint
    }

    var body: some View {
        let image = Image(asset.rawValue)
            .renderingMode(renderingMode)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)

        if let tint {
            image.foregroundStyle(tint)
        } else {
            image
        }
    }
}
