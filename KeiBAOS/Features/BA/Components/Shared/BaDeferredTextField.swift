//
//  BaDeferredTextField.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import SwiftUI

struct BaDeferredTextField: View {
    let title: String
    let value: String
    let prompt: String
    let sanitizeDraft: (String) -> String
    let normalizeCommit: (String) -> String
    let onCommit: (String) -> Void

    @State private var draft: String
    @FocusState private var isFocused: Bool

    init(
        title: String,
        value: String,
        prompt: String,
        sanitizeDraft: @escaping (String) -> String = { $0 },
        normalizeCommit: @escaping (String) -> String = { $0 },
        onCommit: @escaping (String) -> Void
    ) {
        self.title = title
        self.value = value
        self.prompt = prompt
        self.sanitizeDraft = sanitizeDraft
        self.normalizeCommit = normalizeCommit
        self.onCommit = onCommit
        _draft = State(initialValue: value)
    }

    var body: some View {
        TextField(title, text: $draft, prompt: Text(prompt))
            .focused($isFocused)
            .onSubmit {
                commitDraft()
                isFocused = false
            }
            .onChange(of: draft) { _, newValue in
                let sanitized = sanitizeDraft(newValue)
                guard sanitized != newValue else { return }
                draft = sanitized
            }
            .onChange(of: value) { _, newValue in
                guard isFocused == false else { return }
                draft = newValue
            }
            .onChange(of: isFocused) { _, focused in
                guard focused == false else { return }
                commitDraft()
            }
            .onDisappear(perform: commitDraft)
    }

    private func commitDraft() {
        let committed = normalizeCommit(draft)
        if draft != committed {
            draft = committed
        }
        guard committed != value else {
            if isFocused == false, draft != value {
                draft = value
            }
            return
        }
        onCommit(committed)
    }
}

struct BaDeferredIntField: View {
    let title: String
    let value: Int
    let prompt: String
    let range: ClosedRange<Int>
    let onCommit: (Int) -> Void

    @State private var draft: String
    @FocusState private var isFocused: Bool

    init(
        title: String,
        value: Int,
        prompt: String,
        range: ClosedRange<Int>,
        onCommit: @escaping (Int) -> Void
    ) {
        self.title = title
        self.value = value
        self.prompt = prompt
        self.range = range
        self.onCommit = onCommit
        _draft = State(initialValue: "\(value)")
    }

    var body: some View {
        TextField(title, text: $draft, prompt: Text(prompt))
            .focused($isFocused)
            .onSubmit {
                commitDraft()
                isFocused = false
            }
            .onChange(of: draft) { _, newValue in
                let sanitized = sanitizedDraft(newValue)
                guard sanitized != newValue else { return }
                draft = sanitized
            }
            .onChange(of: value) { _, newValue in
                guard isFocused == false else { return }
                draft = "\(newValue)"
            }
            .onChange(of: isFocused) { _, focused in
                guard focused == false else { return }
                commitDraft()
            }
            .onDisappear(perform: commitDraft)
    }

    private func sanitizedDraft(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(max(String(range.upperBound).count, 1)))
    }

    private func commitDraft() {
        guard let rawValue = Int(draft) else {
            draft = "\(value)"
            return
        }
        let committed = min(max(rawValue, range.lowerBound), range.upperBound)
        let committedText = "\(committed)"
        if draft != committedText {
            draft = committedText
        }
        guard committed != value else { return }
        onCommit(committed)
    }
}
