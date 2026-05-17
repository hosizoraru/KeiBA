//
//  BaLibraryView.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

struct BaLibraryView: View {
    @Environment(BaAppModel.self) private var model
    #if os(iOS)
        @Environment(\.tabBarPlacement) private var tabBarPlacement
    #endif

    let playbackSession: BaMusicPlaybackSession

    @State private var searchText = ""

    @MainActor
    init() {
        playbackSession = BaMusicPlaybackSession()
    }

    init(playbackSession: BaMusicPlaybackSession) {
        self.playbackSession = playbackSession
    }

    private var snapshot: BaMusicLibrarySnapshot {
        musicSnapshot(query: searchText)
    }

    private func musicSnapshot(query: String) -> BaMusicLibrarySnapshot {
        BaMusicLibraryBuilder.snapshot(
            favoriteEntries: model.entries(for: .favorites, query: "", sortMode: .defaultOrder),
            detailStates: model.studentDetailStates,
            query: query
        )
    }

    var body: some View {
        let snapshot = snapshot

        BaAdaptiveGeometry { metrics in
            musicPage(snapshot: snapshot, metrics: metrics)
                .background(AppBackground())
                #if os(macOS)
                    .safeAreaInset(edge: .bottom, spacing: 10) {
                        BaMusicMiniNowPlayingBar(session: playbackSession)
                            .padding(.horizontal, metrics.screenHorizontalPadding)
                            .padding(.bottom, 10)
                    }
                #endif
        }
        .searchable(text: $searchText, prompt: Text(String(localized: "ba.music.search.prompt")))
        .task {
            await model.loadCatalogIfNeeded()
        }
        .task(id: snapshot.queueSignature) {
            playbackSession.updateQueue(snapshot.playableTracks)
        }
    }

    @ViewBuilder
    private func musicPage(snapshot: BaMusicLibrarySnapshot, metrics: BaAdaptiveMetrics) -> some View {
        if usesSplitPage(snapshot: snapshot, metrics: metrics) {
            splitMusicPage(snapshot: snapshot, metrics: metrics)
        } else {
            stackedMusicPage(snapshot: snapshot, metrics: metrics)
        }
    }

