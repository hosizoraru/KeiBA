//
//  BaStudentGuideModels.swift
//  KeiBAOS
//
//  Split from BaDomainModels.swift by Codex on 2026/05/16.
//

import Foundation

nonisolated enum BaStudentDetailSection: String, CaseIterable, Codable, Identifiable, Hashable {
    case profile
    case skills
    case growth
    case voice
    case gallery
    case simulate

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .profile:
            BaL10n.string("ba.student.detail.section.profile")
        case .skills:
            BaL10n.string("ba.student.detail.section.skills")
        case .growth:
            BaL10n.string("ba.student.detail.section.growth")
        case .voice:
            BaL10n.string("ba.student.detail.section.voice")
        case .gallery:
            BaL10n.string("ba.student.detail.section.gallery")
        case .simulate:
            BaL10n.string("ba.student.detail.section.simulate")
        }
    }

    var systemImage: String {
        switch self {
        case .profile:
            "person.text.rectangle"
        case .skills:
            "sparkles"
        case .growth:
            "shield.lefthalf.filled"
        case .voice:
            "waveform"
        case .gallery:
            "photo.on.rectangle.angled"
        case .simulate:
            "chart.xyaxis.line"
        }
    }
}

nonisolated enum BaStudentDetailPage: String, CaseIterable, Codable, Identifiable, Hashable {
    case overviewProfile
    case skills
    case profile
    case voice
    case gallery
    case simulate

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .overviewProfile:
            BaL10n.string("ba.student.detail.page.overviewProfile")
        case .skills:
            BaL10n.string("ba.student.detail.page.skills")
        case .profile:
            BaL10n.string("ba.student.detail.page.profile")
        case .voice:
            BaL10n.string("ba.student.detail.page.voice")
        case .gallery:
            BaL10n.string("ba.student.detail.page.gallery")
        case .simulate:
            BaL10n.string("ba.student.detail.page.simulate")
        }
    }
}

nonisolated struct BaGuideRow: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let value: String
    let imageURL: URL?
    var imageURLs: [URL]? = nil
}

nonisolated enum BaGuideMediaKind: String, Codable, Hashable {
    case image
    case video
    case audio
    case live2d
    case unknown

    var systemImage: String {
        switch self {
        case .image:
            "photo"
        case .video:
            "play.rectangle"
        case .audio:
            "waveform"
        case .live2d:
            "person.crop.square"
        case .unknown:
            "paperclip"
        }
    }

    var title: String {
        switch self {
        case .image:
            BaL10n.string("ba.student.detail.media.image")
        case .video:
            BaL10n.string("ba.student.detail.media.video")
        case .audio:
            BaL10n.string("ba.student.detail.media.audio")
        case .live2d:
            BaL10n.string("ba.student.detail.media.live2d")
        case .unknown:
            BaL10n.string("ba.student.detail.media.unknown")
        }
    }
}

nonisolated struct BaGuideGalleryItem: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let detail: String
    let imageURL: URL?
    let mediaURL: URL?
    var mediaKind: BaGuideMediaKind? = nil
    var memoryUnlockLevel: String? = nil
    var note: String? = nil
}

nonisolated struct BaGuideVoiceEntry: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let transcript: String
    let audioURL: URL?
    var section: String? = nil
    var lineHeaders: [String]? = nil
    var lines: [String]? = nil
    var audioURLs: [URL]? = nil
    var audioHeaders: [String]? = nil
}

nonisolated struct BaStudentGuideInfo: Identifiable, Codable, Hashable {
    let contentId: Int64
    let sourceURL: URL?
    let title: String
    let subtitle: String
    let summary: String
    let imageURL: URL?
    let stats: [BaGuideRow]
    let profileRows: [BaGuideRow]
    let skillRows: [BaGuideRow]
    let voiceLanguageHeaders: [String]
    let voiceRows: [BaGuideVoiceEntry]
    let galleryItems: [BaGuideGalleryItem]
    let growthRows: [BaGuideRow]
    let simulateRows: [BaGuideRow]
    let contentSource: String
    let syncedAt: Date

    var id: Int64 {
        contentId
    }

    init(
        contentId: Int64,
        sourceURL: URL?,
        title: String,
        subtitle: String,
        summary: String,
        imageURL: URL?,
        stats: [BaGuideRow],
        profileRows: [BaGuideRow],
        skillRows: [BaGuideRow],
        voiceLanguageHeaders: [String] = [],
        voiceRows: [BaGuideVoiceEntry],
        galleryItems: [BaGuideGalleryItem],
        growthRows: [BaGuideRow],
        simulateRows: [BaGuideRow],
        contentSource: String,
        syncedAt: Date
    ) {
        self.contentId = contentId
        self.sourceURL = sourceURL
        self.title = title
        self.subtitle = subtitle
        self.summary = summary
        self.imageURL = imageURL
        self.stats = stats
        self.profileRows = profileRows
        self.skillRows = skillRows
        self.voiceLanguageHeaders = voiceLanguageHeaders
        self.voiceRows = voiceRows
        self.galleryItems = galleryItems
        self.growthRows = growthRows
        self.simulateRows = simulateRows
        self.contentSource = contentSource
        self.syncedAt = syncedAt
    }

    private enum CodingKeys: String, CodingKey {
        case contentId
        case sourceURL
        case title
        case subtitle
        case summary
        case imageURL
        case stats
        case profileRows
        case skillRows
        case voiceLanguageHeaders
        case voiceRows
        case galleryItems
        case growthRows
        case simulateRows
        case contentSource
        case syncedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            contentId: try container.decode(Int64.self, forKey: .contentId),
            sourceURL: try container.decodeIfPresent(URL.self, forKey: .sourceURL),
            title: try container.decode(String.self, forKey: .title),
            subtitle: try container.decode(String.self, forKey: .subtitle),
            summary: try container.decode(String.self, forKey: .summary),
            imageURL: try container.decodeIfPresent(URL.self, forKey: .imageURL),
            stats: try container.decode([BaGuideRow].self, forKey: .stats),
            profileRows: try container.decode([BaGuideRow].self, forKey: .profileRows),
            skillRows: try container.decode([BaGuideRow].self, forKey: .skillRows),
            voiceLanguageHeaders: try container.decodeIfPresent([String].self, forKey: .voiceLanguageHeaders) ?? [],
            voiceRows: try container.decode([BaGuideVoiceEntry].self, forKey: .voiceRows),
            galleryItems: try container.decode([BaGuideGalleryItem].self, forKey: .galleryItems),
            growthRows: try container.decode([BaGuideRow].self, forKey: .growthRows),
            simulateRows: try container.decode([BaGuideRow].self, forKey: .simulateRows),
            contentSource: try container.decode(String.self, forKey: .contentSource),
            syncedAt: try container.decode(Date.self, forKey: .syncedAt)
        )
    }
}
