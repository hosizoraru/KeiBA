//
//  BaStudentDetailGalleryTests.swift
//  KeiBATests
//
//  Split by Codex on 2026/05/16.
//

@testable import KeiBA
import UniformTypeIdentifiers
import XCTest

final class BaStudentDetailGalleryTests: XCTestCase {
    func testGuideMediaExportMetadataKeepsGIFExtension() throws {
        let url = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/furniture-1.gif?x=1"))
        let metadata = BaGuideMediaExportBuilder.metadata(for: url, title: "互动家具 1")

        XCTAssertEqual(metadata.fileName, "互动家具 1.gif")
    }

    func testGuideMediaExportMetadataHandlesVideoAndAudioExtensions() throws {
        let videoURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/memory.mp4?token=1"))
        let audioURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/bgm.ogg"))

        XCTAssertEqual(BaGuideMediaExportBuilder.metadata(for: videoURL, title: "回忆大厅视频").contentType.preferredFilenameExtension, "mp4")
        XCTAssertEqual(BaGuideMediaExportBuilder.metadata(for: audioURL, title: "BGM").contentType.preferredFilenameExtension, "ogg")
    }

    func testPlatformMediaPreviewPolicyPrefersQuickLookWhenAvailable() throws {
        let gifURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/furniture.gif?token=1"))
        let audioURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/bgm.ogg"))

        XCTAssertEqual(
            BaPlatformMediaPreviewPolicy.renderer(for: .image, fileURL: gifURL, isQuickLookAvailable: true),
            .quickLook
        )
        XCTAssertEqual(
            BaPlatformMediaPreviewPolicy.renderer(for: .audio, fileURL: audioURL, isQuickLookAvailable: true),
            .quickLook
        )
    }

    func testPlatformMediaPreviewPolicyFallsBackToZoomOnlyForImageMedia() throws {
        let imageURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/portrait.webp"))
        let videoURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/memory.mp4"))
        let audioURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/bgm.ogg"))

        XCTAssertEqual(
            BaPlatformMediaPreviewPolicy.renderer(for: .image, fileURL: imageURL, isQuickLookAvailable: false),
            .zoomableImage
        )
        XCTAssertEqual(
            BaPlatformMediaPreviewPolicy.renderer(for: .video, fileURL: videoURL, isQuickLookAvailable: false),
            .iconFallback
        )
        XCTAssertEqual(
            BaPlatformMediaPreviewPolicy.renderer(for: .audio, fileURL: audioURL, isQuickLookAvailable: false),
            .iconFallback
        )
    }

    func testGalleryDisplayStateGroupsExpressionsAndFiltersProfileOnlyMedia() throws {
        let standing = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/standing.png"))
        let memory = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/memory.png"))
        let memoryVideo = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/memory.mp4"))
        let bgm = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/bgm.ogg"))
        let expression1 = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/expression1.png"))
        let expression2 = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/expression2.png"))
        let furniture = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/furniture.gif"))
        let chocolate = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/chocolate.png"))
        let info = BaStudentGuideInfo(
            contentId: 611_753,
            sourceURL: nil,
            title: "日奈(礼服)",
            subtitle: "GameKee",
            summary: "",
            imageURL: standing,
            stats: [],
            profileRows: [
                BaGuideRow(id: "unlock", title: "回忆大厅解锁等级", value: "羁绊 5", imageURL: nil),
                BaGuideRow(id: "link", title: "影画相关链接", value: "官方介绍 / https://bluearchive.jp", imageURL: nil),
            ],
            skillRows: [],
            voiceRows: [],
            galleryItems: [
                BaGuideGalleryItem(id: "standing", title: "立绘", detail: "图片", imageURL: standing, mediaURL: standing, mediaKind: .image),
                BaGuideGalleryItem(id: "memory", title: "回忆大厅", detail: "图片", imageURL: memory, mediaURL: memory, mediaKind: .image, memoryUnlockLevel: "5"),
                BaGuideGalleryItem(id: "memory-video", title: "回忆大厅视频", detail: "视频", imageURL: nil, mediaURL: memoryVideo, mediaKind: .video),
                BaGuideGalleryItem(id: "bgm", title: "BGM", detail: "音频", imageURL: nil, mediaURL: bgm, mediaKind: .audio),
                BaGuideGalleryItem(id: "expression1", title: "角色表情 1", detail: "图片", imageURL: expression1, mediaURL: expression1, mediaKind: .image),
                BaGuideGalleryItem(id: "expression2", title: "表情差分 2", detail: "图片", imageURL: expression2, mediaURL: expression2, mediaKind: .image),
                BaGuideGalleryItem(id: "furniture", title: "互动家具 1 2", detail: "图片", imageURL: furniture, mediaURL: furniture, mediaKind: .image),
                BaGuideGalleryItem(id: "chocolate", title: "巧克力图", detail: "图片", imageURL: chocolate, mediaURL: chocolate, mediaKind: .image),
            ],
            growthRows: [],
            simulateRows: [],
            contentSource: "content_json",
            syncedAt: Date(timeIntervalSince1970: 0)
        )

        let state = BaStudentGalleryDisplayState(info: info)

        XCTAssertEqual(state.memoryUnlockLevel, "5")
        XCTAssertEqual(state.memoryHallVideoGroup?.items.first?.imageURL, memory)
        XCTAssertEqual(state.expressionItems.map(\.id), ["expression1", "expression2"])
        XCTAssertEqual(state.galleryRelatedLinkRows.map(\.id), ["link"])
        XCTAssertTrue(state.displayGalleryItems.contains { $0.id == "bgm" })
        XCTAssertFalse(state.displayGalleryItems.contains { $0.id == "furniture" })
        XCTAssertFalse(state.displayGalleryItems.contains { $0.id == "chocolate" })
        XCTAssertEqual(state.rows.map(\.id), [
            "item-standing",
            "memory-unlock-5",
            "item-memory",
            "video-回忆大厅视频|memory-video",
            "item-bgm",
            "expression-expression1,expression2",
            "related-link",
        ])
    }

