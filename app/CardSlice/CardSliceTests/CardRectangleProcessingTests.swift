import Testing
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import CardSlice

@MainActor
struct CardRectangleProcessingTests {
    private var fullBoundary: CardQuadrilateral {
        CardQuadrilateral(topLeft: CGPoint(x: 0, y: 1), topRight: CGPoint(x: 1, y: 1),
                          bottomLeft: .zero, bottomRight: CGPoint(x: 1, y: 0))
    }

    @Test func testEmptyAndInvalidImagesAreRejected() {
        for data in [Data(), Data("not an image".utf8)] {
            #expect(throws: CardRectangleProcessingError.invalidImage) {
                try CardRectangleDetectionService.detect(data)
            }
            #expect(throws: CardRectangleProcessingError.invalidImage) {
                try CardPerspectiveCorrectionService.correct(data, boundary: fullBoundary)
            }
        }
    }

    @Test func testFeaturelessImageHasSafeDetectionResult() throws {
        let result = try CardRectangleDetectionService.detect(makeImage())
        #expect(result.pixelWidth == 200)
        #expect(result.pixelHeight == 120)
        if let boundary = result.boundary {
            // 不依赖 Vision 对纯色图的具体识别结果，只要求结果合法。
            #expect(boundary.isValid)
            let confidence = try #require(result.confidence)
            #expect(confidence.isFinite && (0...1).contains(confidence))
        } else {
            #expect(!result.isDetected)
            #expect(result.confidence == nil)
        }
    }

    @Test func testNormalizedPointsConvertToPixelCoordinates() throws {
        let points = try fullBoundary.pixelPoints(in: CGRect(x: 10, y: 20, width: 200, height: 100))
        #expect(points == [CGPoint(x: 10, y: 120), CGPoint(x: 210, y: 120),
                           CGPoint(x: 210, y: 20), CGPoint(x: 10, y: 20)])
    }

    @Test func testInvalidQuadrilateralsAreRejected() throws {
        let data = try makeImage()
        let boundaries = [
            CardQuadrilateral(topLeft: CGPoint(x: -0.1, y: 1), topRight: CGPoint(x: 1, y: 1),
                              bottomLeft: .zero, bottomRight: CGPoint(x: 1, y: 0)),
            CardQuadrilateral(topLeft: .zero, topRight: .zero, bottomLeft: .zero, bottomRight: .zero),
            CardQuadrilateral(topLeft: CGPoint(x: 0, y: 1), topRight: CGPoint(x: 1, y: 0),
                              bottomLeft: .zero, bottomRight: CGPoint(x: 1, y: 1)),
            CardQuadrilateral(topLeft: CGPoint(x: CGFloat.nan, y: 1), topRight: CGPoint(x: 1, y: 1),
                              bottomLeft: .zero, bottomRight: CGPoint(x: 1, y: 0))
        ]
        for boundary in boundaries {
            #expect(!boundary.isValid)
            #expect(throws: CardRectangleProcessingError.invalidBoundary) {
                try CardPerspectiveCorrectionService.correct(data, boundary: boundary)
            }
        }
    }

    @Test func testValidPerspectiveCorrectionProducesDecodableImage() throws {
        let boundary = CardQuadrilateral(topLeft: CGPoint(x: 0.15, y: 0.85), topRight: CGPoint(x: 0.8, y: 0.95),
                                         bottomLeft: CGPoint(x: 0.1, y: 0.1), bottomRight: CGPoint(x: 0.9, y: 0.15))
        let result = try CardPerspectiveCorrectionService.correct(makeImage(), boundary: boundary)
        let source = try #require(CGImageSourceCreateWithData(result.data as CFData, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        #expect(image.width == result.pixelWidth)
        #expect(image.height == result.pixelHeight)
    }

    @Test func testCorrectionPreservesInputData() throws {
        let input = try makeImage()
        let snapshot = Data(input)
        let result = try CardPerspectiveCorrectionService.correct(input, boundary: fullBoundary)
        #expect(input == snapshot)
        #expect(!result.data.isEmpty)
    }

    @Test func testOutputDimensionsAreReasonable() throws {
        let result = try CardPerspectiveCorrectionService.correct(makeImage(), boundary: fullBoundary)
        #expect(result.pixelWidth > 0 && result.pixelHeight > 0)
        #expect(abs(result.pixelWidth - 200) <= 2)
        #expect(abs(result.pixelHeight - 120) <= 2)
    }

    @Test func testInvalidPixelExtentIsRejected() {
        #expect(throws: CardRectangleProcessingError.invalidBoundary) {
            try fullBoundary.pixelPoints(in: .zero)
        }
    }

    private func candidate(_ boundary: CardQuadrilateral, confidence: Float = 0.9) -> CardRectangleCandidate {
        CardRectangleCandidate(boundary: boundary, confidence: confidence, pixelWidth: 200, pixelHeight: 120)
    }

    private var innerBoundary: CardQuadrilateral {
        CardQuadrilateral(topLeft: CGPoint(x: 0.2, y: 0.8), topRight: CGPoint(x: 0.8, y: 0.8),
                          bottomLeft: CGPoint(x: 0.2, y: 0.2), bottomRight: CGPoint(x: 0.8, y: 0.2))
    }

    @Test func testCandidateRankingIsDeterministic() {
        let a = candidate(fullBoundary, confidence: 1)
        let b = candidate(innerBoundary)
        let first = CardRectangleDetectionService.rankedCandidates([a, b])
        let second = CardRectangleDetectionService.rankedCandidates([b, a])
        #expect(first.map { $0.boundary.points } == second.map { $0.boundary.points })
        #expect(first.count == 2)
    }

    @Test func testInternalCandidatePrecedesBorderWithoutDiscardingBorder() {
        let border = candidate(fullBoundary, confidence: 1)
        let inner = candidate(innerBoundary, confidence: 0.6)
        let sorted = CardRectangleDetectionService.rankedCandidates([border, inner])
        #expect(border.isNearImageBorder)
        #expect(!inner.isNearImageBorder)
        #expect(sorted.first?.boundary.points == innerBoundary.points)
        #expect(sorted.last?.boundary.points == fullBoundary.points)
        #expect(sorted.count == 2)
    }

    @Test func testCandidateMetadataAndCornersStayTogether() {
        let sorted = CardRectangleDetectionService.rankedCandidates([
            candidate(fullBoundary, confidence: 1), candidate(innerBoundary, confidence: 0.7)])
        let inner = sorted[0]
        #expect(inner.boundary.topLeft == innerBoundary.topLeft)
        #expect(inner.boundary.topRight == innerBoundary.topRight)
        #expect(inner.boundary.bottomLeft == innerBoundary.bottomLeft)
        #expect(inner.boundary.bottomRight == innerBoundary.bottomRight)
        #expect(inner.confidence == 0.7)
        #expect(abs(inner.relativeArea - 0.36) < 0.0001)
        #expect(abs(inner.aspectRatio - 200.0 / 120.0) < 0.0001)
    }

    @Test func testOnlyConfirmedSelectedCandidateIsUsedForCorrection() throws {
        let result = CardRectangleDetectionResult(candidates: [candidate(innerBoundary), candidate(fullBoundary)],
                                                   pixelWidth: 200, pixelHeight: 120)
        #expect(throws: CardRectangleProcessingError.invalidBoundary) {
            try result.selectedBoundary(at: 1, confirmed: false)
        }
        let selected = try result.selectedBoundary(at: 1, confirmed: true)
        #expect(selected.points == fullBoundary.points)
        let corrected = try CardPerspectiveCorrectionService.correct(makeImage(), boundary: selected)
        #expect(abs(corrected.pixelWidth - 200) <= 2)
        #expect(abs(corrected.pixelHeight - 120) <= 2)
    }

    @Test func testEmptyCandidatesAndInvalidSelectionAreSafe() {
        let result = CardRectangleDetectionResult(candidates: [], pixelWidth: 200, pixelHeight: 120)
        #expect(!result.isDetected)
        #expect(result.boundary == nil)
        #expect(result.candidate(at: nil) == nil)
        #expect(result.candidate(at: 0) == nil)
        #expect(throws: CardRectangleProcessingError.invalidBoundary) {
            try result.selectedBoundary(at: 0, confirmed: true)
        }
    }

    @Test func testSingleBorderCandidateRemainsSelectable() throws {
        let sorted = CardRectangleDetectionService.rankedCandidates([candidate(fullBoundary)])
        let result = CardRectangleDetectionResult(candidates: sorted, pixelWidth: 200, pixelHeight: 120)
        #expect(result.candidates.count == 1)
        #expect(result.candidate(at: -1) == nil)
        #expect(result.candidate(at: 1) == nil)
        #expect(try result.selectedBoundary(at: 0, confirmed: true).points == fullBoundary.points)
    }

    @Test func testInvalidCandidateConfidenceIsRejected() {
        let sorted = CardRectangleDetectionService.rankedCandidates([
            candidate(innerBoundary, confidence: .nan), candidate(fullBoundary, confidence: 1.1)])
        #expect(sorted.isEmpty)
    }

    @Test func testLandscapeCropMappingAccountsForVerticalLetterbox() {
        let geometry = CardCropPreviewGeometry(imageSize: CGSize(width: 400, height: 200),
                                               viewport: CGSize(width: 200, height: 200))
        #expect(geometry.imageFrame == CGRect(x: 0, y: 50, width: 200, height: 100))
        let point = CGPoint(x: 0.25, y: 0.75)
        #expect(geometry.displayPoint(for: point) == CGPoint(x: 50, y: 75))
        #expect(geometry.normalizedPoint(for: CGPoint(x: 50, y: 75)) == point)
    }

    @Test func testPortraitCropMappingClampsHorizontalLetterboxAndEdges() {
        let geometry = CardCropPreviewGeometry(imageSize: CGSize(width: 100, height: 200),
                                               viewport: CGSize(width: 200, height: 200))
        #expect(geometry.imageFrame == CGRect(x: 50, y: 0, width: 100, height: 200))
        #expect(geometry.normalizedPoint(for: CGPoint(x: 20, y: -10)) == CGPoint(x: 0, y: 1))
        #expect(geometry.normalizedPoint(for: CGPoint(x: 180, y: 210)) == CGPoint(x: 1, y: 0))
    }

    @Test func testManualCropUsesEditedCornersInServiceOrder() throws {
        var crop = ManualCardCrop(candidate: innerBoundary)
        let edited = CGPoint(x: 0.05, y: 0.95)
        let moved = crop.moveCorner(at: 0, to: edited)
        #expect(moved)
        #expect(crop.boundary.points == [edited, innerBoundary.topRight,
                                         innerBoundary.bottomRight, innerBoundary.bottomLeft])
        #expect(crop.boundary.isValid)
        let corrected = try CardPerspectiveCorrectionService.correct(makeImage(), boundary: crop.boundary)
        #expect(corrected.pixelWidth > 0)
        #expect(corrected.pixelHeight > 0)
    }

    @Test func testManualCropRejectsCrossingAndDegenerateMoves() {
        var crop = ManualCardCrop(candidate: nil)
        let initial = crop.boundary
        let crossed = crop.moveCorner(at: 0, to: CGPoint(x: 0.95, y: 0.05))
        #expect(!crossed)
        let degenerated = crop.moveCorner(at: 0, to: initial.topRight)
        #expect(!degenerated)
        let movedOutside = crop.moveCorner(at: 0, to: CGPoint(x: -0.1, y: 0.9))
        #expect(!movedOutside)
        #expect(crop.boundary.points == initial.points)
    }

    @Test func testManualCropWithoutCandidateStartsFresh() {
        var previous = ManualCardCrop(candidate: nil)
        let initial = previous.boundary
        #expect(initial.isValid)
        let moved = previous.moveCorner(at: 0, to: CGPoint(x: 0.05, y: 0.95))
        #expect(moved)
        let fresh = ManualCardCrop(candidate: nil)
        #expect(fresh.boundary.points == initial.points)
        #expect(fresh.boundary.points != previous.boundary.points)
        #expect(ManualCardCrop(candidate: innerBoundary).boundary.points == innerBoundary.points)
    }

    private func makeImage() throws -> Data {
        let context = try #require(CGContext(data: nil, width: 200, height: 120,
            bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        context.setFillColor(CGColor(gray: 0.7, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 200, height: 120))
        let image = try #require(context.makeImage())
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        let finalized = CGImageDestinationFinalize(destination)
        #expect(finalized)
        return data as Data
    }
}
