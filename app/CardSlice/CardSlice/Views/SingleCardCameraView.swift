import AVFoundation
import ImageIO
import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum SingleCardCameraError: LocalizedError {
    case unavailable
    case denied
    case restricted
    case unreadablePhoto

    var errorDescription: String? {
        switch self {
        case .unavailable: "当前设备没有可用相机，可从相册导入。"
        case .denied: "相机权限已拒绝，可在系统设置中允许访问相机，或从相册导入。"
        case .restricted: "系统限制了相机访问，可从相册导入。"
        case .unreadablePhoto: "无法读取拍摄的图片，请重拍或从相册导入。"
        }
    }
}

enum SingleCardCameraAccess: Equatable {
    case ready
    case request
    case blocked(SingleCardCameraError)

    static func evaluate(available: Bool, status: AVAuthorizationStatus) -> Self {
        guard available else { return .blocked(.unavailable) }
        switch status {
        case .authorized: return .ready
        case .notDetermined: return .request
        case .denied: return .blocked(.denied)
        case .restricted: return .blocked(.restricted)
        @unknown default: return .blocked(.restricted)
        }
    }
}

@MainActor
struct SingleCardCameraView: UIViewControllerRepresentable {
    // nil 表示取消，且没有图片需要进入处理流程。
    let onFinish: (Result<Data, SingleCardCameraError>?) -> Void

    static func accessIssue() async -> SingleCardCameraError? {
        let available = UIImagePickerController.isSourceTypeAvailable(.camera)
        switch SingleCardCameraAccess.evaluate(available: available, status: AVCaptureDevice.authorizationStatus(for: .video)) {
        case .ready: return nil
        case .request: return await AVCaptureDevice.requestAccess(for: .video) ? nil : .denied
        case .blocked(let error): return error
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    func makeUIViewController(context: Context) -> UIViewController {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            let coordinator = context.coordinator
            Task { @MainActor in coordinator.finish(.failure(.unavailable)) }
            return UIViewController()
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.image.identifier]
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private var onFinish: ((Result<Data, SingleCardCameraError>?) -> Void)?

        init(onFinish: @escaping (Result<Data, SingleCardCameraError>?) -> Void) {
            self.onFinish = onFinish
        }

        func finish(_ result: Result<Data, SingleCardCameraError>?) {
            let callback = onFinish
            onFinish = nil
            callback?(result)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            finish(nil)
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let url = info[.imageURL] as? URL, let data = try? Data(contentsOf: url), !data.isEmpty {
                finish(.success(data))
            } else if let image = info[.originalImage] as? UIImage, let data = Self.encodePhoto(image) {
                finish(.success(data))
            } else {
                finish(.failure(.unreadablePhoto))
            }
        }

        private static func encodePhoto(_ image: UIImage) -> Data? {
            // 相机通常只提供 UIImage。按原像素编码，并写入 EXIF 方向供现有 ImageIO 管线使用。
            guard let pixels = image.cgImage else { return nil }
            let data = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
                return nil
            }
            let orientation: CGImagePropertyOrientation
            switch image.imageOrientation {
            case .up: orientation = .up
            case .down: orientation = .down
            case .left: orientation = .left
            case .right: orientation = .right
            case .upMirrored: orientation = .upMirrored
            case .downMirrored: orientation = .downMirrored
            case .leftMirrored: orientation = .leftMirrored
            case .rightMirrored: orientation = .rightMirrored
            @unknown default: return nil
            }
            let properties: [String: Any] = [
                kCGImagePropertyOrientation as String: orientation.rawValue,
                kCGImageDestinationLossyCompressionQuality as String: 1.0
            ]
            CGImageDestinationAddImage(destination, pixels, properties as CFDictionary)
            return CGImageDestinationFinalize(destination) ? data as Data : nil
        }
    }
}
