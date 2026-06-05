//
//  BaAppModel+Office.swift
//  KeiBA
//
//  Created by Codex on 2026/05/18.
//

import Foundation

extension BaAppModel {
    func refreshOfficeSnapshot(now: Date = Date()) {
        officeSnapshot = officeRepository.snapshot(settings: settings, now: now)
    }

    func officeSnapshot(now: Date = Date()) -> BaOfficeSnapshot {
        officeRepository.snapshot(settings: settings, now: now)
    }

    func officeAPSnapshot(now: Date = Date()) -> BaOfficeAPSnapshot {
        officeRepository.apSnapshot(settings: settings, now: now)
    }
}
