import Foundation
import UIKit
import XCTest

final class CardSliceOCRCaptureTests: XCTestCase {
    private struct Manifest: Decodable {
        struct Sample: Decodable {
            let sampleID: String
            let image: String
            let split: String

            enum CodingKeys: String, CodingKey {
                case sampleID = "sample_id"
                case image, split
            }
        }

        let samples: [Sample]
    }

    private struct FormalManifest: Decodable {
        struct Sample: Decodable {
            let sampleID: String
            let image: String

            enum CodingKeys: String, CodingKey {
                case sampleID = "sample_id"
                case image
            }
        }

        let samples: [Sample]
    }

    private struct CaptureInput {
        let sampleID: String
        let sourceImage: String
        let url: URL?
    }

    @MainActor
    func testCapturePilotOCR() async throws {
        let split = "pilot"
        let bundle = Bundle(for: CardSliceOCRCaptureTests.self)
        let manifestURL = try XCTUnwrap(bundle.url(forResource: "ground_truth", withExtension: "json"),
                                       "测试 Bundle 缺少 ground_truth.json。")
        let manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: manifestURL))
        let samples = manifest.samples.filter { $0.split == split }
        let sampleIDs = samples.map(\.sampleID)
        guard samples.count == 4, Set(sampleIDs) == Set(["A", "B", "C", "D"]) else {
            XCTFail("先导清单必须恰好包含 A、B、C、D 各一条。")
            return
        }

        let resources = try XCTUnwrap(bundle.resourceURL, "找不到测试 Bundle 的资源目录。")
        let inputs = samples.map {
            CaptureInput(sampleID: $0.sampleID, sourceImage: $0.image, url: imageURL(for: $0.image, in: resources))
        }
        try await captureBatch(inputs, split: split)
    }

    @MainActor
    func testCaptureFormalOCR() async throws {
        let bundle = Bundle(for: CardSliceOCRCaptureTests.self)
        let manifestURL = try XCTUnwrap(bundle.url(forResource: "dataset_manifest", withExtension: "json"),
                                       "测试 Bundle 缺少正式数据集 dataset_manifest.json。")
        let manifest = try JSONDecoder().decode(FormalManifest.self, from: Data(contentsOf: manifestURL))
        let expectedIDs = Set((1...36).map { String(format: "F%02d", $0) })
        guard manifest.samples.count == expectedIDs.count,
              Set(manifest.samples.map(\.sampleID)) == expectedIDs else {
            XCTFail("正式清单必须恰好包含 F01～F36 各一条。")
            return
        }

        let resources = try XCTUnwrap(bundle.resourceURL, "找不到测试 Bundle 的资源目录。")
        let images = resources.appendingPathComponent("images", isDirectory: true)
        let inputs = manifest.samples.map { sample in
            let filename = sample.sampleID + ".png"
            let validPath = sample.image == "evaluation/formal/images/" + filename
            return CaptureInput(sampleID: sample.sampleID, sourceImage: sample.image,
                                url: validPath ? images.appendingPathComponent(filename) : nil)
        }
        try await captureBatch(inputs, split: "formal")
    }

    @MainActor
    private func captureBatch(_ inputs: [CaptureInput], split: String) async throws {
        let device = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? UIDevice.current.model
        let os = "iOS " + UIDevice.current.systemVersion
        let batchID = UUID().uuidString
        let timestamp = ISO8601DateFormatter()
        var rows: [[String: Any]] = []
        var failedSamples: [String] = []

        for sample in inputs {
            let output: Capture
            if sample.url == nil, split == "formal" {
                output = Capture(error: "加载：正式清单图片路径与样本 ID 不匹配。")
            } else {
                output = await capture(sample.url)
            }
            var row: [String: Any] = [
                "sample_id": sample.sampleID,
                "source_image": sample.sourceImage,
                "input_variant": output.inputVariant,
                "device": device,
                "os": os,
                "captured_at": timestamp.string(from: Date()),
                "ocr_raw_text": output.rawText,
                "ocr_languages": output.languages,
                "corrected_fields": NSNull(),
                "reference_parsed_fields": NSNull()
            ]
            if let fields = output.fields {
                row["parsed_fields"] = fields
            } else {
                row["parsed_fields"] = NSNull()
            }
            if let error = output.error { row["capture_error"] = error }
            if output.fields == nil || (split == "formal" && output.error != nil) {
                failedSamples.append(sample.sampleID)
            }
            rows.append(row)
        }

        let json = try JSONSerialization.data(withJSONObject: [
            "batch_id": batchID,
            "split": split,
            "results": rows
        ], options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("recognition_results-\(split)-\(batchID).json")
        try json.write(to: file, options: .atomic)
        let attachment = XCTAttachment(contentsOfFile: file)
        attachment.name = file.lastPathComponent
        attachment.lifetime = .keepAlways
        add(attachment)
        print("OCR \(split)：\(file.lastPathComponent) → \(file.path)")
        if split == "formal" {
            print("正式采集：成功 \(rows.count - failedSamples.count)，失败 \(failedSamples.count)，共 \(rows.count) 张。")
        }

        XCTAssertTrue(failedSamples.isEmpty,
                      "采集未完成：\(failedSamples.joined(separator: ", "))；已附上本批 JSON。")
    }

    private func imageURL(for path: String, in resources: URL) -> URL? {
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        guard components.count > 1, components.first == "test_data",
              components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else { return nil }
        return resources.appendingPathComponent(path)
    }

    private struct Capture {
        var rawText = ""
        var languages: [String] = []
        var fields: [String: [String]]?
        var error: String?
        var inputVariant = "not_run"
    }

    @MainActor
    private func capture(_ input: URL?) async -> Capture {
        guard let input else { return Capture(error: "加载：图片路径须位于 test_data。") }
        let original: Data
        do {
            original = try Data(contentsOf: input)
        } catch {
            return Capture(error: "加载：\(error.localizedDescription)")
        }

        let prepared: PreparedCardImage
        do {
            prepared = try await Task.detached(priority: .userInitiated) {
                try CardImagePreparationService.prepare(original)
            }.value
        } catch {
            return Capture(error: "预处理：\(error.localizedDescription)")
        }

        let ocr: RecognizedCardText
        let variant = "prepared_without_perspective_correction"
        do {
            ocr = try await Task.detached(priority: .userInitiated) {
                try CardTextRecognitionService.recognize(prepared.processedData)
            }.value
        } catch {
            // 无文字是已执行的空结果。运行环境或引擎故障不进入准确率分母。
            let fields: [String: [String]]? = (error as? CardTextRecognitionError) == .noText ? [:] : nil
            return Capture(fields: fields, error: "OCR：\(error.localizedDescription)",
                           inputVariant: variant)
        }

        do {
            let parsed = try CardContactFieldParser.parse(ocr)
            return Capture(rawText: ocr.rawText, languages: ocr.languages, fields: fieldArrays(parsed.fields),
                           inputVariant: variant)
        } catch {
            return Capture(rawText: ocr.rawText, languages: ocr.languages,
                           error: "解析：\(error.localizedDescription)",
                           inputVariant: variant)
        }
    }

    @MainActor
    private func fieldArrays(_ fields: ParsedContactFields) -> [String: [String]] {
        func values(_ value: String?) -> [String] { value.map { [$0] } ?? [] }
        var result = [
            "name": values(fields.name), "company": values(fields.company),
            "job_title": values(fields.jobTitle), "mobile": [], "office": [], "fax": [], "other_phone": [],
            "email": fields.emails, "website": values(fields.website), "address": values(fields.address)
        ]
        for phone in fields.phones {
            let key: String
            switch phone.type {
            case .mobile: key = "mobile"
            case .office: key = "office"
            case .fax: key = "fax"
            case .other: key = "other_phone"
            }
            result[key, default: []].append(phone.value)
        }
        return result
    }
}
