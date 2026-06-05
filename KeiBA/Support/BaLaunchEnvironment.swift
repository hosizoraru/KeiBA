//
//  BaLaunchEnvironment.swift
//  KeiBA
//
//  Created by Codex on 2026/05/19.
//

import Foundation

enum BaLaunchEnvironment {
    static var isRunningUnitTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        if environment["KEIBA_XCTEST_HOST"] == "1" {
            return true
        }
        if environment["XCTestConfigurationFilePath"] != nil ||
            environment["XCTestBundlePath"] != nil
        {
            return true
        }
        if [
            "SIMULATOR_SHARED_RESOURCES_DIRECTORY",
            "CFFIXED_USER_HOME",
            "HOME",
            "TMPDIR"
        ].contains(where: { environment[$0]?.contains("/XCTestDevices/") == true }) {
            return true
        }
        return ProcessInfo.processInfo.arguments.contains { argument in
            argument.localizedCaseInsensitiveContains("xctest")
        }
    }
}
