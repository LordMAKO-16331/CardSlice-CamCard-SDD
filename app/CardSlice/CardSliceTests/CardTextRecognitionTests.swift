import Testing
import Foundation
import UIKit
@testable import CardSlice

@MainActor
struct CardTextRecognitionTests {
    @Test func testEmptyDataIsRejected() {
        #expect(throws: CardTextRecognitionError.emptyInput) {
            try CardTextRecognitionService.recognize(Data())
        }
    }

    @Test func testNonImageDataIsRejected() {
        #expect(throws: CardTextRecognitionError.undecodableImage) {
            try CardTextRecognitionService.recognize(Data("not an image".utf8))
        }
    }

    @Test func testClearEnglishImageProducesValidLines() throws {
        let result = try CardTextRecognitionService.recognize(makeImage(text: "HELLO WORLD 123"), languages: ["en-US"])
        #expect(!result.lines.isEmpty)
        #expect(result.lines.contains { $0.text.contains(where: { $0.isLetter }) })
        for line in result.lines {
            #expect(!line.text.isEmpty)
            #expect(line.confidence.isFinite && (0...1).contains(line.confidence))
            let box = line.boundingBox
            #expect(box.origin.x.isFinite && box.origin.y.isFinite)
            #expect(box.width > 0 && box.height > 0)
            #expect(box.minX >= -0.001 && box.minY >= -0.001 && box.maxX <= 1.001 && box.maxY <= 1.001)
        }
        #expect(result.rawText == result.lines.map(\.text).joined(separator: "\n"))
    }

    @Test func testRawTextPreservesLineTextAndPunctuation() {
        let lines = [
            RecognizedCardTextLine(text: "Name, A!", confidence: 0.9, boundingBox: CGRect(x: 0.1, y: 0.8, width: 0.5, height: 0.1)),
            RecognizedCardTextLine(text: "+123 (456) / test@example.com", confidence: 0.8, boundingBox: CGRect(x: 0.1, y: 0.5, width: 0.8, height: 0.1))
        ]
        let result = RecognizedCardText(lines: lines, languages: ["en-US"])
        #expect(result.rawText == "Name, A!\n+123 (456) / test@example.com")
    }

    @Test func testReadingOrderIsTopToBottomThenLeftToRight() {
        let bottom = RecognizedCardTextLine(text: "bottom", confidence: 1, boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.1))
        let right = RecognizedCardTextLine(text: "right", confidence: 1, boundingBox: CGRect(x: 0.6, y: 0.8, width: 0.3, height: 0.1))
        let left = RecognizedCardTextLine(text: "left", confidence: 1, boundingBox: CGRect(x: 0.1, y: 0.8, width: 0.3, height: 0.1))
        #expect(CardTextRecognitionService.readingOrder([bottom, right, left]).map(\.text) == ["left", "right", "bottom"])
    }

    @Test func testBlankImageReturnsNoText() throws {
        let image = try makeImage(text: nil)
        #expect(throws: CardTextRecognitionError.noText) {
            try CardTextRecognitionService.recognize(image, languages: ["en-US"])
        }
    }

    @Test func testLanguageValidationAndMissingLanguageError() {
        #expect(throws: Never.self) {
            let languages = try CardTextRecognitionService.validatedLanguages(
                requested: ["zh-Hans", "en-US"], supported: ["en-US", "zh-Hans", "fr-FR"])
            #expect(languages == ["zh-Hans", "en-US"])
        }
        #expect(throws: CardTextRecognitionError.unavailableLanguages(["zh-Hans"])) {
            try CardTextRecognitionService.validatedLanguages(requested: ["zh-Hans", "en-US"], supported: ["en-US"])
        }
        #expect(throws: CardTextRecognitionError.unavailableLanguages(["zz-INVALID"])) {
            try CardTextRecognitionService.validatedLanguages(requested: ["zz-INVALID"], supported: [])
        }
    }

    @Test func testRuntimeChineseEnglishAvailabilityIsExplicit() throws {
        let supported = try CardTextRecognitionService.supportedLanguages()
        let requested = CardTextRecognitionService.preferredLanguages
        let missing = requested.filter { !supported.contains($0) }
        if missing.isEmpty {
            let result = try CardTextRecognitionService.recognize(makeImage(text: "名片测试 联系方式 HELLO 123"))
            #expect(result.languages == requested)
            #expect(result.lines.contains { line in
                line.text.unicodeScalars.contains { (0x4E00...0x9FFF).contains($0.value) }
            })
        } else {
            let image = try makeImage(text: "HELLO 123")
            #expect(throws: CardTextRecognitionError.unavailableLanguages(missing)) {
                try CardTextRecognitionService.recognize(image)
            }
        }
    }

    private func makeImage(text: String?) throws -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1600, height: 400), format: format)
        let data = renderer.pngData { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1600, height: 400))
            if let text {
                (text as NSString).draw(at: CGPoint(x: 70, y: 130), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 64, weight: .medium),
                    .foregroundColor: UIColor.black
                ])
            }
        }
        #expect(!data.isEmpty)
        return data
    }
}
