//
//  StudentsView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct StudentsView: View {
    private let items = StudentFoundationItem.allCases
    private let columns = [
        GridItem(.adaptive(minimum: 148), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                LiquidGlassSurface(cornerRadius: 32, tint: .purple.opacity(0.12)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(String(localized: "students.hero.eyebrow"), systemImage: "person.crop.square.stack.fill")
                            .font(.headline)
                            .foregroundStyle(.purple)

                        Text(String(localized: "students.hero.title"))
                            .font(.title.bold())
                            .foregroundStyle(.primary)

                        Text(String(localized: "students.hero.subtitle"))
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { item in
                        StudentFoundationCard(item: item)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .safeAreaPadding(.bottom, 92)
        }
        .background(AppBackground())
        .navigationTitle(String(localized: "tab.students"))
    }
}

private enum StudentFoundationItem: CaseIterable, Identifiable {
    case profile
    case relationship
    case media
    case catalog

    var id: Self { self }

    var title: String {
        switch self {
        case .profile:
            String(localized: "students.card.profile.title")
        case .relationship:
            String(localized: "students.card.relationship.title")
        case .media:
            String(localized: "students.card.media.title")
        case .catalog:
            String(localized: "students.card.catalog.title")
        }
    }

    var detail: String {
        switch self {
        case .profile:
            String(localized: "students.card.profile.detail")
        case .relationship:
            String(localized: "students.card.relationship.detail")
        case .media:
            String(localized: "students.card.media.detail")
        case .catalog:
            String(localized: "students.card.catalog.detail")
        }
    }

    var systemImage: String {
        switch self {
        case .profile:
            "person.text.rectangle.fill"
        case .relationship:
            "heart.text.square.fill"
        case .media:
            "photo.stack.fill"
        case .catalog:
            "books.vertical.fill"
        }
    }
}

private struct StudentFoundationCard: View {
    let item: StudentFoundationItem

    var body: some View {
        LiquidGlassSurface(cornerRadius: 24, padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16), tint: .indigo.opacity(0.10)) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: item.systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.indigo)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(item.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        }
    }
}

#Preview {
    NavigationStack {
        StudentsView()
    }
}
