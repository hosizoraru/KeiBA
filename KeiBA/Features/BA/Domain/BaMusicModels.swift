//
//  BaMusicModels.swift
//  KeiBA
//
//  Created by Codex on 2026/05/17.
//

import Foundation

nonisolated struct BaMusicTrack: Identifiable, Hashable {
    enum Availability: Hashable {
        case needsDetail
        case loadingDetail
        case ready
        case missing
        case failed(String)
    }

    let entry: BaGuideCatalogEntry
    let title: String
    let subtitle: String
    let artworkURL: URL?
    let audioURL: URL?
    let sourceURL: URL?
    let galleryTitle: String
    let availability: Availability

    var id: Int64 {
        entry.contentId
    }

    var isPlayable: Bool {
        audioURL != nil
    }

    var needsDetailLoadForMusic: Bool {
        guard audioURL == nil else { return false }
        switch availability {
        case .needsDetail, .failed:
            return true
        case .loadingDetail, .ready, .missing:
            return false
        }
    }

    func matches(trimmedQuery keyword: String) -> Bool {
        guard keyword.isEmpty == false else { return true }
        if entry.matches(trimmedQuery: keyword) { return true }
        return [
            title,
            subtitle,
            galleryTitle,
            sourceURL?.absoluteString ?? "",
            audioURL?.absoluteString ?? "",
        ].contains { value in
            value.localizedCaseInsensitiveContains(keyword)
        }
    }

    func refreshed(with track: BaMusicTrack) -> BaMusicTrack {
        guard id == track.id else { return self }
        return track
    }
}

nonisolated struct BaMusicLibrarySnapshot: Hashable {
    let tracks: [BaMusicTrack]
    let visibleTracks: [BaMusicTrack]
    let playableTracks: [BaMusicTrack]
    let queueSignature: String

    init(tracks: [BaMusicTrack], visibleTracks: [BaMusicTrack]) {
        self.tracks = tracks
        self.visibleTracks = visibleTracks
        playableTracks = tracks.filter(\.isPlayable)
        queueSignature = playableTracks
            .map { "\($0.id):\($0.audioURL?.absoluteString ?? "")" }
            .joined(separator: "|")
    }

    var firstPlayableTrack: BaMusicTrack? {
        playableTracks.first
    }
}

nonisolated enum BaMusicLibraryBuilder {
    static func snapshot(
        favoriteEntries: [BaGuideCatalogEntry],
        detailStates: [Int64: BaLoadableState<BaStudentGuideInfo>],
        query: String
    ) -> BaMusicLibrarySnapshot {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let tracks = favoriteEntries
            .filter(isStudentMusicFavorite)
            .map { track(for: $0, detailState: detailStates[$0.contentId]) }
        let visibleTracks = tracks.filter { $0.matches(trimmedQuery: keyword) }
        return BaMusicLibrarySnapshot(tracks: tracks, visibleTracks: visibleTracks)
    }

    static func preferredBGMItem(in info: BaStudentGuideInfo) -> BaGuideGalleryItem? {
        let audioItems = info.galleryItems.filter { item in
            (item.mediaKind ?? .unknown) == .audio &&
                item.mediaURL.map(BaGuideGallerySupport.isRenderableAudioURL) == true
        }
        return audioItems.first { item in
            let title = BaGuideGallerySupport.normalizeTitle(item.title)
            return title.localizedCaseInsensitiveContains("BGM") ||
                title.localizedCaseInsensitiveContains("回忆大厅")
        } ?? audioItems.first
    }

    private static func track(
        for entry: BaGuideCatalogEntry,
        detailState: BaLoadableState<BaStudentGuideInfo>?
    ) -> BaMusicTrack {
        guard let info = detailState?.value else {
            return BaMusicTrack(
                entry: entry,
                title: entry.name,
                subtitle: entry.aliasDisplay.isEmpty ? entry.alias : entry.aliasDisplay,
                artworkURL: entry.iconURL,
                audioURL: nil,
                sourceURL: entry.detailURL,
                galleryTitle: "",
                availability: availability(for: detailState)
            )
        }

        let item = preferredBGMItem(in: info)
        return BaMusicTrack(
            entry: entry,
            title: clean(info.title, fallback: entry.name),
            subtitle: BaL10n.string("ba.music.bgm.title"),
            artworkURL: info.preferredPortraitURL(fallback: entry.iconURL),
            audioURL: item?.mediaURL,
            sourceURL: info.sourceURL ?? entry.detailURL,
            galleryTitle: item?.title ?? "",
            availability: item?.mediaURL == nil ? .missing : .ready
        )
    }

    private static func availability(for detailState: BaLoadableState<BaStudentGuideInfo>?) -> BaMusicTrack.Availability {
        guard let detailState else { return .needsDetail }
        if detailState.isLoading { return .loadingDetail }
        if let error = detailState.errorMessage, error.isEmpty == false {
            return .failed(error)
        }
        return .needsDetail
    }

    private static func isStudentMusicFavorite(_ entry: BaGuideCatalogEntry) -> Bool {
        switch entry.category {
        case .students, .studentBgm:
            return true
        case .favorites:
            return entry.pid == BaCatalogCategory.students.gameKeePID
        case .npcSatellite:
            return false
        }
    }

    private static func clean(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}
