import Testing
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import CardSlice

@MainActor
struct CardImagePreparationTests {
    @Test func testEmptyDataIsRejected() {
        #expect(throws: CardImagePreparationError.emptyInput) {
            try CardImagePreparationService.prepare(Data())
        }
    }

    @Test func testNonImageDataIsRejected() {
        #expect(throws: CardImagePreparationError.unsupportedOrUndecodable) {
            try CardImagePreparationService.prepare(Data("not an image".utf8))
        }
    }

    @Test func testProcessedDataCanBeDecoded() throws {
        let input = try makeImage(width: 240, height: 120)
        let result = try CardImagePreparationService.prepare(input)
        let source = try #require(CGImageSourceCreateWithData(result.processedData as CFData, nil))
        let decoded = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        #expect(decoded.width == result.pixelWidth)
        #expect(decoded.height == result.pixelHeight)
        #expect(result.pixelWidth > 0 && result.pixelHeight > 0)
    }

    @Test func testOriginalDataIsPreserved() throws {
        let input = try makeImage(width: 160, height: 90)
        let result = try CardImagePreparationService.prepare(input)
        #expect(result.originalData == input)
        #expect(!result.processedData.isEmpty)
    }

    @Test func testLargeImageIsDownsampledWithoutChangingAspectRatio() throws {
        let input = try makeImage(width: 4000, height: 2000)
        let result = try CardImagePreparationService.prepare(input)
        #expect(max(result.pixelWidth, result.pixelHeight) <= CardImagePreparationService.maximumPixelDimension)
        #expect(result.pixelWidth < 4000)
        #expect(abs(Double(result.pixelWidth) / Double(result.pixelHeight) - 2.0) < 0.01)
    }

    @Test func testSmallImageIsNotUpscaled() throws {
        let input = try makeImage(width: 320, height: 180)
        let result = try CardImagePreparationService.prepare(input)
        #expect(result.pixelWidth == 320)
        #expect(result.pixelHeight == 180)
    }

    @Test func testOrientationMetadataIsApplied() throws {
        // EXIF 6 表示顺时针90度；输出像素应转正且不再携带该旋转方向。
        let input = try makeImage(width: 120, height: 80, orientation: 6)
        let result = try CardImagePreparationService.prepare(input)
        #expect(result.pixelWidth == 80)
        #expect(result.pixelHeight == 120)
        let source = try #require(CGImageSourceCreateWithData(result.processedData as CFData, nil))
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
        #expect(orientation == 1)
    }

    /// 生成虚拟像素与方向元数据，不依赖用户相册。
    private func makeImage(width: Int, height: Int, orientation: Int = 1) throws -> Data {
        let context = try #require(CGContext(data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width / 3, height: height / 2))
        let image = try #require(context.makeImage())
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data,
            UTType.jpeg.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: orientation] as CFDictionary)
        let finalized = CGImageDestinationFinalize(destination)
        #expect(finalized)
        return data as Data
    }
}
