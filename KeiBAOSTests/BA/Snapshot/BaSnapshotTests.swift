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
    func testOverviewCardsLayout() throws {
        try XCTSkipIf(!baselineExists("overview-cards-layout"), "Baseline not yet generated")
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
        try XCTSkipIf(!baselineExists("gallery-card-layout"), "Baseline not yet generated")
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
        try XCTSkipIf(!baselineExists("rich-text-view-layout"), "Baseline not yet generated")
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

    private func baselineExists(_ name: String) -> Bool {
        let baselineURL = BaSnapshotTesting.baselineDirectory.appendingPathComponent("\(name).png")
        return FileManager.default.fileExists(atPath: baselineURL.path)
    }
}
