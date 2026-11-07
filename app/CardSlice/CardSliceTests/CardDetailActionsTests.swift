import CoreGraphics
import Foundation
import Testing
import UIKit
@testable import CardSlice

@MainActor
struct CardDetailActionsTests {
    @Test func testLocalTelephoneTarget() {
        #expect(CardDetailContactAction.phone.url(for: "010-5555-0123")?.absoluteString == "tel:01055550123")
    }

    @Test func testInternationalTelephoneTarget() {
        #expect(CardDetailContactAction.phone.url(for: " +86 (138) 0013–8000 ")?.absoluteString == "tel:+8613800138000")
    }

    @Test func testInvalidTelephoneTargetsAreRejected() {
        for value in [" ", "12", "++8613800138000", "555-0123;ext=8", "*#06#", "tel:5550123", "555%0A0123"] {
            #expect(CardDetailContactAction.phone.url(for: value) == nil)
        }
    }

    @Test func testEmailTargetEscapesAddressWithoutAddingHeaders() {
        #expect(CardDetailContactAction.email.url(for: " alex+work@example.com ")?.absoluteString == "mailto:alex+work@example.com")
        #expect(CardDetailContactAction.email.url(for: "a#b@example.com")?.absoluteString == "mailto:a%23b@example.com")
    }

    @Test func testInvalidEmailTargetsAreRejected() {
        for value in [" ", "alex", "alex@@example.com", "alex\n@example.com", "alex..work@example.com", "alex@example.com?subject=Hi", "a@example.com,b@example.com"] {
            #expect(CardDetailContactAction.email.url(for: value) == nil)
        }
    }

    @Test func testExplicitWebSchemesAndPathsArePreserved() {
        let http = "http://example.com/card"
        let https = "https://example.com/contact?q=alex#details"
        #expect(CardDetailContactAction.website.url(for: http)?.absoluteString == http)
        #expect(CardDetailContactAction.website.url(for: https)?.absoluteString == https)
    }

    @Test func testBareWebDomainUsesHTTPS() {
        #expect(CardDetailContactAction.website.url(for: " www.example.com/team ")?.absoluteString == "https://www.example.com/team")
    }

    @Test func testInvalidWebTargetsAndOtherSchemesAreRejected() {
        for value in [" ", "not a host", "undotted", "javascript:alert(1)", "file:///tmp/contact",
                      "custom://example.com", "https://user@example.com", "//example.com",
                      "https://bad_host.example", "https://example.com:99999"] {
            #expect(CardDetailContactAction.website.url(for: value) == nil)
        }
    }

    @Test func testOriginalAndProcessedImagesUseDistinctStoredData() {
        let originalSize = CGSize(width: 28, height: 16)
        let processedSize = CGSize(width: 14, height: 24)
        let card = BusinessCardRecord(originalImageData: png(size: originalSize),
                                      processedImageData: png(size: processedSize), name: "虚构联系人")
        guard case .image(let original) = CardDetailImage.original.preview(in: card),
              case .image(let processed) = CardDetailImage.processed.preview(in: card) else {
            Issue.record("原图与处理图应分别解码")
            return
        }
        #expect(original.size == originalSize)
        #expect(processed.size == processedSize)
    }

    @Test func testMissingAndUnreadableImagesAreDistinguished() {
        let card = BusinessCardRecord(processedImageData: Data([0, 1, 2]), name: "虚构联系人")
        guard case .missing = CardDetailImage.original.preview(in: card),
              case .unreadable = CardDetailImage.processed.preview(in: card) else {
            Issue.record("缺失及损坏数据应产生各自的状态")
            return
        }
    }

    @Test func testRowThumbnailPrefersProcessedAndLimitsPixelSize() throws {
        let card = BusinessCardRecord(originalImageData: png(size: CGSize(width: 90, height: 60)),
                                      processedImageData: png(size: CGSize(width: 300, height: 600)),
                                      name: "缩略图测试")
        let image = try #require(thumbnailRequest(for: card).decode())
        #expect(image.height == 60)
        #expect(image.width == 30)
    }

    @Test func testRowThumbnailUsesOriginalWhenProcessedIsMissing() throws {
        let card = BusinessCardRecord(originalImageData: png(size: CGSize(width: 120, height: 60)), name: "原图测试")
        let image = try #require(thumbnailRequest(for: card).decode())
        #expect(image.width == 60)
        #expect(image.height == 30)
    }

    @Test func testRowThumbnailIsMissingWithoutUsableImages() {
        let missing = BusinessCardRecord(name: "无图")
        let damaged = BusinessCardRecord(originalImageData: Data([1]), processedImageData: Data([2]), name: "坏图")
        #expect(thumbnailRequest(for: missing).decode() == nil)
        #expect(thumbnailRequest(for: damaged).decode() == nil)
    }

    @Test func testRowThumbnailFallsBackFromDamagedProcessedImage() throws {
        let card = BusinessCardRecord(originalImageData: png(size: CGSize(width: 60, height: 120)),
                                      processedImageData: Data([0, 1, 2]), name: "回退测试")
        let image = try #require(thumbnailRequest(for: card).decode())
        #expect(image.width == 30)
        #expect(image.height == 60)
    }

    @Test func testRowThumbnailRequestsKeepCardsAndImageUpdatesDistinct() throws {
        let first = BusinessCardRecord(processedImageData: png(size: CGSize(width: 120, height: 60)), name: "甲")
        let second = BusinessCardRecord(processedImageData: png(size: CGSize(width: 60, height: 120)), name: "乙")
        let firstRequest = thumbnailRequest(for: first)
        let secondRequest = thumbnailRequest(for: second)
        #expect(firstRequest != secondRequest)
        let firstImage = try #require(firstRequest.decode())
        let secondImage = try #require(secondRequest.decode())
        #expect(firstImage.width > firstImage.height)
        #expect(secondImage.width < secondImage.height)

        var updated = first
        updated.processedImageData = second.processedImageData
        #expect(thumbnailRequest(for: updated) != firstRequest)
    }

    private func thumbnailRequest(for card: BusinessCardRecord) -> CardThumbnailRequest {
        CardThumbnailRequest(cardID: card.id, processed: card.processedImageData,
                             original: card.originalImageData, maxPixelSize: 60)
    }

    private func png(size: CGSize) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).pngData { context in
            context.cgContext.setFillColor(UIColor.blue.cgColor)
            context.cgContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
