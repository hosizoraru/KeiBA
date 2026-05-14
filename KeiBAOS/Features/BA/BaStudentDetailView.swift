//
//  BaStudentDetailView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaStudentDetailView: View {
    let student: BaStudentPreview

    var body: some View {
        List {
            Section {
                studentHeader
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section(String(localized: "ba.student.detail.overview.title")) {
                LabeledContent(String(localized: "ba.student.detail.school.title")) {
                    Text(student.school)
                }

                LabeledContent(String(localized: "ba.student.detail.role.title")) {
                    Text(student.role)
                }
            }

            Section(String(localized: "ba.student.detail.sections.title")) {
                ForEach(BaStudentDetailSection.allCases) { section in
                    DetailSectionRow(section: section)
                }
            }
        }
        .navigationTitle(student.name)
        .platformInsetGroupedListStyle()
        .scrollContentBackground(.hidden)
        .background(AppBackground())
    }

    private var studentHeader: some View {
        BaGlassCard(tint: student.tint) {
            HStack(alignment: .top, spacing: 14) {
                BaSymbolTile(systemImage: student.systemImage, tint: student.tint)

                VStack(alignment: .leading, spacing: 6) {
                    Text(student.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(student.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct DetailSectionRow: View {
    let section: BaStudentDetailSection

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(section.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(section.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        } icon: {
            Image(systemName: section.systemImage)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }
}

#Preview {
    NavigationStack {
        BaStudentDetailView(student: .hoshino)
    }
}
