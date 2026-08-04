// Encode a directory of PNG frames into a muted H.264 .mp4 loop.
// Used because this Blender build has no FFMPEG encoder compiled in.
// Usage: swift encode_mp4.swift <framesDir> <out.mp4> <fps> <width> <height>
import AVFoundation
import AppKit
import Foundation

let a = CommandLine.arguments
guard a.count >= 6, let fps = Int32(a[3]), let W = Int(a[4]), let H = Int(a[5]) else {
    FileHandle.standardError.write(Data("usage: encode_mp4.swift framesDir out.mp4 fps w h\n".utf8))
    exit(2)
}
let dir = a[1], outPath = a[2]

let frames = (try! FileManager.default.contentsOfDirectory(atPath: dir))
    .filter { $0.hasSuffix(".png") }.sorted()
    .map { (dir as NSString).appendingPathComponent($0) }
guard !frames.isEmpty else { FileHandle.standardError.write(Data("no PNG frames in \(dir)\n".utf8)); exit(1) }

try? FileManager.default.removeItem(atPath: outPath)
let writer = try! AVAssetWriter(outputURL: URL(fileURLWithPath: outPath), fileType: .mp4)
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: W, AVVideoHeightKey: H,
])
input.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
    kCVPixelBufferWidthKey as String: W, kCVPixelBufferHeightKey as String: H,
])
writer.add(input)
writer.startWriting()
writer.startSession(atSourceTime: .zero)

func pixelBuffer(_ path: String) -> CVPixelBuffer? {
    guard let img = NSImage(contentsOfFile: path),
          let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
    var pb: CVPixelBuffer?
    CVPixelBufferCreate(kCFAllocatorDefault, W, H, kCVPixelFormatType_32ARGB, nil, &pb)
    guard let buffer = pb else { return nil }
    CVPixelBufferLockBaseAddress(buffer, [])
    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
    let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: W, height: H,
        bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
    ctx?.draw(cg, in: CGRect(x: 0, y: 0, width: W, height: H))
    return buffer
}

var i: Int64 = 0
for f in frames {
    while !input.isReadyForMoreMediaData { usleep(1000) }
    guard let pb = pixelBuffer(f) else { continue }
    adaptor.append(pb, withPresentationTime: CMTime(value: i, timescale: fps))
    i += 1
}
input.markAsFinished()
let sem = DispatchSemaphore(value: 0)
writer.finishWriting { sem.signal() }
sem.wait()
if writer.status == .completed {
    print("wrote \(outPath) (\(i) frames @ \(fps)fps, \(W)x\(H))")
} else {
    FileHandle.standardError.write(Data("encode failed: \(String(describing: writer.error))\n".utf8))
    exit(1)
}