    private func stackedMusicPage(snapshot: BaMusicLibrarySnapshot, metrics: BaAdaptiveMetrics) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: metrics.cardSpacing) {
                if let status = libraryStatusText(snapshot: snapshot) {
                    musicStatus(status)
                }
                musicContent(snapshot: snapshot, metrics: metrics)
            }
            .baAdaptiveReadableContent(
                maxWidth: BaMusicLibraryLayoutPolicy.contentMaxWidth(
                    for: metrics,
                    navigationChrome: navigationChrome
                )
            )
            .padding(.horizontal, metrics.screenHorizontalPadding)
            .padding(.vertical, metrics.screenVerticalPadding)
            .safeAreaPadding(.bottom, 16)
        }
        .refreshable {
            await refreshMusicLibrary()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func splitMusicPage(snapshot: BaMusicLibrarySnapshot, metrics: BaAdaptiveMetrics) -> some View {
        HStack(alignment: .top, spacing: metrics.cardSpacing) {
            ScrollView {
                BaMusicNowPlayingHero(
                    track: playbackSession.selectedTrack ?? snapshot.firstPlayableTrack,
                    session: playbackSession,
                    metrics: metrics,
                    layout: .stacked
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .frame(width: BaMusicLibraryLayoutPolicy.heroColumnWidth(for: metrics))

            ScrollView {
                VStack(alignment: .leading, spacing: metrics.cardSpacing) {
                    if let status = libraryStatusText(snapshot: snapshot) {
                        musicStatus(status)
                    }
                    trackSection(snapshot: snapshot, metrics: metrics)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .refreshable {
                await refreshMusicLibrary()
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .baAdaptiveReadableContent(
            maxWidth: BaMusicLibraryLayoutPolicy.contentMaxWidth(
                for: metrics,
                navigationChrome: navigationChrome
            )
        )
        .padding(.horizontal, metrics.screenHorizontalPadding)
        .padding(.vertical, metrics.screenVerticalPadding)
        .safeAreaPadding(.bottom, 16)
    }

    private func musicStatus(_ status: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "music.note")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BaMusicAccentPalette.fallback)

            Text(status)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func musicContent(snapshot: BaMusicLibrarySnapshot, metrics: BaAdaptiveMetrics) -> some View {
        if model.catalogState.isLoading, snapshot.tracks.isEmpty {
            BaGlassCard(tint: BaMusicAccentPalette.fallback) {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 22)
            }
        } else if snapshot.tracks.isEmpty {
            ContentUnavailableView(
                String(localized: "ba.music.empty.title"),
                systemImage: "music.note",
                description: Text(String(localized: "ba.music.empty.detail"))
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
        } else if snapshot.visibleTracks.isEmpty {
            ContentUnavailableView(
                String(localized: "ba.catalog.empty.title"),
                systemImage: "magnifyingglass",
                description: Text(String(localized: "ba.music.empty.search.detail"))
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
        } else {
            musicLayout(snapshot: snapshot, metrics: metrics)
        }
    }

    @ViewBuilder
    private func musicLayout(snapshot: BaMusicLibrarySnapshot, metrics: BaAdaptiveMetrics) -> some View {
        let displayTrack = playbackSession.selectedTrack ?? snapshot.firstPlayableTrack

        VStack(alignment: .leading, spacing: metrics.cardSpacing) {
            BaMusicNowPlayingHero(
                track: displayTrack,
                session: playbackSession,
                metrics: metrics,
                layout: .stacked
            )
            trackSection(snapshot: snapshot, metrics: metrics)
        }
    }

    private func usesSplitPage(snapshot: BaMusicLibrarySnapshot, metrics: BaAdaptiveMetrics) -> Bool {
        snapshot.visibleTracks.isEmpty == false &&
            BaMusicLibraryLayoutPolicy.layoutStyle(for: metrics, navigationChrome: navigationChrome) == .split
    }

    private func trackSection(snapshot: BaMusicLibrarySnapshot, metrics: BaAdaptiveMetrics) -> some View {
        BaMusicQueueSection(
            title: String(localized: "ba.music.queue.title"),
            tracks: snapshot.visibleTracks,
            thumbnailSize: metrics.catalogThumbnailSize,
            thumbnailMaxPixelDimension: metrics.catalogThumbnailMaxPixelDimension,
            currentTrackID: playbackSession.selectedTrack?.id,
            isPlaying: playbackSession.player.isPlaying,
            cacheState: playbackSession.cacheState(for:),
            onPrimaryAction: playTrack,
            onCache: cacheTrack,
            onClearCache: { playbackSession.clearCache(for: $0) },
            onCacheAll: cacheTracks,
            onClearAllCache: { playbackSession.clearCachedTracks($0) },
            onLoadDetail: loadDetail,
            onRefreshCacheState: playbackSession.refreshCacheState(for:)
        )
    }

    private func libraryStatusText(snapshot: BaMusicLibrarySnapshot) -> String? {
        if let error = model.catalogState.errorMessage, error.isEmpty == false {
            return String(format: String(localized: "ba.state.error.format"), error)
        }
        if snapshot.playableTracks.isEmpty, snapshot.tracks.isEmpty == false {
            return String(localized: "ba.music.library.loading.subtitle")
        }
        return nil
    }

    private func playTrack(_ track: BaMusicTrack) {
        if track.isPlayable {
            playbackSession.play(track)
        } else {
            loadDetail(track)
        }
    }

    private func loadDetail(_ track: BaMusicTrack) {
        Task {
            await model.loadStudentDetail(entry: track.entry)
        }
    }

    private func cacheTrack(_ track: BaMusicTrack) {
        if track.audioURL != nil {
            playbackSession.cache(track)
            return
        }
        Task {
            await model.loadStudentDetail(entry: track.entry)
            if let refreshedTrack = refreshedTracks(matching: [track.id], query: searchText).first {
                playbackSession.cache(refreshedTrack)
            }
        }
    }

    private func cacheTracks(_ tracks: [BaMusicTrack]) {
        let requestedIDs = Set(tracks.map(\.id))
        Task {
            await model.loadStudentDetails(
                entries: tracks.filter(\.needsDetailForMusicCache).map(\.entry)
            )
            playbackSession.cacheAll(refreshedTracks(matching: requestedIDs, query: searchText))
        }
    }

    private func refreshedTracks(matching ids: Set<Int64>, query: String) -> [BaMusicTrack] {
        musicSnapshot(query: query).tracks.filter { ids.contains($0.id) }
    }

    private func refreshMusicLibrary() async {
        await model.refreshCatalog(force: true)
        await model.loadStudentDetails(
            entries: snapshot.visibleTracks.map(\.entry),
            force: true,
            limit: BaPlatformPerformanceProfile.musicInitialDetailFetchLimit
        )
    }

    private var navigationChrome: BaMusicLibraryNavigationChrome {
        #if os(iOS)
            switch tabBarPlacement {
            case .sidebar:
                .sidebar
            case .topBar:
                .topBar
            default:
                .other
            }
        #else
            .other
        #endif
    }
}

private extension BaMusicTrack {
    var needsDetailForMusicCache: Bool {
        guard audioURL == nil else { return false }
        switch availability {
        case .needsDetail, .failed:
            return true
        case .loadingDetail, .ready, .missing:
            return false
        }
    }
}

#Preview {
    NavigationStack {
        BaLibraryView()
            .navigationTitle(AppTab.library.title)
    }
    .environment(BaAppModel.live())
}
