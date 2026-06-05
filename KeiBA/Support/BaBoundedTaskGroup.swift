//
//  BaBoundedTaskGroup.swift
//  KeiBA
//
//  Created by Codex on 2026/05/17.
//

import Foundation

enum BaBoundedTaskGroup {
    nonisolated static func run<Element: Sendable>(
        _ elements: [Element],
        maxConcurrentTasks: Int,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable (Element) async -> Void
    ) async {
        let limit = max(maxConcurrentTasks, 1)
        guard elements.isEmpty == false else { return }

        await withTaskGroup(of: Void.self) { group in
            var nextIndex = 0

            func enqueueNext() {
                guard nextIndex < elements.count else { return }
                let element = elements[nextIndex]
                nextIndex += 1
                group.addTask(priority: priority) {
                    await operation(element)
                }
            }

            for _ in 0 ..< min(limit, elements.count) {
                enqueueNext()
            }

            while await group.next() != nil {
                enqueueNext()
            }
        }
    }
}
