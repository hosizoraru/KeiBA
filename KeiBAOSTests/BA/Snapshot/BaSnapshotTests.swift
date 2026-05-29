//
//  BaSnapshotTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/29.
//

@testable import KeiBAOS
import XCTest
import SwiftUI

final class BaSnapshotTests: XCTestCase {
    private var isCI: Bool {
        ProcessInfo.processInfo.environment["CI"] != nil ||
            ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] != nil
    }

    func testOverviewCardsLayout() throws {
        try XCTSkipIf(isCI, "Snapshot tests skipped on CI due to rendering differences")
        let cards = VStack(spacing: 12) {
            BaGlassCard(tint: BaDesign.green) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AP").font(.headline)
                        Text("1 / 240").font(.title2.bold())
                    }
                    Spacer()
                    Image(systemName: "drop.fill").foregroundStyle(BaDesign.green)
                }
            }
            .frame(height: 100)

            BaGlassCard(tint: BaDesign.blue) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("咖啡厅").font(.headline)
                        Text("462 / 1740").font(.title2.bold())
                    }
                    Spacer()
                    Image(systemName: "cup.and.saucer.fill").foregroundStyle(BaDesign.blue)
                }
            }
            .frame(height: 100)
        }
        .padding()

        BaSnapshotTesting.assertSnapshot(of: cards, named: "overview-cards-layout")
    }

    func testGalleryCardLayout() throws {
        try XCTSkipIf(isCI, "Snapshot tests skipped on CI due to rendering differences")
        let card = BaGlassCard(tint: BaDesign.pink) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("表情包").font(.headline)
                    Spacer()
                    Text("3 张").font(.caption).foregroundStyle(.secondary)
                }
                RoundedRectangle(cornerRadius: 12)
                    .fill(BaDesign.pink.opacity(0.15))
                    .frame(height: 180)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(BaDesign.pink)
                    }
            }
        }
        .frame(width: 320)
        .padding()

        BaSnapshotTesting.assertSnapshot(of: card, named: "gallery-card-layout")
    }

    func testRichTextViewLayout() throws {
        try XCTSkipIf(isCI, "Snapshot tests skipped on CI due to rendering differences")
        let text = BaSelectableRichTextView(
            segments: [
                .text("普通文本 "),
                .emphasized("加粗文本 "),
                .tinted("着色文本 "),
                .secondary("次要文本"),
            ],
            plainText: "普通文本 加粗文本 着色文本 次要文本",
            tint: BaDesign.blue
        )
        .frame(width: 300)
        .padding()

        BaSnapshotTesting.assertSnapshot(of: text, named: "rich-text-view-layout")
    }
}
