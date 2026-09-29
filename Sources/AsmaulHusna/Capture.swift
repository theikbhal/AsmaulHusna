import SwiftUI
import ScreenCaptureKit
import AVFoundation
import CoreMedia

// MARK: - PNG capture (ImageRenderer, no screen permission needed)

enum Capture {
    static func stamp() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd-HHmmss"
        return f.string(from: Date())
    }

    static func desktopURL(_ name: String) -> URL {
        FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
    }

    static func shareFolder() -> URL {
        let url = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AsmaulHusna-Exports", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @MainActor
    static func png<V: View>(_ view: V, width: CGFloat, height: CGFloat, to url: URL) -> Bool {
        let renderer = ImageRenderer(content: view.frame(width: width, height: height))
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:]) else { return false }
        return (try? data.write(to: url)) != nil
    }
}

// MARK: - Instagram exports

@MainActor
enum ShareExport {
    enum Size {
        static let post = (w: CGFloat(1080), h: CGFloat(1350))     // 4:5 feed post
        static let story = (w: CGFloat(1080), h: CGFloat(1920))    // 9:16 story / reel cover
        static let square = (w: CGFloat(1080), h: CGFloat(1080))   // 1:1
    }

    static func post(_ h: Husna, _ settings: AppSettings) -> URL? {
        let url = Capture.shareFolder().appendingPathComponent("post-\(h.id)-\(Capture.stamp()).png")
        let view = ShareCard(husna: h, style: .post)
            .environmentObject(settings)
            .environmentObject(ReadStore.shared)
        return Capture.png(view, width: Size.post.w, height: Size.post.h, to: url) ? url : nil
    }

    static func story(_ h: Husna, _ settings: AppSettings) -> URL? {
        let url = Capture.shareFolder().appendingPathComponent("story-\(h.id)-\(Capture.stamp()).png")
        let view = ShareCard(husna: h, style: .story)
            .environmentObject(settings)
            .environmentObject(ReadStore.shared)
        return Capture.png(view, width: Size.story.w, height: Size.story.h, to: url) ? url : nil
    }

    /// Multi-card carousel: one PNG per name, plus an index card.
    static func carousel(_ list: [Husna], _ settings: AppSettings) -> [URL] {
        var out: [URL] = []
        let folder = Capture.shareFolder().appendingPathComponent("carousel-\(Capture.stamp())", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for (i, h) in list.enumerated() {
            let view = ShareCard(husna: h, style: .post, index: i + 1, total: list.count)
                .environmentObject(settings)
                .environmentObject(ReadStore.shared)
            let url = folder.appendingPathComponent("\(String(format: "%02d", i + 1))-name-\(h.id).png")
            if Capture.png(view, width: Size.post.w, height: Size.post.h, to: url) { out.append(url) }
        }
        let readme = """
        Asmaul Husna carousel — \(list.count) cards, 1080x1350 PNG.
        Upload in order (01…\(String(format: "%02d", list.count))) as an Instagram carousel.
        Generated \(Capture.stamp()).
        """
        try? readme.write(to: folder.appendingPathComponent("README.txt"), atomically: true, encoding: .utf8)
        return out
    }

    /// Renders portrait frames and encodes them into an MP4 (optionally with an audio track).
    static func reel(_ list: [Husna], audio: URL?, secondsPerCard: Double,
                     _ settings: AppSettings) async throws -> URL {
        let out = Capture.shareFolder().appendingPathComponent("reel-\(Capture.stamp()).mp4")
        var frames: [CGImage] = []
        for (i, h) in list.enumerated() {
            let view = ShareCard(husna: h, style: .story, index: i + 1, total: list.count)
                .environmentObject(settings)
                .environmentObject(ReadStore.shared)
            let url = Capture.shareFolder().appendingPathComponent(".frame-\(i)-\(Capture.stamp()).png")
            guard Capture.png(view, width: Size.story.w, height: Size.story.h, to: url),
                  let img = NSImage(contentsOf: url) ?? nil,
                  let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { continue }
            frames.append(cg)
            try? FileManager.default.removeItem(at: url)
        }
        guard !frames.isEmpty else { throw ShareError.noFrames }

        let duration = CMTime(seconds: secondsPerCard, preferredTimescale: 600)
        try await VideoEncoder.encode(frames: frames, frameDuration: duration, audio: audio, to: out)
        return out
    }

    enum ShareError: LocalizedError {
        case noFrames, encodeFailed(String)
        var errorDescription: String? {
            switch self {
            case .noFrames: return "Could not render any cards."
            case .encodeFailed(let m): return "Video encoding failed: \(m)"
            }
        }
    }
}

// MARK: - H.264 frame encoder with optional audio track

enum VideoEncoder {
    @MainActor
    static func encode(frames: [CGImage], frameDuration: CMTime, audio: URL?, to out: URL) async throws {
        let size = CGSize(width: 1080, height: 1920)
        try? FileManager.default.removeItem(at: out)

        let writer = try AVAssetWriter(outputURL: out, fileType: .mp4)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height)
        ]
        let vInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        vInput.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: vInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: Int(size.width),
                kCVPixelBufferHeightKey as String: Int(size.height)
            ])
        guard writer.canAdd(vInput) else { throw ShareExport.ShareError.encodeFailed("video input") }
        writer.add(vInput)

        var aInput: AVAssetWriterInput?
        var audioReader: AVAssetReader?
        var audioOutput: AVAssetReaderTrackOutput?
        let totalDur = CMTimeMultiply(frameDuration, multiplier: Int32(frames.count))

        if let audio, AppSettings.shared.audioInReel {
            let asset = AVURLAsset(url: audio)
            do {
                let reader = try AVAssetReader(asset: asset)
                if let track = try? await asset.loadTracks(withMediaType: .audio).first {
                    let outSettings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatMPEG4AAC,
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 2
                    ]
                    let o = AVAssetReaderTrackOutput(track: track, outputSettings: outSettings)
                    reader.timeRange = CMTimeRange(start: .zero, duration: totalDur)
                    if reader.canAdd(o) {
                        reader.add(o)
                        let inp = AVAssetWriterInput(mediaType: .audio, outputSettings: outSettings)
                        inp.expectsMediaDataInRealTime = false
                        if writer.canAdd(inp) { writer.add(inp); aInput = inp; audioReader = reader; audioOutput = o }
                    }
                }
            } catch { /* no audio — continue silent */ }
        }

        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        // video frames
        for (i, cg) in frames.enumerated() {
            while !vInput.isReadyForMoreMediaData { try await Task.sleep(nanoseconds: 8_000_000) }
            guard let buf = pixelBuffer(from: cg, size: size) else { continue }
            let t = CMTimeMultiply(frameDuration, multiplier: Int32(i))
            if !adaptor.append(buf, withPresentationTime: t) {
                throw ShareExport.ShareError.encodeFailed(writer.error?.localizedDescription ?? "frame \(i)")
            }
        }
        vInput.markAsFinished()

        // audio samples
        if let aInput, let audioReader, let audioOutput {
            audioReader.startReading()
            while let sample = audioOutput.copyNextSampleBuffer() {
                while !aInput.isReadyForMoreMediaData { try await Task.sleep(nanoseconds: 8_000_000) }
                if !aInput.append(sample) { break }
            }
            aInput.markAsFinished()
        }

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            writer.finishWriting { cont.resume() }
        }
        if writer.status == .failed {
            throw ShareExport.ShareError.encodeFailed(writer.error?.localizedDescription ?? "unknown")
        }
    }

    private static func pixelBuffer(from cg: CGImage, size: CGSize) -> CVPixelBuffer? {
        var buf: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        guard kCVReturnSuccess == CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height),
                                                      kCVPixelFormatType_32BGRA, attrs as CFDictionary, &buf),
              let buffer = buf else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                  width: Int(size.width), height: Int(size.height),
                                  bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                                    | CGBitmapInfo.byteOrder32Little.rawValue) else { return nil }
        ctx.interpolationQuality = .high
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        return buffer
    }
}

