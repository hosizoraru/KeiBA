//
//  GameKeeClient.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

struct GameKeeRequest: Hashable, Sendable {
    let pathOrURL: String
    let refererPath: String
    var extraHeaders: [String: String] = [:]
}

enum GameKeeError: LocalizedError, Sendable {
    case invalidURL(String)
    case invalidResponse(String)
    case httpStatus(Int)
    case emptyBody
    case apiCode(Int)

    var errorDescription: String? {
        switch self {
        case let .invalidURL(value):
            "Invalid URL: \(value)"
        case let .invalidResponse(value):
            "Invalid response: \(value)"
        case let .httpStatus(code):
            "HTTP \(code)"
        case .emptyBody:
            "Empty response"
        case let .apiCode(code):
            "GameKee API code \(code)"
        }
    }
}

struct GameKeeClient: @unchecked Sendable {
    static let baseURL = URL(string: "https://www.gamekee.com")!
    nonisolated static let safariUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1"
    nonisolated static let firefoxAndroidUserAgent = "Mozilla/5.0 (Android 15; Mobile; rv:140.0) Gecko/140.0 Firefox/140.0"
    nonisolated static let requestUserAgents = [firefoxAndroidUserAgent, safariUserAgent]
    nonisolated static let mediaRetryUserAgents = [firefoxAndroidUserAgent, safariUserAgent]

    private let session: URLSession
    private let retryAttempts: Int
    private nonisolated static let defaultSession = makeSession()

    nonisolated init(
        session: URLSession = GameKeeClient.defaultSession,
        retryAttempts: Int = 2
    ) {
        self.session = session
        self.retryAttempts = max(retryAttempts, 1)
    }

    func fetchJSONData(_ request: GameKeeRequest) async throws -> Data {
        try await fetchData(
            request,
            acceptHeader: "application/json, text/plain, */*",
            requireJSONBody: true
        )
    }

    func fetchHTML(_ request: GameKeeRequest) async throws -> String {
        let data = try await fetchData(
            request,
            acceptHeader: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            requireJSONBody: false
        )
        return String(decoding: data, as: UTF8.self)
    }

    func fetchImageData(url: URL, refererPath: String = "/ba") async throws -> Data {
        let request = GameKeeRequest(pathOrURL: url.absoluteString, refererPath: refererPath)
        var lastError: Error?
        for userAgent in Self.mediaRetryUserAgents {
            do {
                return try await executeImage(request, userAgent: userAgent)
            } catch {
                lastError = error
            }
        }
        throw lastError ?? GameKeeError.emptyBody
    }

    func fetchAudioData(url: URL, refererPath: String = "/ba") async throws -> Data {
        let request = GameKeeRequest(pathOrURL: url.absoluteString, refererPath: refererPath)
        var lastError: Error?
        for userAgent in Self.mediaRetryUserAgents {
            do {
                return try await executeAudio(request, userAgent: userAgent)
            } catch {
                lastError = error
            }
        }
        throw lastError ?? GameKeeError.emptyBody
    }

    func fetchMediaData(url: URL, refererPath: String = "/ba") async throws -> Data {
        let request = GameKeeRequest(pathOrURL: url.absoluteString, refererPath: refererPath)
        var lastError: Error?
        for userAgent in Self.mediaRetryUserAgents {
            do {
                return try await executeMedia(request, userAgent: userAgent)
            } catch {
                lastError = error
            }
        }
        throw lastError ?? GameKeeError.emptyBody
    }

    nonisolated var imageRetryUserAgents: [String] {
        Self.mediaRetryUserAgents
    }

    nonisolated func resolvedReferer(pathOrURL: String, refererPath: String) -> String {
        resolveReferer(pathOrURL: pathOrURL, refererPath: refererPath)
    }

    private func fetchData(
        _ request: GameKeeRequest,
        acceptHeader: String,
        requireJSONBody: Bool
    ) async throws -> Data {
        var lastError: Error?
        let userAgents = Self.requestUserAgents
        for attempt in 0 ..< retryAttempts {
            for userAgent in userAgents {
                do {
                    return try await execute(
                        request,
                        acceptHeader: acceptHeader,
                        requireJSONBody: requireJSONBody,
                        userAgent: userAgent
                    )
                } catch {
                    lastError = error
                }
            }
            if attempt < retryAttempts - 1 {
                try? await Task.sleep(for: .milliseconds(300))
            }
        }
        throw lastError ?? GameKeeError.emptyBody
    }

