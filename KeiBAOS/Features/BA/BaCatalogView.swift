//
//  BaCatalogView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaCatalogView: View {
    @State private var selectedCategory: BaCatalogCategory = .students
    @State private var searchText = ""

    private let students = BaStudentPreview.previewStudents
    private let favorites = BaStudentPreview.favoriteStudents
    private let npcEntries = BaCatalogInfoEntry.npcSatellitePreview
    private let bgmEntries = BaCatalogInfoEntry.bgmPreview

    var body: some View {
        List {
            Section {
                Picker(String(localized: "ba.catalog.category.picker"), selection: $selectedCategory) {
                    ForEach(BaCatalogCategory.allCases) { category in
                        Text(category.title)
                            .tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
            }

            Section {
                categoryContent
            } header: {
                Text(selectedCategory.title)
            } footer: {
                Text(categoryFooter)
            }
        }
        .platformInsetGroupedListStyle()
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .searchable(text: $searchText, prompt: Text(selectedCategory.searchPrompt))
    }

    @ViewBuilder
    private var categoryContent: some View {
        switch selectedCategory {
        case .students:
            studentRows(students)
        case .npcSatellite:
            infoRows(filteredInfoEntries(npcEntries))
        case .studentBgm:
            infoRows(filteredInfoEntries(bgmEntries))
        case .favorites:
            studentRows(favorites)
        }
    }

    private var categoryFooter: String {
        switch selectedCategory {
        case .students:
            String(localized: "ba.catalog.footer.students")
        case .npcSatellite:
            String(localized: "ba.catalog.footer.npc")
        case .studentBgm:
            String(localized: "ba.catalog.footer.bgm")
        case .favorites:
            String(localized: "ba.catalog.footer.favorites")
        }
    }

    @ViewBuilder
    private func studentRows(_ source: [BaStudentPreview]) -> some View {
        let matches = filteredStudents(source)
        if matches.isEmpty {
            ContentUnavailableView(
                String(localized: "ba.catalog.empty.title"),
                systemImage: "magnifyingglass",
                description: Text(String(localized: "ba.catalog.empty.detail"))
            )
        } else {
            ForEach(matches) { student in
                NavigationLink {
                    BaStudentDetailView(student: student)
                } label: {
                    BaStudentRow(student: student)
                }
            }
        }
    }

    @ViewBuilder
    private func infoRows(_ source: [BaCatalogInfoEntry]) -> some View {
        if source.isEmpty {
            ContentUnavailableView(
                String(localized: "ba.catalog.empty.title"),
                systemImage: "magnifyingglass",
                description: Text(String(localized: "ba.catalog.empty.detail"))
            )
        } else {
            ForEach(source) { entry in
                NavigationLink {
                    BaCatalogPlaceholderDetail(entry: entry)
                } label: {
                    BaCatalogInfoRow(entry: entry)
                }
            }
        }
    }

    private func filteredStudents(_ source: [BaStudentPreview]) -> [BaStudentPreview] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return source }

        return source.filter { student in
            student.name.localizedCaseInsensitiveContains(query) ||
            student.school.localizedCaseInsensitiveContains(query) ||
            student.role.localizedCaseInsensitiveContains(query) ||
            student.summary.localizedCaseInsensitiveContains(query)
        }
    }

    private func filteredInfoEntries(_ source: [BaCatalogInfoEntry]) -> [BaCatalogInfoEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return source }

        return source.filter { entry in
            entry.title.localizedCaseInsensitiveContains(query) ||
            entry.detail.localizedCaseInsensitiveContains(query)
        }
    }
}

private struct BaStudentRow: View {
    let student: BaStudentPreview

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(student.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(
                    String(
                        format: String(localized: "ba.catalog.student.subtitle.format"),
                        student.school,
                        student.role
                    )
                )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(student.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        } icon: {
            Image(systemName: student.systemImage)
                .foregroundStyle(student.tint)
        }
        .padding(.vertical, 4)
    }
}

private struct BaCatalogInfoEntry: Identifiable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color

    static var npcSatellitePreview: [BaCatalogInfoEntry] {
        [
            BaCatalogInfoEntry(
                id: "arona",
                title: String(localized: "ba.catalog.npc.arona.title"),
                detail: String(localized: "ba.catalog.npc.arona.detail"),
                systemImage: "person.crop.circle.badge.questionmark.fill",
                tint: BaDesign.blue
            ),
            BaCatalogInfoEntry(
                id: "seia",
                title: String(localized: "ba.catalog.satellite.seia.title"),
                detail: String(localized: "ba.catalog.satellite.seia.detail"),
                systemImage: "sparkles.rectangle.stack.fill",
                tint: BaDesign.violet
            )
        ]
    }

    static var bgmPreview: [BaCatalogInfoEntry] {
        [
            BaCatalogInfoEntry(
                id: "hoshino-bgm",
                title: String(localized: "ba.catalog.bgm.hoshino.title"),
                detail: String(localized: "ba.catalog.bgm.hoshino.detail"),
                systemImage: "music.note",
                tint: BaDesign.amber
            ),
            BaCatalogInfoEntry(
                id: "shiroko-bgm",
                title: String(localized: "ba.catalog.bgm.shiroko.title"),
                detail: String(localized: "ba.catalog.bgm.shiroko.detail"),
                systemImage: "music.quarternote.3",
                tint: BaDesign.cyan
            )
        ]
    }
}

private struct BaCatalogInfoRow: View {
    let entry: BaCatalogInfoEntry

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(entry.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        } icon: {
            Image(systemName: entry.systemImage)
                .foregroundStyle(entry.tint)
        }
        .padding(.vertical, 4)
    }
}

private struct BaCatalogPlaceholderDetail: View {
    let entry: BaCatalogInfoEntry

    var body: some View {
        List {
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.title)
                            .font(.headline)

                        Text(entry.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    BaSymbolTile(systemImage: entry.systemImage, tint: entry.tint)
                }
            } footer: {
                Text(String(localized: "ba.catalog.placeholder.footer"))
            }
        }
        .navigationTitle(entry.title)
        .platformInsetGroupedListStyle()
        .scrollContentBackground(.hidden)
        .background(AppBackground())
    }
}

#Preview {
    NavigationStack {
        BaCatalogView()
            .navigationTitle(AppTab.catalog.title)
    }
}