// MARK: - Live window recorder (ScreenCaptureKit, macOS 15+)

@MainActor
final class Recorder: ObservableObject {
    @Published var status = ""
    @Published var recording = false
    private var stream: SCStream?

    func toggle() {
        if recording { stop() } else { start() }
    }

    func start() {
        guard #available(macOS 15.0, *) else {
            status = "Live video recording requires macOS 15 or later — use Reel export instead."
            return
        }
        Task { await performStart() }
    }

    @available(macOS 15.0, *)
    private func performStart() async {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let win = NSApp.windows.first(where: { $0.isVisible }),
                  let sc = content.windows.first(where: { $0.windowID == UInt32(win.windowNumber) }) else {
                status = "Window not found for recording."
                return
            }
            let filter = SCContentFilter(desktopIndependentWindow: sc)
            let cfg = SCStreamConfiguration()
            cfg.width = Int((sc.frame.width * 2).rounded()) & ~1
            cfg.height = Int((sc.frame.height * 2).rounded()) & ~1
            cfg.minimumFrameInterval = CMTime(value: 1, timescale: 30)
            cfg.showsCursor = true

            let outCfg = SCRecordingOutputConfiguration()
            let url = Capture.shareFolder().appendingPathComponent("window-\(Capture.stamp()).mp4")
            outCfg.outputURL = url
            outCfg.outputFileType = .mp4

            let delegate = RecorderDelegate()
            let output = SCRecordingOutput(configuration: outCfg, delegate: delegate)
            let s = SCStream(filter: filter, configuration: cfg, delegate: nil)
            try s.addRecordingOutput(output)
            try await s.startCapture()
            stream = s
            recording = true
            status = "Recording → \(url.lastPathComponent)"
        } catch {
            status = "Recording blocked: allow Screen Recording for AsmaulHusna in System Settings → Privacy & Security."
        }
    }

    func stop() {
        Task {
            try? await stream?.stopCapture()
            stream = nil
            recording = false
            status = "Saved to Desktop/AsmaulHusna-Exports"
        }
    }
}

@available(macOS 15.0, *)
private final class RecorderDelegate: NSObject, SCRecordingOutputDelegate {
    func recordingOutput(_ recordingOutput: SCRecordingOutput, didFailWithError error: Error) {
        print("recording failed: \(error)")
    }
    func recordingOutputDidFinishRecording(_ recordingOutput: SCRecordingOutput) {}
}
