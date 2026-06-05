//
//  BaPlatformSearchField.swift
//  KeiBA
//
//  Created by Codex on 2026/05/29.
//

import SwiftUI

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

struct BaPlatformSearchField: View {
    @Binding var text: String

    let prompt: String
    var onSubmit: (() -> Void)?

    var body: some View {
        Representable(text: $text, prompt: prompt, onSubmit: onSubmit)
            .frame(minHeight: 38, idealHeight: 38, maxHeight: 42)
            .accessibilityLabel(Text(prompt))
    }
}

#if os(iOS)
private extension BaPlatformSearchField {
    struct Representable: UIViewRepresentable {
        @Binding var text: String

        let prompt: String
        let onSubmit: (() -> Void)?

        func makeUIView(context: Context) -> UISearchTextField {
            let textField = UISearchTextField(frame: .zero)
            textField.delegate = context.coordinator
            textField.placeholder = prompt
            textField.text = text
            textField.clearButtonMode = .whileEditing
            textField.returnKeyType = .search
            textField.enablesReturnKeyAutomatically = false
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
            textField.adjustsFontForContentSizeCategory = true
            textField.addTarget(
                context.coordinator,
                action: #selector(Coordinator.textDidChange(_:)),
                for: .editingChanged
            )
            return textField
        }

        func updateUIView(_ textField: UISearchTextField, context: Context) {
            context.coordinator.text = $text
            context.coordinator.onSubmit = onSubmit
            if textField.placeholder != prompt {
                textField.placeholder = prompt
            }
            if textField.text != text {
                textField.text = text
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(text: $text, onSubmit: onSubmit)
        }

        final class Coordinator: NSObject, UITextFieldDelegate {
            var text: Binding<String>
            var onSubmit: (() -> Void)?

            init(text: Binding<String>, onSubmit: (() -> Void)?) {
                self.text = text
                self.onSubmit = onSubmit
            }

            @objc
            func textDidChange(_ sender: UISearchTextField) {
                let nextText = sender.text ?? ""
                guard text.wrappedValue != nextText else { return }
                text.wrappedValue = nextText
            }

            func textFieldShouldClear(_ textField: UITextField) -> Bool {
                text.wrappedValue = ""
                return true
            }

            func textFieldShouldReturn(_ textField: UITextField) -> Bool {
                onSubmit?()
                textField.resignFirstResponder()
                return true
            }
        }
    }
}
#elseif os(macOS)
private extension BaPlatformSearchField {
    struct Representable: NSViewRepresentable {
        @Binding var text: String

        let prompt: String
        let onSubmit: (() -> Void)?

        func makeNSView(context: Context) -> NSSearchField {
            let searchField = NSSearchField(frame: .zero)
            searchField.delegate = context.coordinator
            searchField.placeholderString = prompt
            searchField.stringValue = text
            searchField.sendsSearchStringImmediately = true
            searchField.sendsWholeSearchString = false
            searchField.controlSize = .large
            searchField.font = .preferredFont(forTextStyle: .body)
            searchField.target = context.coordinator
            searchField.action = #selector(Coordinator.submitSearch(_:))
            return searchField
        }

        func updateNSView(_ searchField: NSSearchField, context: Context) {
            context.coordinator.text = $text
            context.coordinator.onSubmit = onSubmit
            if searchField.placeholderString != prompt {
                searchField.placeholderString = prompt
            }
            if searchField.stringValue != text {
                searchField.stringValue = text
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(text: $text, onSubmit: onSubmit)
        }

        final class Coordinator: NSObject, NSSearchFieldDelegate {
            var text: Binding<String>
            var onSubmit: (() -> Void)?

            init(text: Binding<String>, onSubmit: (() -> Void)?) {
                self.text = text
                self.onSubmit = onSubmit
            }

            func controlTextDidChange(_ notification: Notification) {
                guard let searchField = notification.object as? NSSearchField else { return }
                let nextText = searchField.stringValue
                guard text.wrappedValue != nextText else { return }
                text.wrappedValue = nextText
            }

            func control(
                _ control: NSControl,
                textView: NSTextView,
                doCommandBy commandSelector: Selector
            ) -> Bool {
                guard commandSelector == #selector(NSResponder.insertNewline(_:)) else { return false }
                onSubmit?()
                textView.window?.makeFirstResponder(nil)
                return true
            }

            @objc
            func submitSearch(_ sender: NSSearchField) {
                let nextText = sender.stringValue
                if text.wrappedValue != nextText {
                    text.wrappedValue = nextText
                }
                onSubmit?()
            }
        }
    }
}
#else
private extension BaPlatformSearchField {
    struct Representable: View {
        @Binding var text: String

        let prompt: String
        let onSubmit: (() -> Void)?

        var body: some View {
            TextField(prompt, text: $text, prompt: Text(prompt))
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    onSubmit?()
                }
        }
    }
}
#endif
