import Foundation
import SwiftUI
import PhotosUI
import UIKit

/// 单张名片的采集、裁剪、识别、确认与保存流程。
@MainActor
struct CardImageImportView: View {
    let canSave: Bool
    let insertRecord: (BusinessCardRecord) async throws -> Void
    let onSaved: () -> Void
    @StateObject private var saveState = CardRecordSaveState()
    @State private var recognizedImageData: Data?
    @State private var assemblyError: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedItem: PhotosPickerItem?
    @State private var cameraPermissionRequest: UUID?
    @State private var showingCamera = false
    @State private var cameraResult: Result<Data, SingleCardCameraError>?
    @State private var capturedImageRequest: UUID?
    @State private var cameraMessage: String?
    @State private var previewImage: UIImage?
    @State private var preparedImage: PreparedCardImage?
    @State private var detection: CardRectangleDetectionResult?
    @State private var selectedCandidateIndex: Int?
    @State private var manualCrop: ManualCardCrop?
    @State private var cropMoveRejected = false
    @State private var correctedImage: CorrectedCardImage?
    @State private var ocrResult: RecognizedCardText?
    @State private var parsedContact: CardContactParseResult?
    @State private var showingCorrection = false
    @State private var showingPhotoPicker = false
    @State private var showingDiscardCorrection = false
    @State private var pendingAction: (() -> Void)?
    @State private var processingMessage: String?
    @State private var workflow = CardScanWorkflow()
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            stagePage
            .id(workflow.stage == .save ? CardScanWorkflow.Stage.review : workflow.stage)
            .navigationTitle(stageTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        protectCorrection {
                            clearPreview()
                            dismiss()
                        }
                    }
                    .disabled(saveState.isSaving)
                }
            }
            .safeAreaInset(edge: .bottom) {
                stageActions
            }
        }
        .interactiveDismissDisabled(workflow.correctionDraft != nil || saveState.isSaving)
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedItem, matching: .images)
        .sheet(isPresented: $showingCorrection) {
            if let parsedContact {
                let reviewRequest = workflow.request
                CardFieldCorrectionView(draft: workflow.correctionDraft ?? CardFieldCorrectionDraft(result: parsedContact)) { draft, _ in
                    guard workflow.applyCorrection(draft, for: reviewRequest) else { return }
                    saveState.reset()
                    assemblyError = nil
                }
            }
        }
        .confirmationDialog("此操作将清除尚未保存的人工校正，是否继续？", isPresented: $showingDiscardCorrection, titleVisibility: .visible) {
            Button("丢弃校正并继续", role: .destructive) {
                let action = pendingAction
                pendingAction = nil
                action?()
            }
            Button("取消", role: .cancel) { pendingAction = nil }
        }
        .fullScreenCover(isPresented: $showingCamera, onDismiss: {
            switch cameraResult {
            case .success: capturedImageRequest = UUID()
            case .failure(let error):
                cameraMessage = error.localizedDescription
                cameraResult = nil
            case nil: break
            }
        }) {
            SingleCardCameraView { result in
                cameraResult = result
                showingCamera = false
            }
        }
        .onDisappear { if !showingCorrection && !showingCamera { clearPreview() } }
        .task(id: cameraPermissionRequest) {
            guard let request = cameraPermissionRequest else { return }
            let issue = await SingleCardCameraView.accessIssue()
            guard !Task.isCancelled, cameraPermissionRequest == request else { return }
            cameraPermissionRequest = nil
            if let issue {
                cameraMessage = issue.localizedDescription
            } else {
                protectCorrection {
                    // 重拍从新会话开始，即使随后取消，也不会继续使用旧拍摄数据。
                    clearPreview()
                    showingCamera = true
                }
            }
        }
        .task(id: selectedItem) {
            guard let selectedItem else { return }
            cameraMessage = nil
            await loadImage {
                try await selectedItem.loadTransferable(type: Data.self)
            }
        }
        .task(id: capturedImageRequest) {
            guard capturedImageRequest != nil, case .success(let data) = cameraResult else { return }
            cameraResult = nil
            await loadImage { data }
        }
    }

    private var stageTitle: String {
        switch workflow.stage {
        case .source: "扫描名片"
        case .crop: "裁剪校正"
        case .recognition: "识别名片"
        case .review, .save: "识别结果"
        }
    }

    @ViewBuilder private var stagePage: some View {
        switch workflow.stage {
        case .review, .save:
            resultForm
        case .source, .crop, .recognition:
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let errorMessage {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                    stageContent
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
    }

    @ViewBuilder private var stageContent: some View {
        switch workflow.stage {
        case .source:
            sourceContent
        case .crop:
            cropContent
        case .recognition:
            if let previewImage { imagePreview(previewImage) }
            if isLoading {
                ProgressView("正在识别名片…")
            } else {
                Text("可以重试识别，或返回调整裁剪范围。")
                recognitionTranscript
            }
        case .review, .save:
            EmptyView()
        }
    }

    @ViewBuilder private var recognitionTranscript: some View {
        if let ocrResult {
            DisclosureGroup {
                Text(ocrResult.rawText).textSelection(.enabled)
            } label: {
                Text("查看识别原文")
                    .frame(minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
        }
    }

    private var sourceContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "viewfinder")
                .font(.largeTitle)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("选择图片来源")
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            Text("拍摄一张名片，或从相册选取名片图片。")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Button {
                    cameraMessage = nil
                    cameraPermissionRequest = UUID()
                } label: {
                    Label("拍摄名片", systemImage: "camera")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                Button {
                    selectedItem = nil
                    showingPhotoPicker = true
                } label: {
                    Label("从相册导入", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
            }
            .disabled(isLoading || cameraPermissionRequest != nil)

            if cameraPermissionRequest != nil {
                ProgressView("正在检查相机权限…")
            }
            if isLoading { ProgressView("正在准备图片…") }
            if let cameraMessage {
                Text(cameraMessage)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .frame(maxWidth: 440)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private var cropContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let previewImage { cropPreview(for: previewImage) }
            if isLoading, let processingMessage {
                ProgressView(processingMessage)
            } else if let processingMessage {
                Text(processingMessage).font(.callout)
            }
            if cropMoveRejected {
                Text("该位置会使边界无效，已保留上一个有效边界。")
                    .font(.callout).foregroundStyle(.red)
            }
            cropBoundaryControls
        }
    }

    private var cropBoundaryControls: some View {
        GroupBox("裁剪边界") {
            VStack(alignment: .leading, spacing: 10) {
                if let detection, let index = selectedCandidateIndex, detection.candidates.count > 1 {
                    Text("候选 \(index + 1)/\(detection.candidates.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button("上一个") { selectCandidate(index - 1) }
                            .disabled(index == 0)
                        Button("下一个") { selectCandidate(index + 1) }
                            .disabled(index + 1 >= detection.candidates.count)
                    }
                    .buttonStyle(.bordered)
                    Divider()
                }

                if manualCrop == nil {
                    Button("手动裁剪") { startManualCrop() }
                    Button("重新检测边界") { Task { await detectBoundary() } }
                } else {
                    Button {
                        startManualCrop()
                    } label: {
                        Label(selectedBoundary == nil ? "恢复手动初始区域" : "恢复自动候选区域",
                              systemImage: "arrow.counterclockwise")
                            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .disabled(isLoading)
        }
    }

    private func imagePreview(_ image: UIImage) -> some View {
        Image(uiImage: image).resizable().scaledToFit()
            .frame(maxHeight: 300)
            .accessibilityLabel("裁剪后的名片")
    }

    private var resultForm: some View {
        Form {
            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red) }
            }
            if let parsedContact {
                resultSections(workflow.reviewFields(initial: parsedContact))
            }
            if !canSave {
                Section { Text("测试数据源不提供正式保存。") }
            }
            if ocrResult != nil {
                Section("识别参考") {
                    recognitionTranscript
                }
            }
        }
    }

    @ViewBuilder private func resultSections(_ fields: ParsedContactFields) -> some View {
        Section("基本信息") {
            Text(fields.name ?? "姓名未识别")
                .font(.title2.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            resultField("公司", value: fields.company)
            resultField("职位", value: fields.jobTitle)
        }

        Section("电话号码") {
            if fields.phones.isEmpty {
                resultField("电话", value: nil)
            } else {
                ForEach(Array(fields.phones.enumerated()), id: \.offset) { _, phone in
                    resultField("电话 · " + phone.type.displayLabel, value: phone.value)
                }
            }
        }

        Section("电子邮箱") {
            if fields.emails.isEmpty {
                resultField("邮箱", value: nil)
            } else {
                ForEach(Array(fields.emails.enumerated()), id: \.offset) { _, email in
                    resultField("邮箱", value: email)
                }
            }
        }

        Section("网站与地址") {
            resultField("网站", value: fields.website)
            resultField("地址", value: fields.address)
        }
    }

    private func resultField(_ label: String, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Text(value ?? "未识别")
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private var stageActions: some View {
        if workflow.stage != .source {
            VStack(spacing: 8) {
                switch workflow.stage {
                case .source:
                    EmptyView()
                case .crop:
                    Button {
                        Task { await correctPerspective() }
                    } label: {
                        Text("确认裁剪")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || (manualCrop == nil && selectedBoundary == nil))
                    secondaryActionLayout {
                        secondaryAction("重新选图") { clearPreview() }
                        secondaryAction("重拍") {
                            clearPreview()
                            cameraPermissionRequest = UUID()
                        }
                    }
                case .recognition:
                    if !isLoading {
                        Button("重新识别") { Task { await recognizeText() } }
                            .buttonStyle(.borderedProminent)
                    }
                    secondaryAction("返回裁剪") { restorePreparedImage() }
                case .review, .save:
                    if let message = assemblyError ?? saveState.errorMessage {
                        Text(message).font(.callout).foregroundStyle(.red)
                    }
                    if saveState.isSaving {
                        ProgressView("正在保存名片…")
                    } else if let parsedContact, workflow.draftForSaving(initial: parsedContact) == nil,
                              workflow.stage == .review {
                        Text("请先通过「修改识别信息」补充姓名。").font(.callout)
                    }
                    Button {
                        Task { await saveConfirmedCard() }
                    } label: {
                        actionLabel("确认无误，保存名片")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave || saveState.savedID != nil ||
                              parsedContact.flatMap { workflow.draftForSaving(initial: $0) } == nil)
                    secondaryActionLayout {
                        secondaryAction("修改识别信息") { showingCorrection = true }
                        secondaryAction("返回裁剪") { protectCorrection { restorePreparedImage() } }
                    }
                    .disabled(workflow.stage == .save)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.regularMaterial)
        }
    }

    private var secondaryActionLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
    }

    private func secondaryAction(_ title: String, action: @escaping @MainActor () -> Void) -> some View {
        Button(action: action) { actionLabel(title) }
            .buttonStyle(.bordered)
    }

    private func actionLabel(_ title: String) -> some View {
        Text(title)
            .multilineTextAlignment(.center)
            .frame(minWidth: 44, maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
    }

    private func cropPreview(for image: UIImage) -> CardCropEditorView {
        let boundary = correctedImage == nil ? (manualCrop?.boundary ?? selectedBoundary) : nil
        let onMove: (@MainActor (Int, CGPoint) -> Void)?
        if manualCrop != nil, correctedImage == nil, !isLoading {
            onMove = { index, point in moveCropCorner(index, point) }
        } else {
            onMove = nil
        }
        return CardCropEditorView(image: image, boundary: boundary, onMove: onMove)
    }

    private func loadImage(readData: @MainActor () async throws -> Data?) async {
        guard !Task.isCancelled, workflow.stage == .source, !isLoading else { return }
        let request = workflow.beginRequest()
        isLoading = true
        errorMessage = nil
        previewImage = nil
        preparedImage = nil
        detection = nil
        selectedCandidateIndex = nil
        manualCrop = nil
        cropMoveRejected = false
        correctedImage = nil
        clearOCR()
        processingMessage = nil
        defer {
            if workflow.request == request { isLoading = false }
        }

        do {
            let data = try await readData()
            guard !Task.isCancelled, workflow.request == request else { return }
            guard let data else {
                errorMessage = "无法读取所选图片，请重新选择。"
                return
            }
            // ImageIO 在后台处理，关闭或换图后不提交旧结果。
            let result = try await Task.detached(priority: .userInitiated) {
                try CardImagePreparationService.prepare(data)
            }.value
            guard !Task.isCancelled, workflow.request == request else { return }
            guard let image = UIImage(data: result.processedData) else {
                throw CardImagePreparationError.processingOrEncodingFailed
            }
            guard workflow.advance(for: request, from: .source) else { return }
            preparedImage = result
            previewImage = image
            isLoading = false
            await detectBoundary()
        } catch {
            guard !Task.isCancelled, workflow.request == request else { return }
            errorMessage = "图片处理失败：\(error.localizedDescription)"
        }
    }

    private func saveConfirmedCard() async {
        guard canSave, !isLoading, !saveState.isSaving, saveState.savedID == nil,
              let preparedImage, let ocrResult, let parsedContact, let recognizedImageData,
              let draft = workflow.draftForSaving(initial: parsedContact),
              workflow.advance(for: workflow.request, from: .review) else { return }
        defer { workflow.finishSaveAttempt() }
        assemblyError = nil
        do {
            let record = try CardRecordAssemblyService.assemble(prepared: preparedImage,
                correctedData: correctedImage?.data, ocr: ocrResult, initial: parsedContact,
                draft: draft, recognizedImageData: recognizedImageData)
            let saved = await saveState.save(record, insert: insertRecord)
            if saved {
                onSaved()
                dismiss()
            }
        } catch { assemblyError = error.localizedDescription }
    }

    private func protectCorrection(_ action: @escaping () -> Void) {
        guard !saveState.isSaving else { return }
        if workflow.correctionDraft != nil {
            pendingAction = action
            showingDiscardCorrection = true
        } else { action() }
    }

    private func clearOCR() {
        recognizedImageData = nil
        assemblyError = nil
        saveState.reset()
        parsedContact = nil
        ocrResult = nil
    }

    private func recognizeText() async {
        guard workflow.stage == .recognition, !isLoading, let correctedImage else { return }
        let data = correctedImage.data
        let request = workflow.beginRequest()
        clearOCR()
        isLoading = true
        errorMessage = nil
        defer { if workflow.request == request { isLoading = false } }
        do {
            let result = try await Task.detached(priority: .userInitiated) {
                try CardTextRecognitionService.recognize(data)
            }.value
            guard !Task.isCancelled, workflow.request == request else { return }
            ocrResult = result
            let parsed = try CardContactFieldParser.parse(result)
            guard workflow.advance(for: request, from: .recognition) else { return }
            recognizedImageData = data
            parsedContact = parsed
        } catch {
            guard !Task.isCancelled, workflow.request == request else { return }
            errorMessage = error.localizedDescription
        }
    }

    private var selectedBoundary: CardQuadrilateral? {
        detection?.candidate(at: selectedCandidateIndex)?.boundary
    }

    private func startManualCrop() {
        guard workflow.stage == .crop, !isLoading, preparedImage != nil else { return }
        workflow.beginRequest()
        clearOCR()
        manualCrop = ManualCardCrop(candidate: selectedBoundary)
        cropMoveRejected = false
        errorMessage = nil
        processingMessage = nil
    }

    private func moveCropCorner(_ index: Int, _ point: CGPoint) {
        guard workflow.stage == .crop, !isLoading, var crop = manualCrop else { return }
        cropMoveRejected = !crop.moveCorner(at: index, to: point)
        manualCrop = crop
    }

    private func selectCandidate(_ index: Int) {
        guard workflow.stage == .crop, !isLoading, let candidate = detection?.candidate(at: index) else { return }
        selectedCandidateIndex = index
        manualCrop = ManualCardCrop(candidate: candidate.boundary)
        cropMoveRejected = false
        clearOCR()
        errorMessage = nil
        processingMessage = "已切换候选，请查看黄色轮廓并确认。"
    }

    private func detectBoundary() async {
        guard workflow.stage == .crop, !isLoading, let preparedImage, manualCrop == nil else { return }
        let request = workflow.beginRequest()
        isLoading = true
        errorMessage = nil
        detection = nil
        selectedCandidateIndex = nil
        cropMoveRejected = false
        processingMessage = "正在检测矩形候选…"
        defer { if workflow.request == request { isLoading = false } }
        do {
            let data = preparedImage.processedData
            let result = try await Task.detached(priority: .userInitiated) {
                try CardRectangleDetectionService.detect(data)
            }.value
            guard !Task.isCancelled, workflow.request == request, manualCrop == nil else { return }
            detection = result
            selectedCandidateIndex = result.candidates.isEmpty ? nil : 0
            if let boundary = result.boundary {
                manualCrop = ManualCardCrop(candidate: boundary)
                processingMessage = "拖动四角，使边界贴合名片，再确认裁剪。"
            } else {
                processingMessage = "未找到名片边界。请选择手动裁剪，或重新选图。"
            }
        } catch {
            guard !Task.isCancelled, workflow.request == request else { return }
            processingMessage = nil
            errorMessage = error.localizedDescription
        }
    }

    private func correctPerspective() async {
        guard workflow.stage == .crop, !isLoading, let preparedImage else { return }
        guard let boundary = manualCrop?.boundary ?? selectedBoundary, boundary.isValid else {
            errorMessage = "裁剪边界无效，请重新调整后确认。"
            return
        }
        let request = workflow.beginRequest()
        isLoading = true
        errorMessage = nil
        clearOCR()
        processingMessage = "正在应用透视矫正…"
        defer { if workflow.request == request { isLoading = false } }
        do {
            let data = preparedImage.processedData
            let result = try await Task.detached(priority: .userInitiated) {
                try CardPerspectiveCorrectionService.correct(data, boundary: boundary)
            }.value
            guard !Task.isCancelled, workflow.request == request else { return }
            guard let image = UIImage(data: result.data) else { throw CardRectangleProcessingError.correctionFailed }
            guard workflow.advance(for: request, from: .crop) else { return }
            correctedImage = result
            previewImage = image
            processingMessage = nil
            isLoading = false
            await recognizeText()
        } catch {
            guard !Task.isCancelled, workflow.request == request else { return }
            processingMessage = nil
            errorMessage = error.localizedDescription
        }
    }

    private func restorePreparedImage() {
        guard !saveState.isSaving, let preparedImage else { return }
        guard let image = UIImage(data: preparedImage.processedData) else {
            errorMessage = "无法恢复预处理图片，请重新选择。"
            return
        }
        workflow.returnToCrop()
        isLoading = false
        clearOCR()
        previewImage = image
        correctedImage = nil
        cropMoveRejected = false
        errorMessage = nil
        processingMessage = "调整边界后，再次确认裁剪。"
    }

    /// 关闭时使进行中的请求失效，并释放本流程持有的原图与处理结果。
    private func clearPreview() {
        workflow.reset()
        selectedItem = nil
        cameraPermissionRequest = nil
        cameraResult = nil
        capturedImageRequest = nil
        cameraMessage = nil
        clearOCR()
        detection = nil
        selectedCandidateIndex = nil
        manualCrop = nil
        cropMoveRejected = false
        correctedImage = nil
        processingMessage = nil
        preparedImage = nil
        previewImage = nil
        errorMessage = nil
        isLoading = false
    }
}

/// 每张图片共用一个请求标识，返回或开始新操作时旧结果失效。
struct CardScanWorkflow {
    enum Stage: Hashable {
        case source, crop, recognition, review, save
    }

    private(set) var stage: Stage = .source
    private(set) var request = UUID()
    private(set) var correctionDraft: CardFieldCorrectionDraft?

    @discardableResult
    mutating func beginRequest() -> UUID {
        request = UUID()
        return request
    }

    @discardableResult
    mutating func advance(for request: UUID, from stage: Stage) -> Bool {
        guard self.request == request, self.stage == stage else { return false }
        switch stage {
        case .source: self.stage = .crop
        case .crop: self.stage = .recognition
        case .recognition: self.stage = .review
        case .review: self.stage = .save
        case .save: return false
        }
        return true
    }

    @discardableResult
    mutating func applyCorrection(_ draft: CardFieldCorrectionDraft, for request: UUID) -> Bool {
        guard stage == .review, self.request == request else { return false }
        correctionDraft = draft
        return true
    }

    func reviewFields(initial: CardContactParseResult) -> ParsedContactFields {
        guard let correctionDraft, let fields = try? correctionDraft.confirmedFields() else {
            return initial.fields
        }
        return fields
    }

    func draftForSaving(initial: CardContactParseResult) -> CardFieldCorrectionDraft? {
        let draft = correctionDraft ?? CardFieldCorrectionDraft(result: initial)
        guard stage == .review, !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return draft
    }

    mutating func finishSaveAttempt() {
        if stage == .save { stage = .review }
    }

    mutating func returnToCrop() {
        beginRequest()
        correctionDraft = nil
        stage = .crop
    }

    mutating func reset() {
        beginRequest()
        correctionDraft = nil
        stage = .source
    }
}
