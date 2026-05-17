//
//  BaDataErrorPresenter.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

enum BaDataErrorPresenter {
    static func studentDetailMessage(for sourceError: String?) -> String? {
        guard let sourceError, sourceError.isEmpty == false else { return nil }
        if isInternalStudentDetailSourceError(sourceError) {
            return BaL10n.string("ba.student.detail.partialSource.warning")
        }
        return sourceError
    }

    private static func isInternalStudentDetailSourceError(_ value: String) -> Bool {
        value.hasPrefix("content_cdn") ||
            value.hasPrefix("content_json") ||
            value.hasPrefix("content:")
    }
}
