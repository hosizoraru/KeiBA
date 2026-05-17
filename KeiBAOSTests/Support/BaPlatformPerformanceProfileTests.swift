//
//  BaPlatformPerformanceProfileTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/17.
//

@testable import KeiBAOS
import XCTest

final class BaPlatformPerformanceProfileTests: XCTestCase {
    func testPerformanceProfileScalesWorkByPlatformClass() {
        XCTAssertEqual(BaPlatformPerformanceProfile.musicDetailPrefetchConcurrency(for: .phone), 2)
        XCTAssertEqual(BaPlatformPerformanceProfile.musicDetailPrefetchConcurrency(for: .pad), 4)
        XCTAssertEqual(BaPlatformPerformanceProfile.musicDetailPrefetchConcurrency(for: .desktop), 6)
        XCTAssertEqual(BaPlatformPerformanceProfile.musicDetailPrefetchConcurrency(for: .watch), 1)

        XCTAssertLessThan(
            BaPlatformPerformanceProfile.musicCacheConcurrency(for: .phone),
            BaPlatformPerformanceProfile.musicCacheConcurrency(for: .desktop)
        )
        XCTAssertLessThan(
            BaPlatformPerformanceProfile.musicProgressUpdateInterval(for: .desktop),
            BaPlatformPerformanceProfile.musicProgressUpdateInterval(for: .phone)
        )
        XCTAssertLessThan(
            BaPlatformPerformanceProfile.overviewStartupNetworkDelay(for: .desktop),
            BaPlatformPerformanceProfile.overviewStartupNetworkDelay(for: .phone)
        )
        XCTAssertLessThan(
            BaPlatformPerformanceProfile.notificationStartupRefreshDelay(for: .desktop),
            BaPlatformPerformanceProfile.notificationStartupRefreshDelay(for: .phone)
        )
        XCTAssertLessThan(
            BaPlatformPerformanceProfile.notificationTimelineRefreshDelay(for: .desktop),
            BaPlatformPerformanceProfile.notificationTimelineRefreshDelay(for: .phone)
        )
        XCTAssertFalse(BaPlatformPerformanceProfile.musicSamplesRowAvatarAccent(for: .phone))
        XCTAssertTrue(BaPlatformPerformanceProfile.musicSamplesRowAvatarAccent(for: .pad))
    }

    func testBoundedTaskGroupCapsConcurrentOperations() async {
        let counter = TaskConcurrencyCounter()

        await BaBoundedTaskGroup.run(
            Array(0 ..< 12),
            maxConcurrentTasks: 3,
            priority: .utility
        ) { _ in
            await counter.start()
            try? await Task.sleep(for: .milliseconds(20))
            await counter.finish()
        }

        let maxActiveCount = await counter.maxActiveCount
        XCTAssertEqual(maxActiveCount, 3)
    }
}

private actor TaskConcurrencyCounter {
    private var activeCount = 0
    private(set) var maxActiveCount = 0

    func start() {
        activeCount += 1
        maxActiveCount = max(maxActiveCount, activeCount)
    }

    func finish() {
        activeCount -= 1
    }
}
