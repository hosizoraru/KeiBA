//
//  BaStartupInstrumentation.swift
//  KeiBA
//
//  Created by Codex on 2026/05/18.
//

import Foundation
import os.signpost

enum BaStartupInstrumentation {
    nonisolated static let log = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "KeiBA",
        category: .pointsOfInterest
    )

    nonisolated static func begin(_ name: StaticString) -> OSSignpostID {
        let signpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: name, signpostID: signpostID)
        return signpostID
    }

    nonisolated static func end(_ name: StaticString, _ signpostID: OSSignpostID) {
        os_signpost(.end, log: log, name: name, signpostID: signpostID)
    }
}
