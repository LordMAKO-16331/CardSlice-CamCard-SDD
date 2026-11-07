import Foundation
import CoreImage
import ImageIO
import UniformTypeIdentifiers

struct CorrectedCardImage: Sendable {
    let data: Data
    let pixelWidth: Int
    let pixelHeight: Int
    nonisolated init(data: Data, pixelWidth: Int, pixelHeight: Int) {
        self.data = data; self.pixelWidth = pixelWidth; self.pixelHeight = pixelHeight
    }
}

struct CardPerspectiveCorrectionService {
    nonisolated static func correct(_ data: Data, boundary: CardQuadrilateral) throws -> CorrectedCardImage {
        let cgImage = try CardRectangleDetectionService.decode(data)
        let image = CIImage(cgImage: cgImage)
        let points = try boundary.pixelPoints(in: image.extent)
        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
            throw CardRectangleProcessingError.correctionFailed
        }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: points[0]), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: points[1]), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: points[2]), forKey: "inputBottomRight")
        filter.setValue(CIVector(cgPoint: points[3]), forKey: "inputBottomLeft")
        guard let output = filter.outputImage else { throw CardRectangleProcessingError.correctionFailed }
        let extent = output.extent.integral
        // [DECISION/TEMP] 限制渲染范围，拒绝病态几何导致的异常内存分配。
        guard !extent.isNull, !extent.isInfinite,
              extent.origin.x.isFinite, extent.origin.y.isFinite,
              extent.width.isFinite, extent.height.isFinite,
              extent.width >= 1, extent.height >= 1,
              extent.width <= 6000, extent.height <= 6000,
              extent.width * extent.height <= 18_000_000,
              let rendered = CIContext().createCGImage(output, from: extent) else {
            throw CardRectangleProcessingError.correctionFailed
        }
        let encoded = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(encoded, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw CardRectangleProcessingError.correctionFailed
        }
        // [DECISION/TEMP] 与预处理阶段一致，输出已转正的JPEG。
        CGImageDestinationAddImage(destination, rendered, [kCGImageDestinationLossyCompressionQuality: 0.9,
                                                         kCGImagePropertyOrientation: 1] as CFDictionary)
        guard CGImageDestinationFinalize(destination), encoded.length > 0 else {
            throw CardRectangleProcessingError.correctionFailed
        }
        return CorrectedCardImage(data: encoded as Data, pixelWidth: rendered.width, pixelHeight: rendered.height)
    }
}
