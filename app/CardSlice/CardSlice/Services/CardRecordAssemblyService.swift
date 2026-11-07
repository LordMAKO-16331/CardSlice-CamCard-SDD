import Foundation
import Combine

enum CardRecordAssemblyError: Error, LocalizedError {
    case missingName
    case missingImage
    case inconsistentSession
    case nonPersistentRepository
    var errorDescription: String? {
        switch self {
        case .missingName: return "保存名片前请在人工校正中填写姓名。"
        case .missingImage: return "原始图片或处理图片缺失，无法保存。"
        case .inconsistentSession: return "当前图片、OCR或校正结果不一致，请重新识别并确认。"
        case .nonPersistentRepository: return "当前为测试数据源，不能进行正式名片保存。"
        }
    }
}

@MainActor
struct CardRecordAssemblyService {
    static func assemble(prepared: PreparedCardImage, correctedData: Data?, ocr: RecognizedCardText,
                         initial: CardContactParseResult, draft: CardFieldCorrectionDraft,
                         recognizedImageData: Data, now: Date = Date()) throws -> BusinessCardRecord {
        let processed = correctedData ?? prepared.processedData
        guard !prepared.originalData.isEmpty, !processed.isEmpty else { throw CardRecordAssemblyError.missingImage }
        guard recognizedImageData == processed, initial.rawText == ocr.rawText, draft.original == initial else {
            throw CardRecordAssemblyError.inconsistentSession
        }
        let final = try draft.confirmedFields()
        guard let name = final.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CardRecordAssemblyError.missingName
        }
        return BusinessCardRecord(id: UUID(), originalImageData: prepared.originalData,
            processedImageData: processed, ocrRawText: ocr.rawText, parsedFields: initial.fields,
            name: name, company: final.company, jobTitle: final.jobTitle, phones: final.phones,
            emails: final.emails, website: final.website, address: final.address,
            tagIDs: [], notes: nil, createdAt: now, updatedAt: now)
    }
}

/// 同一次会话只插入一次；失败重试复用同一UUID，避免重试生成另一条记录。
@MainActor
final class CardRecordSaveState: ObservableObject {
    @Published private(set) var isSaving = false
    @Published private(set) var savedID: UUID?
    @Published private(set) var errorMessage: String?
    private var pendingRecord: BusinessCardRecord?

    func save(_ record: BusinessCardRecord, insert: (BusinessCardRecord) async throws -> Void) async -> Bool {
        guard !isSaving, savedID == nil else { return false }
        isSaving = true
        errorMessage = nil
        if pendingRecord == nil { pendingRecord = record }
        defer { isSaving = false }
        do {
            guard let pendingRecord else { return false }
            try await insert(pendingRecord)
            savedID = pendingRecord.id
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func reset() {
        guard !isSaving else { return }
        pendingRecord = nil; savedID = nil; errorMessage = nil
    }
}
