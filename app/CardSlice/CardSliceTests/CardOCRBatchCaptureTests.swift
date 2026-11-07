import Foundation
import UIKit
import XCTest
@testable import CardSlice

final class CardOCRBatchCaptureTests: XCTestCase {
    // P027-B1-F02 临时开关。取得先导附件后恢复为 false。
    private static let enableNewPhonePilotCapture = true

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

    @MainActor
    func testCaptureOCRBatch() async throws {
        let environment = ProcessInfo.processInfo.environment
        let simulatorName = environment["SIMULATOR_DEVICE_NAME"]
        let simulatorID = environment["SIMULATOR_UDID"] ?? "<未提供>"
        let os = "iOS " + UIDevice.current.systemVersion
        #if DEBUG
        let isDebug = true
        #else
        let isDebug = false
        #endif
        #if targetEnvironment(simulator)
        let isSimulator = true
        #else
        let isSimulator = false
        #endif
        let enabled = Self.enableNewPhonePilotCapture
        print("OCR pilot 环境：Debug=\(isDebug)，Simulator=\(isSimulator)，"
              + "SIMULATOR_DEVICE_NAME=\(simulatorName ?? "<未提供>")，"
              + "SIMULATOR_UDID=\(simulatorID)，系统=\(os)，临时开关=\(enabled)")
        try XCTSkipUnless(isDebug && isSimulator && simulatorName == "NewPhone" && enabled,
                          "先导采集只在已启用临时开关的 Debug NewPhone 模拟器运行。")

        let split = "pilot"
        let bundle = Bundle(for: CardOCRBatchCaptureTests.self)
        let manifestURL = try XCTUnwrap(bundle.url(forResource: "ground_truth", withExtension: "json"),
                                       "测试 Bundle 缺少 ground_truth.json。")
        let manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: manifestURL))
        let samples = manifest.samples.filter { $0.split == split }
        let sampleIDs = samples.map(\.sampleID)
        XCTAssertEqual(Set(sampleIDs), Set(["A", "B", "C", "D"]))
        guard !samples.isEmpty, Set(sampleIDs).count == samples.count else {
            XCTFail("采集分组为空或 sample_id 重复：\(split)")
            return
        }

        let resources = try XCTUnwrap(bundle.resourceURL, "找不到测试 Bundle 的资源目录。")
        let batchID = UUID().uuidString
        let timestamp = ISO8601DateFormatter()
        let device = try XCTUnwrap(simulatorName)
        var rows: [[String: Any]] = []
        var missingInputs: [String] = []

        for sample in samples {
            let input = imageURL(for: sample.image, in: resources)
            let output = await capture(input)
            var row: [String: Any] = [
                "sample_id": sample.sampleID,
                "source_image": sample.image,
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
            if output.inputUnavailable { missingInputs.append(sample.sampleID) }
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
        print("OCR batch \(batchID): \(file.path)")

        XCTAssertTrue(missingInputs.isEmpty, "未能读取输入：\(missingInputs.joined(separator: ", "))；已附上本批 JSON。")
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
        var inputUnavailable = false
        var inputVariant = "not_run"
    }

    @MainActor
    private func capture(_ input: URL?) async -> Capture {
        guard let input else { return Capture(error: "加载：图片路径须位于 test_data。", inputUnavailable: true) }
        let original: Data
        do {
            original = try Data(contentsOf: input)
        } catch {
            return Capture(error: "加载：\(error.localizedDescription)", inputUnavailable: true)
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

    @MainActor
    func testEvaluationFieldMapping() async throws {
        let fields = ParsedContactFields(name: "示例姓名", phones: [
            PhoneEntry(value: "+86 138-0000-0000", type: .mobile),
            PhoneEntry(value: "010-5555-0000", type: .office),
            PhoneEntry(value: "010-5555-0001", type: .fax)
        ], emails: ["a@example.com", "b@example.com"])
        let encoded = try JSONEncoder().encode(fieldArrays(fields))
        let decoded = try JSONDecoder().decode([String: [String]].self, from: encoded)
        XCTAssertEqual(decoded["name"], ["示例姓名"])
        XCTAssertEqual(decoded["mobile"], ["+86 138-0000-0000"])
        XCTAssertEqual(decoded["office"], ["010-5555-0000"])
        XCTAssertEqual(decoded["fax"], ["010-5555-0001"])
        XCTAssertEqual(decoded["email"], ["a@example.com", "b@example.com"])
        XCTAssertEqual(decoded["website"], [])
    }
}
