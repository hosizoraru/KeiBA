//
//  BaOggVorbisDecoder.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import AVFoundation
import AudioCodecs
import Foundation

nonisolated struct BaDecodedOggAudio: @unchecked Sendable {
    let buffer: AVAudioPCMBuffer
    let duration: TimeInterval
}

nonisolated struct BaOggVorbisDecoder: Sendable {
    private let chunkFrames = 4096

    func decode(localURL: URL) throws -> BaDecodedOggAudio {
        try decode(data: Data(contentsOf: localURL))
    }

    func decode(data: Data) throws -> BaDecodedOggAudio {
        guard data.isEmpty == false else {
            throw DecodeError.emptyData
        }

        guard let stream = VFStreamCreate(max(data.count + 1, 65_536)) else {
            throw DecodeError.streamCreateFailed
        }
        defer {
            VFStreamDestroy(stream)
        }

        data.withUnsafeBytes { rawBuffer in
            if let base = rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) {
                VFStreamPush(stream, base, data.count)
            }
        }
        VFStreamMarkEOF(stream)

        var file: VFFileRef?
        let openStatus = VFOpen(stream, &file)
        guard openStatus >= 0, let file else {
            throw DecodeError.openFailed(Int(openStatus))
        }
        defer {
            VFClear(file)
        }

        var info = VFStreamInfo()
        guard VFGetInfo(file, &info) == 0,
              info.sample_rate > 0,
              info.channels > 0
        else {
            throw DecodeError.infoFailed
        }

        let channelCount = Int(info.channels)
        var channels = Array(repeating: [Float](), count: channelCount)
        let frameHint = Int(max(info.total_pcm_samples, 0))
        if frameHint > 0 {
            for index in channels.indices {
                channels[index].reserveCapacity(frameHint)
            }
        }

        while true {
            var pcmChannels: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>?
            let framesRead = Int(VFReadFloat(file, &pcmChannels, Int32(chunkFrames)))
            if framesRead == 0 {
                break
            }
            guard framesRead > 0, let pcmChannels else {
                throw DecodeError.readFailed(framesRead)
            }

            for channel in channels.indices {
                guard let source = pcmChannels[channel] else { continue }
                channels[channel].append(contentsOf: UnsafeBufferPointer(start: source, count: framesRead))
            }
        }

        let frameCount = channels.map(\.count).max() ?? 0
        guard frameCount > 0 else {
            throw DecodeError.emptyPcm
        }

        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: Double(info.sample_rate),
            channels: AVAudioChannelCount(channelCount)
        ),
            let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(frameCount)
            ),
            let outputChannels = buffer.floatChannelData
        else {
            throw DecodeError.formatFailed
        }

        buffer.frameLength = AVAudioFrameCount(frameCount)
        for channel in channels.indices {
            let output = outputChannels[channel]
            let values = channels[channel]
            values.withUnsafeBufferPointer { source in
                if let base = source.baseAddress {
                    output.update(from: base, count: values.count)
                }
            }
            if values.count < frameCount {
                for frame in values.count ..< frameCount {
                    output[frame] = 0
                }
            }
        }

        return BaDecodedOggAudio(
            buffer: buffer,
            duration: Double(frameCount) / Double(info.sample_rate)
        )
    }

    enum DecodeError: LocalizedError {
        case emptyData
        case streamCreateFailed
        case openFailed(Int)
        case infoFailed
        case readFailed(Int)
        case emptyPcm
        case formatFailed

        var errorDescription: String? {
            switch self {
            case .emptyData:
                "Empty Ogg Vorbis data"
            case .streamCreateFailed:
                "Unable to create Ogg Vorbis stream"
            case let .openFailed(status):
                "Unable to open Ogg Vorbis stream (\(status))"
            case .infoFailed:
                "Unable to read Ogg Vorbis stream info"
            case let .readFailed(status):
                "Unable to decode Ogg Vorbis frames (\(status))"
            case .emptyPcm:
                "Ogg Vorbis stream contained no PCM frames"
            case .formatFailed:
                "Unable to create PCM buffer"
            }
        }
    }
}
