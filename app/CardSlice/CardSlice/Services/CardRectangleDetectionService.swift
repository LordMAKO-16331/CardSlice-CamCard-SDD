import Foundation
import CoreGraphics
import ImageIO
import Vision

struct CardQuadrilateral: Sendable {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint

    nonisolated init(topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) {
        self.topLeft = topLeft; self.topRight = topRight
        self.bottomLeft = bottomLeft; self.bottomRight = bottomRight
    }

    /// Vision/Core Image 均采用左下原点；按顺时针顺序排列。
    nonisolated var points: [CGPoint] { [topLeft, topRight, bottomRight, bottomLeft] }

    nonisolated var area: CGFloat {
        let p = points
        return abs((0..<4).reduce(CGFloat.zero) { value, i in
            let next = p[(i + 1) % 4]
            return value + p[i].x * next.y - next.x * p[i].y
        }) / 2
    }

    nonisolated var isValid: Bool {
        let p = points
        guard p.allSatisfy({ $0.x.isFinite && $0.y.isFinite && (0...1).contains($0.x) && (0...1).contains($0.y) }),
              area > 0.0001,
              topLeft.x < topRight.x, bottomLeft.x < bottomRight.x,
              topLeft.y > bottomLeft.y, topRight.y > bottomRight.y else { return false }
        // 严格凸、顺时针，拒绝自交、共线和错误的角点顺序。
        return (0..<4).allSatisfy { i in
            let a = p[i], b = p[(i + 1) % 4], c = p[(i + 2) % 4]
            return (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x) < -0.000001
        }
    }

    nonisolated func pixelPoints(in extent: CGRect) throws -> [CGPoint] {
        guard isValid, !extent.isNull, !extent.isInfinite,
              extent.origin.x.isFinite, extent.origin.y.isFinite,
              extent.width.isFinite, extent.height.isFinite,
              extent.width > 0, extent.height > 0 else { throw CardRectangleProcessingError.invalidBoundary }
        return points.map { CGPoint(x: extent.minX + $0.x * extent.width, y: extent.minY + $0.y * extent.height) }
    }
}

struct CardRectangleCandidate: Sendable {
    let boundary: CardQuadrilateral
    let confidence: Float
    let relativeArea: CGFloat
    /// 两条水平边平均长度 / 两条垂直边平均长度（像素空间），不是规范化框比例。
    let aspectRatio: CGFloat
    let isNearImageBorder: Bool

    nonisolated init(boundary: CardQuadrilateral, confidence: Float, pixelWidth: Int, pixelHeight: Int) {
        self.boundary = boundary; self.confidence = confidence
        relativeArea = boundary.area
        func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
            hypot((a.x - b.x) * CGFloat(pixelWidth), (a.y - b.y) * CGFloat(pixelHeight))
        }
        let width = distance(boundary.topLeft, boundary.topRight) + distance(boundary.bottomLeft, boundary.bottomRight)
        let height = distance(boundary.topLeft, boundary.bottomLeft) + distance(boundary.topRight, boundary.bottomRight)
        aspectRatio = pixelWidth > 0 && pixelHeight > 0 && height > 0 ? width / height : 0
        // [DECISION/TEMP] 四边都贴近2%边缘且面积超过85%时标记外框；保留供用户选择。
        let points = boundary.points
        isNearImageBorder = boundary.area >= 0.85
            && (points.map(\.x).min() ?? 1) <= 0.02 && (points.map(\.x).max() ?? 0) >= 0.98
            && (points.map(\.y).min() ?? 1) <= 0.02 && (points.map(\.y).max() ?? 0) >= 0.98
    }

    nonisolated var isValid: Bool {
        boundary.isValid && confidence.isFinite && (0...1).contains(confidence)
            && aspectRatio.isFinite && aspectRatio > 0 && relativeArea.isFinite
    }
}

