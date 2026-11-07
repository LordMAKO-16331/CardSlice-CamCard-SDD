import SwiftUI
import UIKit

/// 预览为左上原点，裁剪服务使用左下原点的归一化坐标。
struct CardCropPreviewGeometry {
    let imageFrame: CGRect

    init(imageSize: CGSize, viewport: CGSize) {
        let scale = min(viewport.width / imageSize.width, viewport.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        imageFrame = CGRect(x: (viewport.width - width) / 2, y: (viewport.height - height) / 2,
                            width: width, height: height)
    }

    func displayPoint(for point: CGPoint) -> CGPoint {
        CGPoint(x: imageFrame.minX + point.x * imageFrame.width,
                y: imageFrame.minY + (1 - point.y) * imageFrame.height)
    }

    func normalizedPoint(for point: CGPoint) -> CGPoint? {
        guard imageFrame.width > 0, imageFrame.height > 0, point.x.isFinite, point.y.isFinite else { return nil }
        let x = (point.x - imageFrame.minX) / imageFrame.width
        let y = 1 - (point.y - imageFrame.minY) / imageFrame.height
        return CGPoint(x: min(max(x, 0), 1), y: min(max(y, 0), 1))
    }
}

struct ManualCardCrop {
    private(set) var boundary: CardQuadrilateral

    init(candidate: CardQuadrilateral?) {
        boundary = candidate.flatMap { $0.isValid ? $0 : nil } ?? CardQuadrilateral(
            topLeft: CGPoint(x: 0.12, y: 0.88), topRight: CGPoint(x: 0.88, y: 0.88),
            bottomLeft: CGPoint(x: 0.12, y: 0.12), bottomRight: CGPoint(x: 0.88, y: 0.12)
        )
    }

    @discardableResult
    mutating func moveCorner(at index: Int, to point: CGPoint) -> Bool {
        var points = boundary.points
        guard points.indices.contains(index) else { return false }
        points[index] = point
        let proposed = CardQuadrilateral(topLeft: points[0], topRight: points[1],
                                         bottomLeft: points[3], bottomRight: points[2])
        guard proposed.isValid else { return false }
        boundary = proposed
        return true
    }
}

struct CardCropEditorView: View {
    let image: UIImage
    let boundary: CardQuadrilateral?
    let onMove: (@MainActor (Int, CGPoint) -> Void)?
    @State private var dragOrigin: CGPoint?

    init(image: UIImage, boundary: CardQuadrilateral?, onMove: (@MainActor (Int, CGPoint) -> Void)?) {
        self.image = image
        self.boundary = boundary
        self.onMove = onMove
    }

    var body: some View {
        GeometryReader { proxy in
            let geometry = CardCropPreviewGeometry(imageSize: image.size, viewport: proxy.size)
            let frame = geometry.imageFrame
            ZStack(alignment: .topLeading) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
                if let boundary {
                    let points = boundary.points.map { geometry.displayPoint(for: $0) }
                    Path { path in
                        path.addLines(points)
                        path.closeSubpath()
                    }
                    .stroke(.yellow, lineWidth: 3)
                    .allowsHitTesting(false)

                    if let onMove {
                        ForEach(points.indices, id: \.self) { index in
                            Circle()
                                .fill(.yellow)
                                .overlay { Circle().strokeBorder(.black, lineWidth: 2) }
                                .frame(width: 18, height: 18)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                                .position(points[index])
                                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("cardCropPreview"))
                                    .onChanged { value in
                                        let origin = dragOrigin ?? points[index]
                                        dragOrigin = origin
                                        let position = CGPoint(x: origin.x + value.translation.width,
                                                               y: origin.y + value.translation.height)
                                        if let point = geometry.normalizedPoint(for: position) { onMove(index, point) }
                                    }
                                    .onEnded { _ in dragOrigin = nil })
                                .accessibilityLabel(["左上角", "右上角", "右下角", "左下角"][index])
                                .accessibilityHint("拖动以调整裁剪边界")
                        }
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .coordinateSpace(name: "cardCropPreview")
        }
        .aspectRatio(4.0 / 3.0, contentMode: .fit)
        // 让触摸区域在边缘也能完整保留。
        .padding(22)
    }
}
