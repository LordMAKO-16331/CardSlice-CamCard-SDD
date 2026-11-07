import Testing
@testable import CardSlice

@MainActor
struct CardScanWorkflowTests {
    @Test func testSuccessfulStagesRequireReviewBeforeSave() {
        var workflow = CardScanWorkflow()
        let image = workflow.beginRequest()
        let prepared = workflow.advance(for: image, from: .source)
        #expect(prepared)
        #expect(workflow.stage == .crop)

        let crop = workflow.beginRequest()
        let corrected = workflow.advance(for: crop, from: .crop)
        #expect(corrected)
        #expect(workflow.stage == .recognition)

        let ocr = workflow.beginRequest()
        let recognized = workflow.advance(for: ocr, from: .recognition)
        #expect(recognized)
        #expect(workflow.stage == .review)

        let confirmed = workflow.advance(for: ocr, from: .review)
        #expect(confirmed)
        #expect(workflow.stage == .save)
        let repeated = workflow.advance(for: ocr, from: .review)
        #expect(!repeated)
    }

    @Test func testCancelledSourceRejectsOldImageCompletion() {
        var workflow = CardScanWorkflow()
        let abandoned = workflow.beginRequest()
        workflow.reset()
        let current = workflow.beginRequest()

        let oldCompletion = workflow.advance(for: abandoned, from: .source)
        #expect(!oldCompletion)
        #expect(workflow.stage == .source)

        let newCompletion = workflow.advance(for: current, from: .source)
        #expect(newCompletion)
        #expect(workflow.stage == .crop)
    }

    @Test func testCropAndRecognitionRemainInStageUntilSuccess() {
        var workflow = CardScanWorkflow()
        let image = workflow.beginRequest()
        workflow.advance(for: image, from: .source)

        let failedCrop = workflow.beginRequest()
        #expect(workflow.stage == .crop)
        let retryCrop = workflow.beginRequest()
        let lateCrop = workflow.advance(for: failedCrop, from: .crop)
        #expect(!lateCrop)
        workflow.advance(for: retryCrop, from: .crop)

        let failedOCR = workflow.beginRequest()
        #expect(workflow.stage == .recognition)
        let retryOCR = workflow.beginRequest()
        let lateOCR = workflow.advance(for: failedOCR, from: .recognition)
        #expect(!lateOCR)
        let recognized = workflow.advance(for: retryOCR, from: .recognition)
        #expect(recognized)
        #expect(workflow.stage == .review)
    }

    @Test func testReturningToCropInvalidatesRecognitionAndReview() {
        var workflow = CardScanWorkflow()
        let image = workflow.beginRequest()
        workflow.advance(for: image, from: .source)
        let crop = workflow.beginRequest()
        workflow.advance(for: crop, from: .crop)
        let ocr = workflow.beginRequest()

        workflow.returnToCrop()
        let lateOCR = workflow.advance(for: ocr, from: .recognition)
        #expect(!lateOCR)
        #expect(workflow.stage == .crop)

        let recrop = workflow.beginRequest()
        workflow.advance(for: recrop, from: .crop)
        let recognized = workflow.beginRequest()
        workflow.advance(for: recognized, from: .recognition)
        workflow.returnToCrop()
        let lateReview = workflow.advance(for: recognized, from: .review)
        #expect(!lateReview)
        #expect(workflow.stage == .crop)
    }

    private func reviewedWorkflow() -> CardScanWorkflow {
        var workflow = CardScanWorkflow()
        let request = workflow.beginRequest()
        workflow.advance(for: request, from: .source)
        workflow.advance(for: request, from: .crop)
        workflow.advance(for: request, from: .recognition)
        return workflow
    }

    @Test func testRecognitionPreviewCanSaveWithoutEditing() throws {
        var workflow = reviewedWorkflow()
        let parsed = CardContactParseResult(rawText: "示例原文", fields: ParsedContactFields(name: "林晓"), reviews: [])
        #expect(workflow.stage == .review)
        #expect(workflow.correctionDraft == nil)
        #expect(workflow.reviewFields(initial: parsed) == parsed.fields)
        let draft = try #require(workflow.draftForSaving(initial: parsed))
        #expect(try draft.confirmedFields().name == "林晓")

        let request = workflow.request
        let started = workflow.advance(for: request, from: .review)
        #expect(started)
        #expect(workflow.draftForSaving(initial: parsed) == nil)
        workflow.finishSaveAttempt()
        #expect(workflow.stage == .review)
        #expect(workflow.draftForSaving(initial: parsed)?.name == "林晓")
    }

    @Test func testConfirmedEditsAreUsedAndCancelledEditsAreIsolated() throws {
        var workflow = reviewedWorkflow()
        let parsed = CardContactParseResult(rawText: "林晓", fields: ParsedContactFields(name: "林晓"), reviews: [])
        let request = workflow.request
        var edited = CardFieldCorrectionDraft(result: parsed)
        edited.name = "林小"
        let applied = workflow.applyCorrection(edited, for: request)
        #expect(applied)

        // 取消时表单不会回传它的局部草稿。
        var cancelled = try #require(workflow.correctionDraft)
        cancelled.name = "未提交"
        #expect(cancelled.name != workflow.reviewFields(initial: parsed).name)
        #expect(workflow.reviewFields(initial: parsed).name == "林小")
        let draft = try #require(workflow.draftForSaving(initial: parsed))
        #expect(draft.name == "林小")
        #expect(draft.original == parsed)
        #expect(draft.original.rawText == "林晓")

        workflow.reset()
        let acceptedLate = workflow.applyCorrection(edited, for: request)
        #expect(!acceptedLate)
        #expect(workflow.correctionDraft == nil)
    }

    @Test func testMissingNameRequiresCorrectionBeforeSaving() {
        var workflow = reviewedWorkflow()
        let parsed = CardContactParseResult(rawText: "只有公司", fields: ParsedContactFields(company: "示例"), reviews: [])
        #expect(workflow.draftForSaving(initial: parsed) == nil)
        #expect(workflow.reviewFields(initial: parsed).name == nil)
        var draft = CardFieldCorrectionDraft(result: parsed)
        draft.name = "林晓"
        let request = workflow.request
        let applied = workflow.applyCorrection(draft, for: request)
        #expect(applied)
        #expect(workflow.draftForSaving(initial: parsed)?.name == "林晓")
    }

}