struct CardRectangleDetectionResult: Sendable {
    let candidates: [CardRectangleCandidate]
    let pixelWidth: Int
    let pixelHeight: Int
    // 兼容原有测试的首候选摘要；UI矫正必须走明确选中的索引。
    nonisolated var boundary: CardQuadrilateral? { candidates.first?.boundary }
    nonisolated var confidence: Float? { candidates.first?.confidence }
    nonisolated var isDetected: Bool { !candidates.isEmpty }
    nonisolated init(candidates: [CardRectangleCandidate], pixelWidth: Int, pixelHeight: Int) {
        self.candidates = candidates; self.pixelWidth = pixelWidth; self.pixelHeight = pixelHeight
    }
    nonisolated func candidate(at index: Int?) -> CardRectangleCandidate? {
        guard let index, candidates.indices.contains(index) else { return nil }
        return candidates[index]
    }
    nonisolated func selectedBoundary(at index: Int?, confirmed: Bool) throws -> CardQuadrilateral {
        guard confirmed, let candidate = candidate(at: index), candidate.isValid else {
            throw CardRectangleProcessingError.invalidBoundary
        }
        return candidate.boundary
    }
}

enum CardRectangleProcessingError: Error, LocalizedError, Equatable, Sendable {
    case invalidImage
    case invalidBoundary
    case visionFailed(String)
    case correctionFailed
    nonisolated var errorDescription: String? {
        switch self {
        case .invalidImage: return "图片为空或无法解码，请重新选择。"
        case .invalidBoundary: return "边界坐标不合法，无法执行透视矫正。"
        case .visionFailed(let reason): return "矩形检测失败：\(reason)"
        case .correctionFailed: return "透视矫正或图片编码失败，请恢复预处理图片。"
        }
    }
}

struct CardRectangleDetectionService {
    nonisolated static func decode(_ data: Data) throws -> CGImage {
        guard !data.isEmpty,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              image.width > 0, image.height > 0 else { throw CardRectangleProcessingError.invalidImage }
        return image
    }

    nonisolated static func detect(_ data: Data) throws -> CardRectangleDetectionResult {
        let image = try decode(data)
        let request = VNDetectRectanglesRequest()
        // [DECISION/TEMP] 宽松候选参数，非课程准确率承诺。
        request.minimumConfidence = 0.5
        request.minimumSize = 0.15
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 1.0
        request.quadratureTolerance = 30
        request.maximumObservations = 16
        do {
            try VNImageRequestHandler(cgImage: image, orientation: .up).perform([request])
        } catch {
            throw CardRectangleProcessingError.visionFailed(error.localizedDescription)
        }
        let candidates = (request.results ?? []).map { observation in
            CardRectangleCandidate(boundary: CardQuadrilateral(
                topLeft: observation.topLeft, topRight: observation.topRight,
                bottomLeft: observation.bottomLeft, bottomRight: observation.bottomRight),
                confidence: observation.confidence, pixelWidth: image.width, pixelHeight: image.height)
        }
        return CardRectangleDetectionResult(candidates: rankedCandidates(candidates),
                                            pixelWidth: image.width, pixelHeight: image.height)
    }

    /// [DECISION/TEMP] 非贴边候选优先；组内按面积平方根×置信度排序，减弱大面积优势。
    /// 仅几何启发式，不判定名片类别；贴边大矩形仍保留，可能就是真实名片。
    nonisolated static func rankedCandidates(_ candidates: [CardRectangleCandidate]) -> [CardRectangleCandidate] {
        candidates.filter { $0.isValid }.sorted { a, b in
            if a.isNearImageBorder != b.isNearImageBorder { return !a.isNearImageBorder }
            let scoreA = sqrt(a.relativeArea) * CGFloat(a.confidence)
            let scoreB = sqrt(b.relativeArea) * CGFloat(b.confidence)
            if scoreA != scoreB { return scoreA > scoreB }
            if a.relativeArea != b.relativeArea { return a.relativeArea > b.relativeArea }
            if a.confidence != b.confidence { return a.confidence > b.confidence }
            for (p, q) in zip(a.boundary.points, b.boundary.points) {
                if p.x != q.x { return p.x < q.x }
                if p.y != q.y { return p.y < q.y }
            }
            return false
        }
    }
}