    private func execute(
        _ request: GameKeeRequest,
        acceptHeader: String,
        requireJSONBody: Bool,
        userAgent: String
    ) async throws -> Data {
        guard let url = normalizedURL(request.pathOrURL) else {
            throw GameKeeError.invalidURL(request.pathOrURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 12
        urlRequest.cachePolicy = .reloadRevalidatingCacheData
        urlRequest.setValue(acceptHeader, forHTTPHeaderField: "Accept")
        urlRequest.setValue("zh-CN", forHTTPHeaderField: "Accept-Language")
        urlRequest.setValue(resolveReferer(pathOrURL: request.pathOrURL, refererPath: request.refererPath), forHTTPHeaderField: "Referer")
        urlRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        for (key, value) in request.extraHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GameKeeError.invalidResponse(response.description)
        }
        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            throw GameKeeError.httpStatus(httpResponse.statusCode)
        }
        guard data.isEmpty == false else {
            throw GameKeeError.emptyBody
        }
        if requireJSONBody, isJSONLike(data) == false {
            throw GameKeeError.invalidResponse(String(decoding: data.prefix(120), as: UTF8.self))
        }
        return data
    }

    private func executeImage(_ request: GameKeeRequest, userAgent: String) async throws -> Data {
        guard let url = normalizedURL(request.pathOrURL) else {
            throw GameKeeError.invalidURL(request.pathOrURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 12
        urlRequest.cachePolicy = .reloadRevalidatingCacheData
        urlRequest.setValue("image/*,*/*", forHTTPHeaderField: "Accept")
        urlRequest.setValue("zh-CN", forHTTPHeaderField: "Accept-Language")
        urlRequest.setValue(resolveReferer(pathOrURL: request.pathOrURL, refererPath: request.refererPath), forHTTPHeaderField: "Referer")
        urlRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        for (key, value) in request.extraHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GameKeeError.invalidResponse(response.description)
        }
        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            throw GameKeeError.httpStatus(httpResponse.statusCode)
        }
        guard data.isEmpty == false else {
            throw GameKeeError.emptyBody
        }
        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
        guard contentType.contains("image") || looksLikeImageData(data) else {
            let preview = String(decoding: data.prefix(120), as: UTF8.self)
            throw GameKeeError.invalidResponse(preview)
        }
        return data
    }

    private func executeAudio(_ request: GameKeeRequest, userAgent: String) async throws -> Data {
        guard let url = normalizedURL(request.pathOrURL) else {
            throw GameKeeError.invalidURL(request.pathOrURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 18
        urlRequest.cachePolicy = .reloadRevalidatingCacheData
        let mediaHeaders = Self.mediaPlaybackHeaders(
            for: url,
            referer: resolveReferer(pathOrURL: request.pathOrURL, refererPath: request.refererPath)
        )
        for (key, value) in mediaHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        urlRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        for (key, value) in request.extraHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GameKeeError.invalidResponse(response.description)
        }
        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            throw GameKeeError.httpStatus(httpResponse.statusCode)
        }
        guard data.isEmpty == false else {
            throw GameKeeError.emptyBody
        }
        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
        guard contentType.contains("audio") ||
            (contentType.contains("octet-stream") && looksLikeAudioData(data)) ||
            looksLikeAudioData(data)
        else {
            let preview = String(decoding: data.prefix(120), as: UTF8.self)
            throw GameKeeError.invalidResponse(preview)
        }
        return data
    }

    private func executeMedia(_ request: GameKeeRequest, userAgent: String) async throws -> Data {
        guard let url = normalizedURL(request.pathOrURL) else {
            throw GameKeeError.invalidURL(request.pathOrURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 24
        urlRequest.cachePolicy = .reloadRevalidatingCacheData
        let mediaHeaders = Self.mediaPlaybackHeaders(
            for: url,
            referer: resolveReferer(pathOrURL: request.pathOrURL, refererPath: request.refererPath)
        )
        for (key, value) in mediaHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        urlRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        for (key, value) in request.extraHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GameKeeError.invalidResponse(response.description)
        }
        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            throw GameKeeError.httpStatus(httpResponse.statusCode)
        }
        guard data.isEmpty == false else {
            throw GameKeeError.emptyBody
        }
        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
        guard Self.isRenderableMediaContentType(contentType) || Self.looksLikeRenderableMediaData(data) else {
            let preview = String(decoding: data.prefix(120), as: UTF8.self)
            throw GameKeeError.invalidResponse(preview)
        }
        return data
    }

