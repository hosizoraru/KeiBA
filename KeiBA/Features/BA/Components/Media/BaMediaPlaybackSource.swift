//
//  BaMediaPlaybackSource.swift
//  KeiBA
//
//  Created by Codex on 2026/05/16.
//

import AVFoundation
import Foundation

enum BaMediaPlaybackSource {
    static func requiresRemotePlayback(_ url: URL) -> Bool {
        let value = url.absoluteString.lowercased()
        return url.pathExtension.lowercased() == "m3u8" || value.contains(".m3u8")
    }

    static func remotePlayerItem(for url: URL, refererPath: String = "/ba") -> AVPlayerItem {
        let client = GameKeeClient()
        let referer = client.resolvedReferer(pathOrURL: url.absoluteString, refererPath: refererPath)
        let headers = GameKeeClient.mediaPlaybackHeaders(for: url, referer: referer)
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        return AVPlayerItem(asset: asset)
    }
}