    func testGalleryVariantTitleResolverNumbersDuplicatePVItems() throws {
        let pv1 = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/pv-1.mp4"))
        let pv2 = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina/pv-2.mp4"))
        let items = [
            BaGuideGalleryItem(id: "pv1", title: "PV", detail: "视频", imageURL: nil, mediaURL: pv1, mediaKind: .video),
            BaGuideGalleryItem(id: "pv2", title: "PV", detail: "视频", imageURL: nil, mediaURL: pv2, mediaKind: .video),
        ]

        XCTAssertEqual(items.map { BaGalleryVariantTitleResolver.title(for: $0, in: items) }, ["PV1", "PV2"])
    }

    func testGalleryCardLayoutsFollowHinaDressSampleMediaRatios() throws {
        let portrait = try XCTUnwrap(URL(string: "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_968/h_1292/829/43637/2025/4/26/608184.png"))
        let memory = try XCTUnwrap(URL(string: "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_1210/h_888/829/43637/2025/4/26/427347.png"))
        let officialIntro = try XCTUnwrap(URL(string: "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_908/h_1210/829/43637/2025/4/26/53825.png"))
        let expression = try XCTUnwrap(URL(string: "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_550/h_550/829/157597/2025/5/17/530525.png"))
        let video = try XCTUnwrap(URL(string: "https://cdnimg-v2.gamekee.com/wiki2.0/video/829/43637/2025/4/26/622281.mp4"))

        let portraitLayout = BaStudentGalleryMediaLayout(item: BaGuideGalleryItem(id: "portrait", title: "立绘1", detail: "图片", imageURL: portrait, mediaURL: portrait, mediaKind: .image))
        let memoryLayout = BaStudentGalleryMediaLayout(item: BaGuideGalleryItem(id: "memory", title: "回忆大厅", detail: "图片", imageURL: memory, mediaURL: memory, mediaKind: .image))
        let introLayout = BaStudentGalleryMediaLayout(item: BaGuideGalleryItem(id: "intro", title: "官方介绍1", detail: "图片", imageURL: officialIntro, mediaURL: officialIntro, mediaKind: .image))
        let expressionLayout = BaStudentGalleryMediaLayout(item: BaGuideGalleryItem(id: "expression", title: "角色表情 1", detail: "图片", imageURL: expression, mediaURL: expression, mediaKind: .image))
        let videoLayout = BaStudentGalleryMediaLayout(item: BaGuideGalleryItem(id: "video", title: "回忆大厅视频", detail: "视频", imageURL: memory, mediaURL: video, mediaKind: .video))

        XCTAssertEqual(portrait.baGalleryPixelSize?.width, 968)
        XCTAssertEqual(portrait.baGalleryPixelSize?.height, 1292)
        XCTAssertEqual(portraitLayout.height, 430, accuracy: 0.5)
        XCTAssertEqual(memoryLayout.height, 261.4, accuracy: 1.0)
        XCTAssertEqual(introLayout.height, 406, accuracy: 0.5)
        XCTAssertEqual(expressionLayout.height, 252, accuracy: 0.5)
        XCTAssertEqual(videoLayout.height, 200.3, accuracy: 1.0)

        XCTAssertEqual(portraitLayout.resolved(for: .regular).height, 507.4, accuracy: 1.0)
        XCTAssertEqual(portraitLayout.resolved(for: .desktop).height, 533.2, accuracy: 1.0)
        XCTAssertEqual(portraitLayout.resolved(for: .preview).height, 580.5, accuracy: 1.0)
        XCTAssertEqual(videoLayout.resolved(for: .regular).height, 252.5, accuracy: 1.0)
        XCTAssertEqual(videoLayout.resolved(for: .desktop).height, 265.4, accuracy: 1.0)
        XCTAssertEqual(videoLayout.resolved(for: .preview).height, 288.9, accuracy: 1.0)
    }
}
