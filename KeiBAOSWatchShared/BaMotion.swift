//
//  BaMotion.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/19.
//

import SwiftUI

enum BaMotion {
    static let quick = Animation.smooth(duration: 0.16)
    static let standard = Animation.smooth(duration: 0.24)
    static let emphasized = Animation.spring(duration: 0.34, bounce: 0.18)
    static let numeric = Animation.smooth(duration: 0.28)
    static let press = Animation.smooth(duration: 0.14)

    static func resolved(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }

    static var subtleTransition: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.985))
    }
}

struct BaPressButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .baPressFeedback(isPressed: configuration.isPressed, scale: scale)
    }
}

extension View {
    func baMotion<Value: Equatable>(
        _ animation: Animation = BaMotion.standard,
        value: Value
    ) -> some View {
        modifier(BaMotionAnimationModifier(animation: animation, value: value))
    }

    func baNumericTextTransition<Value: Equatable>(
        value: Value
    ) -> some View {
        modifier(BaNumericTextTransitionModifier(value: value))
    }

    func baSymbolBounce<Value: Equatable>(
        value: Value
    ) -> some View {
        modifier(BaSymbolBounceModifier(value: value))
    }

    func baPressFeedback(
        isPressed: Bool,
        scale: CGFloat = 0.96
    ) -> some View {
        modifier(BaPressFeedbackModifier(isPressed: isPressed, scale: scale))
    }
}

private struct BaMotionAnimationModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let animation: Animation
    let value: Value

    func body(content: Content) -> some View {
        content.animation(BaMotion.resolved(animation, reduceMotion: reduceMotion), value: value)
    }
}

private struct BaNumericTextTransitionModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let value: Value

    func body(content: Content) -> some View {
        content
            .contentTransition(reduceMotion ? .opacity : .numericText())
            .animation(BaMotion.resolved(BaMotion.numeric, reduceMotion: reduceMotion), value: value)
    }
}

private struct BaSymbolBounceModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let value: Value

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.symbolEffect(.bounce, value: value)
        }
    }
}

private struct BaPressFeedbackModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isPressed: Bool
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(reduceMotion ? 1 : (isPressed ? scale : 1))
            .animation(BaMotion.resolved(BaMotion.press, reduceMotion: reduceMotion), value: isPressed)
    }
}
