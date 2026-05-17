//
//  BaAppIconController.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

#if os(iOS)
    import UIKit
#endif

enum BaAppIconController {
    @MainActor
    static func apply(_ choice: BaAppIconChoice) async -> Bool {
        #if os(iOS)
            let application = UIApplication.shared
            guard application.supportsAlternateIcons else {
                return false
            }

            let iconName = choice.alternateIconName
            guard application.alternateIconName != iconName else {
                return true
            }

            return await withCheckedContinuation { continuation in
                application.setAlternateIconName(iconName) { error in
                    continuation.resume(returning: error == nil)
                }
            }
        #else
            true
        #endif
    }
}
