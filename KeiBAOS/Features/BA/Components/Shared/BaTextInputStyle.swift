//
//  BaTextInputStyle.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import SwiftUI

extension View {
    @ViewBuilder
    func baNicknameTextInput() -> some View {
        #if os(iOS)
            self
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .textContentType(.nickname)
                .submitLabel(.done)
        #else
            self
                .autocorrectionDisabled()
        #endif
    }

    @ViewBuilder
    func baFriendCodeTextInput() -> some View {
        #if os(iOS)
            self
                .monospaced()
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .keyboardType(.asciiCapable)
                .submitLabel(.done)
        #else
            self
                .monospaced()
                .autocorrectionDisabled()
        #endif
    }

    @ViewBuilder
    func baNumberTextInput() -> some View {
        #if os(iOS)
            self
                .monospacedDigit()
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.numberPad)
                .submitLabel(.done)
        #else
            self
                .monospacedDigit()
                .autocorrectionDisabled()
        #endif
    }
}
