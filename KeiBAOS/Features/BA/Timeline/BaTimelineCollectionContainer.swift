//
//  BaTimelineCollectionContainer.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/29.
//

import SwiftUI

#if canImport(UIKit)
    import UIKit

    nonisolated private enum BaTimelineCollectionSection: Hashable {
        case main
    }

    struct BaTimelineCollectionContainer<Item: Hashable, Card: View>: UIViewRepresentable {
        let items: [Item]
        let columnCount: Int
        let spacing: CGFloat
        @Binding var height: CGFloat
        @ViewBuilder var card: (Item) -> Card

        func makeCoordinator() -> Coordinator {
            Coordinator(height: $height, card: card)
        }

        func makeUIView(context: Context) -> UICollectionView {
            let collectionView = UICollectionView(
                frame: .zero,
                collectionViewLayout: Self.makeLayout(columnCount: columnCount, spacing: spacing)
            )
            collectionView.backgroundColor = .clear
            collectionView.isScrollEnabled = false
            collectionView.alwaysBounceVertical = false
            collectionView.contentInsetAdjustmentBehavior = .never
            collectionView.showsVerticalScrollIndicator = false
            collectionView.showsHorizontalScrollIndicator = false
            collectionView.setContentHuggingPriority(.required, for: .vertical)
            collectionView.setContentCompressionResistancePriority(.required, for: .vertical)
            context.coordinator.configureDataSource(collectionView: collectionView)
            return collectionView
        }

        func updateUIView(_ collectionView: UICollectionView, context: Context) {
            context.coordinator.height = $height
            context.coordinator.card = card
            context.coordinator.apply(
                items: items,
                columnCount: columnCount,
                spacing: spacing,
                to: collectionView
            )
        }

        static func dismantleUIView(_ uiView: UICollectionView, coordinator: Coordinator) {
            coordinator.dataSource = nil
            uiView.delegate = nil
        }

        private static func makeLayout(columnCount: Int, spacing: CGFloat) -> UICollectionViewCompositionalLayout {
            UICollectionViewCompositionalLayout { _, _ in
                let columns = max(columnCount, 1)
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(360)
                )
                let subitems = (0 ..< columns).map { _ in
                    NSCollectionLayoutItem(layoutSize: itemSize)
                }

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(360)
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: subitems
                )
                group.interItemSpacing = .fixed(spacing)

                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = spacing
                return section
            }
        }

        final class Coordinator: NSObject {
            var height: Binding<CGFloat>
            var card: (Item) -> Card
            fileprivate var dataSource: UICollectionViewDiffableDataSource<BaTimelineCollectionSection, Item>?

            private var appliedItems: [Item] = []
            private var appliedColumnCount = 0
            private var appliedSpacing: CGFloat = 0
            private var cachedHeight: CGFloat = 0

            init(height: Binding<CGFloat>, card: @escaping (Item) -> Card) {
                self.height = height
                self.card = card
            }

            func configureDataSource(collectionView: UICollectionView) {
                let registration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { [weak self] cell, _, item in
                    guard let self else { return }
                    cell.backgroundConfiguration = .clear()
                    cell.contentConfiguration = UIHostingConfiguration {
                        self.card(item)
                    }
                    .margins(.all, 0)
                    .background {
                        Color.clear
                    }
                }

                dataSource = UICollectionViewDiffableDataSource<BaTimelineCollectionSection, Item>(
                    collectionView: collectionView
                ) { collectionView, indexPath, item in
                    collectionView.dequeueConfiguredReusableCell(
                        using: registration,
                        for: indexPath,
                        item: item
                    )
                }
            }

            func apply(
                items: [Item],
                columnCount: Int,
                spacing: CGFloat,
                to collectionView: UICollectionView
            ) {
                if appliedColumnCount != columnCount || abs(appliedSpacing - spacing) > 0.5 {
                    collectionView.setCollectionViewLayout(
                        BaTimelineCollectionContainer.makeLayout(columnCount: columnCount, spacing: spacing),
                        animated: false
                    )
                    appliedColumnCount = columnCount
                    appliedSpacing = spacing
                }

                guard let dataSource else { return }
                if appliedItems == items {
                    updateHeight(for: collectionView)
                    return
                }

                appliedItems = items
                var snapshot = NSDiffableDataSourceSnapshot<BaTimelineCollectionSection, Item>()
                snapshot.appendSections([.main])
                snapshot.appendItems(items, toSection: .main)
                dataSource.apply(snapshot, animatingDifferences: false) { [weak self, weak collectionView] in
                    guard let self, let collectionView else { return }
                    self.updateHeight(for: collectionView)
                }
            }

            private func updateHeight(for collectionView: UICollectionView) {
                collectionView.collectionViewLayout.invalidateLayout()
                collectionView.layoutIfNeeded()
                let contentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
                guard contentHeight.isFinite, contentHeight > 0 else { return }
                guard abs(cachedHeight - contentHeight) > 1 else { return }
                cachedHeight = contentHeight

                let rounded = contentHeight.rounded(.up)
                guard abs(height.wrappedValue - rounded) > 1 else { return }
                height.wrappedValue = rounded
            }
        }
    }
#endif