    private func normalizedURL(_ pathOrURL: String) -> URL? {
        let raw = pathOrURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("http://") {
            return URL(string: raw.replacingOccurrences(of: "http://", with: "https://", options: [.anchored, .caseInsensitive]))
        }
        if raw.hasPrefix("https://") {
            return URL(string: raw)
        }
        if raw.hasPrefix("//") {
            return URL(string: "https:\(raw)")
        }
        if raw.hasPrefix("/") {
            return URL(string: raw, relativeTo: Self.baseURL)?.absoluteURL
        }
        return URL(string: "/\(raw)", relativeTo: Self.baseURL)?.absoluteURL
    }

    private nonisolated func resolveReferer(pathOrURL: String, refererPath: String) -> String {
        let requestHint = pathHint(pathOrURL).lowercased()
        let refererHint = pathHint(refererPath).lowercased()
        let merged = "\(requestHint) \(refererHint)"
        let requestHost = hostHint(pathOrURL)
        let refererHost = hostHint(refererPath)
        let effectiveHost = requestHost.isEmpty ? refererHost : requestHost
        if effectiveHost.hasSuffix("gamekee.com"), effectiveHost != "www.gamekee.com" {
            return "https://www.gamekee.com/"
        }
        if let detailId = detailContentID(requestHint) ?? detailContentID(refererHint) {
            return "https://www.gamekee.com/ba/tj/\(detailId).html"
        }
        if let referer = normalizedReferer(refererPath) {
            return referer
        }
        if merged.contains("/ba/huodong") {
            return "https://www.gamekee.com/ba/huodong/15"
        }
        if merged.contains("/ba/kachi") {
            return "https://www.gamekee.com/ba/kachi/15"
        }
        return "https://www.gamekee.com/ba"
    }

    private nonisolated func pathHint(_ pathOrURL: String) -> String {
        let raw = pathOrURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard raw.isEmpty == false else { return "" }
        if let url = URL(string: raw), let host = url.host, host.isEmpty == false {
            var path = url.path
            if let query = url.query, query.isEmpty == false {
                path += "?\(query)"
            }
            return path
        }
        if raw.hasPrefix("//"), let url = URL(string: "https:\(raw)") {
            return url.path
        }
        return raw.hasPrefix("/") ? raw : "/\(raw)"
    }

    private nonisolated func hostHint(_ pathOrURL: String) -> String {
        let raw = pathOrURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard raw.isEmpty == false else { return "" }
        if let url = URL(string: raw), let host = url.host, host.isEmpty == false {
            return host.lowercased()
        }
        if raw.hasPrefix("//"), let url = URL(string: "https:\(raw)"), let host = url.host {
            return host.lowercased()
        }
        return ""
    }

    private nonisolated func normalizedReferer(_ refererPath: String) -> String? {
        let raw = refererPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard raw.isEmpty == false else { return nil }
        if raw.hasPrefix("http://") {
            return raw.replacingOccurrences(of: "http://", with: "https://", options: [.anchored, .caseInsensitive])
        }
        if raw.hasPrefix("https://") {
            return raw
        }
        if raw.hasPrefix("//") {
            return "https:\(raw)"
        }
        if raw.hasPrefix("/") {
            return "https://www.gamekee.com\(raw)"
        }
        return "https://www.gamekee.com/\(raw)"
    }

    private nonisolated func detailContentID(_ hint: String) -> String? {
        if let range = hint.range(of: #"/v1/content/detail/(\d+)"#, options: .regularExpression) {
            return String(hint[range]).split(separator: "/").last.map(String.init)
        }
        if let range = hint.range(of: #"/ba/tj/(\d+)\.html"#, options: .regularExpression) {
            let matched = String(hint[range])
            return matched
                .replacingOccurrences(of: "/ba/tj/", with: "")
                .replacingOccurrences(of: ".html", with: "")
        }
        return nil
    }

    private func isJSONLike(_ data: Data) -> Bool {
        var index = data.startIndex
        if data.count >= 3,
           data[index] == 0xEF,
           data[data.index(after: index)] == 0xBB,
           data[data.index(index, offsetBy: 2)] == 0xBF
        {
            index = data.index(index, offsetBy: 3)
        }
        while index < data.endIndex {
            switch data[index] {
            case 0x09, 0x0A, 0x0D, 0x20:
                index = data.index(after: index)
            case 0x7B, 0x5B:
                return true
            default:
                return false
            }
        }
        return false
    }

