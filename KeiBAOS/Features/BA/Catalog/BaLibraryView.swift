//
//  BaLibraryView.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

struct BaLibraryView: View {
    @Environment(BaAppModel.self) private var model

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
        BaMusicLibraryBuilder.snapshot(
            favoriteEntries: model.entries(for: .favorites, query: "", sortMode: .defaultOrder),
            detailStates: model.studentDetailStates,
            query: searchText
        )
    }

    var body: some View {
        let snapshot = snapshot

        BaAdaptiveGeometry { metrics in
            ScrollView {
                VStack(alignment: .leading, spacing: metrics.cardSpacing) {
                    musicIntro(snapshot: snapshot)
                    musicContent(snapshot: snapshot, metrics: metrics)
                }
                .baAdaptiveReadableContent(maxWidth: metrics.dashboardContentMaxWidth)
                .padding(.horizontal, metrics.screenHorizontalPadding)
                .padding(.vertical, metrics.screenVerticalPadding)
                .safeAreaPadding(.bottom, 16)
            }
            .refreshable {
                await refreshMusicLibrary()
            }
            .scrollDismissesKeyboard(.interactively)
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

    private func musicIntro(snapshot: BaMusicLibrarySnapshot) -> some View {
        BaGlassCard(tint: BaDesign.pink) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "music.note")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(BaDesign.pink)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(String(localized: "ba.music.library.title"))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(librarySubtitle(snapshot: snapshot))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func musicContent(snapshot: BaMusicLibrarySnapshot, metrics: BaAdaptiveMetrics) -> some View {
        if model.catalogState.isLoading, snapshot.tracks.isEmpty {
            BaGlassCard(tint: BaDesign.pink) {
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

        if metrics.widthClass == .expanded {
            HStack(alignment: .top, spacing: metrics.cardSpacing) {
                BaMusicNowPlayingHero(
                    track: displayTrack,
                    session: playbackSession,
                    metrics: metrics
                )
                .frame(width: 420)

                trackSection(snapshot: snapshot, metrics: metrics)
            }
        } else {
            VStack(alignment: .leading, spacing: metrics.cardSpacing) {
                BaMusicNowPlayingHero(
                    track: displayTrack,
                    session: playbackSession,
                    metrics: metrics
                )
                trackSection(snapshot: snapshot, metrics: metrics)
            }
        }
    }

    private func trackSection(snapshot: BaMusicLibrarySnapshot, metrics: BaAdaptiveMetrics) -> some View {
        BaMusicQueueSection(
            title: String(localized: "ba.music.queue.title"),
            tracks: snapshot.visibleTracks,
            thumbnailSize: metrics.catalogThumbnailSize,
            thumbnailMaxPixelDimension: metrics.catalogThumbnailMaxPixelDimension,
            currentTrackID: playbackSession.selectedTrack?.id,
            isPlaying: playbackSession.player.isPlaying,
            onPrimaryAction: playTrack,
            onLoadDetail: loadDetail
        )
    }

    private func librarySubtitle(snapshot: BaMusicLibrarySnapshot) -> String {
        if let error = model.catalogState.errorMessage, error.isEmpty == false {
            return String(format: String(localized: "ba.state.error.format"), error)
        }
        if snapshot.playableTracks.isEmpty, snapshot.tracks.isEmpty == false {
            return String(localized: "ba.music.library.loading.subtitle")
        }
        return String(localized: "ba.music.library.subtitle")
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

    private func refreshMusicLibrary() async {
        await model.refreshCatalog(force: true)
        for track in snapshot.visibleTracks.prefix(BaPlatformPerformanceProfile.musicInitialDetailFetchLimit) {
            await model.loadStudentDetail(entry: track.entry, force: true)
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
