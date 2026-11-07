import Foundation
import CoreGraphics
import ImageIO
import Vision

struct RecognizedCardTextLine: Sendable {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
    nonisolated init(text: String, confidence: Float, boundingBox: CGRect) {
        self.text = text; self.confidence = confidence; self.boundingBox = boundingBox
    }
}

struct RecognizedCardText: Sendable {
    let rawText: String
    let lines: [RecognizedCardTextLine]
    let languages: [String]
    nonisolated init(lines: [RecognizedCardTextLine], languages: [String]) {
        self.lines = lines
        self.rawText = lines.map(\.text).joined(separator: "\n")
        self.languages = languages
    }
}

enum CardTextRecognitionError: Error, LocalizedError, Equatable, Sendable {
    case emptyInput
    case undecodableImage
    case requestFailed(String)
    case noText
    case unavailableLanguages([String])
    nonisolated var errorDescription: String? {
        switch self {
        case .emptyInput: return "图片数据为空，请重新选择。"
        case .undecodableImage: return "图片无法解码，不能识别文字。"
        case .requestFailed(let reason): return "文字识别请求失败：\(reason)"
        case .noText: return "未识别到文字，可更换图片或恢复预处理图片后重试。"
        case .unavailableLanguages(let languages):
            return "当前 Vision 环境不支持所请求的语言：\(languages.joined(separator: "、"))。未执行识别。"
        }
    }
}

struct CardTextRecognitionService {
    nonisolated static let preferredLanguages = ["zh-Hans", "en-US"]

    /// 严格要求全部请求语言可用，不静默降级为仅英文。
    nonisolated static func validatedLanguages(requested: [String], supported: [String]) throws -> [String] {
        let missing = requested.filter { !supported.contains($0) }
        guard !requested.isEmpty, missing.isEmpty else {
            throw CardTextRecognitionError.unavailableLanguages(requested.isEmpty ? ["未指定语言"] : missing)
        }
        return requested
    }

    nonisolated static func supportedLanguages() throws -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        do { return try request.supportedRecognitionLanguages() }
        catch { throw CardTextRecognitionError.requestFailed(error.localizedDescription) }
    }

    /// 横排阅读顺序：先按上边缘从上到下，再以该行锚点归组，行内从左到右。
    /// [DECISION/TEMP] 归组容差为较小文本框高度的0.5；不承诺复杂分栏/竖排的语义顺序。
    nonisolated static func readingOrder(_ lines: [RecognizedCardTextLine]) -> [RecognizedCardTextLine] {
        let sorted = lines.sorted {
            if $0.boundingBox.maxY != $1.boundingBox.maxY { return $0.boundingBox.maxY > $1.boundingBox.maxY }
            if $0.boundingBox.minX != $1.boundingBox.minX { return $0.boundingBox.minX < $1.boundingBox.minX }
            return $0.text < $1.text
        }
        var rows: [[RecognizedCardTextLine]] = []
        for line in sorted {
            if let index = rows.firstIndex(where: { row in
                guard let anchor = row.first else { return false }
                return abs(anchor.boundingBox.midY - line.boundingBox.midY)
                    <= min(anchor.boundingBox.height, line.boundingBox.height) * 0.5
            }) {
                rows[index].append(line)
            } else { rows.append([line]) }
        }
        return rows.flatMap { row in
            row.sorted {
                if $0.boundingBox.minX != $1.boundingBox.minX { return $0.boundingBox.minX < $1.boundingBox.minX }
                return $0.boundingBox.maxY > $1.boundingBox.maxY
            }
        }
    }

    nonisolated static func recognize(_ data: Data, languages: [String] = preferredLanguages) throws -> RecognizedCardText {
        guard !data.isEmpty else { throw CardTextRecognitionError.emptyInput }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw CardTextRecognitionError.undecodableImage
        }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        // 保留 Vision 首选候选原文，不启用词典纠正或补充联系人字段。
        request.usesLanguageCorrection = false
        let supported: [String]
        do { supported = try request.supportedRecognitionLanguages() }
        catch { throw CardTextRecognitionError.requestFailed(error.localizedDescription) }
        let configured = try validatedLanguages(requested: languages, supported: supported)
        request.recognitionLanguages = configured
        do {
            try VNImageRequestHandler(cgImage: image, orientation: .up).perform([request])
        } catch { throw CardTextRecognitionError.requestFailed(error.localizedDescription) }
        let lines = (request.results ?? []).compactMap { observation -> RecognizedCardTextLine? in
            guard let candidate = observation.topCandidates(1).first, !candidate.string.isEmpty else { return nil }
            return RecognizedCardTextLine(text: candidate.string, confidence: candidate.confidence,
                                          boundingBox: observation.boundingBox)
        }
        guard !lines.isEmpty else { throw CardTextRecognitionError.noText }
        return RecognizedCardText(lines: readingOrder(lines), languages: configured)
    }
}
