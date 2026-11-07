import Foundation
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

/// 当前预览流程中的图像结果，不是正式名片记录。
struct PreparedCardImage: Sendable {
    let originalData: Data
    let processedData: Data
    let pixelWidth: Int
    let pixelHeight: Int

    nonisolated init(originalData: Data, processedData: Data, pixelWidth: Int, pixelHeight: Int) {
        self.originalData = originalData
        self.processedData = processedData
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}

enum CardImagePreparationError: Error, LocalizedError, Equatable, Sendable {
    case emptyInput
    case unsupportedOrUndecodable
    case invalidDimensions
    case processingOrEncodingFailed

    nonisolated var errorDescription: String? {
        switch self {
        case .emptyInput: return "图片数据为空，请重新选择。"
        case .unsupportedOrUndecodable: return "图片格式不受支持或无法解码，请选择其他图片。"
        case .invalidDimensions: return "图片尺寸无效，无法进行预处理。"
        case .processingOrEncodingFailed: return "图片预处理或编码失败，请重新选择。"
        }
    }
}

/// 独立于 UI 的同步处理服务，可在后台任务中调用。
struct CardImagePreparationService {
    // [DECISION/TEMP] 后续根据 OCR 精度测试调整尺寸和压缩质量。
    nonisolated static let maximumPixelDimension = 3000
    nonisolated static let jpegQuality = 0.9

    nonisolated static func prepare(_ originalData: Data) throws -> PreparedCardImage {
        guard !originalData.isEmpty else { throw CardImagePreparationError.emptyInput }
        guard let source = CGImageSourceCreateWithData(originalData as CFData,
                [kCGImageSourceShouldCache: false] as CFDictionary),
              CGImageSourceGetCount(source) > 0 else {
            throw CardImagePreparationError.unsupportedOrUndecodable
        }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
              let height = properties[kCGImagePropertyPixelHeight] as? NSNumber else {
            throw CardImagePreparationError.unsupportedOrUndecodable
        }
        guard width.doubleValue.isFinite, height.doubleValue.isFinite,
              width.doubleValue > 0, height.doubleValue > 0 else {
            throw CardImagePreparationError.invalidDimensions
        }

        // 限制解码尺寸；对小图使用原最长边，避免放大。Transform 同时处理旋转和镜像元数据。
        let limit = min(Double(maximumPixelDimension), max(width.doubleValue, height.doubleValue))
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(limit),
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw CardImagePreparationError.unsupportedOrUndecodable
        }
        guard image.width > 0, image.height > 0 else {
            throw CardImagePreparationError.invalidDimensions
        }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw CardImagePreparationError.processingOrEncodingFailed
        }
        // 像素已转正，输出方向设为1，避免下游再次旋转。
        CGImageDestinationAddImage(destination, image, [
            kCGImageDestinationLossyCompressionQuality: jpegQuality,
            kCGImagePropertyOrientation: 1
        ] as CFDictionary)
        guard CGImageDestinationFinalize(destination), output.length > 0 else {
            throw CardImagePreparationError.processingOrEncodingFailed
        }
        return PreparedCardImage(originalData: originalData, processedData: output as Data,
                                 pixelWidth: image.width, pixelHeight: image.height)
    }
}