    private func looksLikeImageData(_ data: Data) -> Bool {
        let bytes = [UInt8](data.prefix(16))
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) { return true }
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return true }
        if bytes.starts(with: [0x47, 0x49, 0x46]) { return true }
        if bytes.count >= 12,
           bytes[0 ..< 4].elementsEqual([0x52, 0x49, 0x46, 0x46]),
           bytes[8 ..< 12].elementsEqual([0x57, 0x45, 0x42, 0x50])
        {
            return true
        }
        if let head = String(data: data.prefix(128), encoding: .utf8) {
            return head.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<svg")
        }
        return false
    }

    private func looksLikeAudioData(_ data: Data) -> Bool {
        let bytes = [UInt8](data.prefix(16))
        if bytes.starts(with: [0x49, 0x44, 0x33]) { return true }
        if bytes.count >= 2, bytes[0] == 0xFF, (bytes[1] & 0xE0) == 0xE0 { return true }
        if bytes.starts(with: [0x4F, 0x67, 0x67, 0x53]) { return true }
        if bytes.starts(with: [0x66, 0x4C, 0x61, 0x43]) { return true }
        if bytes.count >= 12,
           bytes[0 ..< 4].elementsEqual([0x52, 0x49, 0x46, 0x46]),
           bytes[8 ..< 12].elementsEqual([0x57, 0x41, 0x56, 0x45])
        {
            return true
        }
        if bytes.count >= 8,
           bytes[4 ..< 8].elementsEqual([0x66, 0x74, 0x79, 0x70])
        {
            return true
        }
        return false
    }

    private nonisolated static func isRenderableMediaContentType(_ contentType: String) -> Bool {
        contentType.contains("image") ||
            contentType.contains("audio") ||
            contentType.contains("video") ||
            contentType.contains("application/octet-stream") ||
            contentType.contains("application/vnd.apple.mpegurl") ||
            contentType.contains("application/x-mpegurl")
    }

    private nonisolated static func looksLikeRenderableMediaData(_ data: Data) -> Bool {
        let bytes = [UInt8](data.prefix(16))
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) { return true }
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return true }
        if bytes.starts(with: [0x47, 0x49, 0x46]) { return true }
        if bytes.starts(with: [0x49, 0x44, 0x33]) { return true }
        if bytes.count >= 2, bytes[0] == 0xFF, (bytes[1] & 0xE0) == 0xE0 { return true }
        if bytes.starts(with: [0x4F, 0x67, 0x67, 0x53]) { return true }
        if bytes.starts(with: [0x66, 0x4C, 0x61, 0x43]) { return true }
        if bytes.count >= 8,
           bytes[4 ..< 8].elementsEqual([0x66, 0x74, 0x79, 0x70])
        {
            return true
        }
        if bytes.count >= 12,
           bytes[0 ..< 4].elementsEqual([0x52, 0x49, 0x46, 0x46])
        {
            return bytes[8 ..< 12].elementsEqual([0x57, 0x45, 0x42, 0x50]) ||
                bytes[8 ..< 12].elementsEqual([0x57, 0x41, 0x56, 0x45])
        }
        if bytes.starts(with: [0x1A, 0x45, 0xDF, 0xA3]) { return true }
        guard let head = String(data: data.prefix(128), encoding: .utf8) else {
            return false
        }
        let trimmed = head.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.hasPrefix("<svg") || trimmed.hasPrefix("#extm3u")
    }

    nonisolated static func httpCacheDirectory(fileManager: FileManager = .default) -> URL {
        let baseDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseDirectory.appendingPathComponent("ba_gamekee_http_cache", isDirectory: true)
    }

    private nonisolated static func makeSession() -> URLSession {
        let cacheDirectory = httpCacheDirectory()
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        let cache = URLCache(
            memoryCapacity: 16 * 1024 * 1024,
            diskCapacity: 64 * 1024 * 1024,
            directory: cacheDirectory
        )
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 20
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .reloadRevalidatingCacheData
        configuration.urlCache = cache
        return URLSession(configuration: configuration)
    }
}

extension GameKeeClient {
    static var baHeaders: [String: String] {
        [
            "device-num": "1",
            "game-alias": "ba",
        ]
    }

    nonisolated static func mediaPlaybackHeaders(
        for _: URL,
        referer: String = "https://www.gamekee.com/"
    ) -> [String: String] {
        [
            "Accept": "*/*",
            "Accept-Language": "zh-CN",
            "Referer": referer,
            "Origin": "https://www.gamekee.com",
            "User-Agent": firefoxAndroidUserAgent,
            "device-num": "1",
            "game-alias": "ba",
        ]
    }
}
