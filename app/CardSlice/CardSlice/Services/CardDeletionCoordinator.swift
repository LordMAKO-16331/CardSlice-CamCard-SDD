import Foundation

@MainActor
final class CardDeletionCoordinator {
    enum Phase: Equatable {
        case idle
        case awaitingConfirmation
        case deleting
        case deleted
    }

    private(set) var phase: Phase = .idle
    let id: UUID
    private let repository: any CardRepository

    init(id: UUID, repository: any CardRepository) {
        self.id = id
        self.repository = repository
    }

    func requestConfirmation() {
        guard phase == .idle else { return }
        phase = .awaitingConfirmation
    }

    func cancel() {
        guard phase == .awaitingConfirmation else { return }
        phase = .idle
    }

    func confirm() async throws -> Bool {
        guard phase == .awaitingConfirmation else { return false }
        phase = .deleting
        do {
            try await repository.delete(id: id)
            phase = .deleted
            return true
        } catch {
            phase = .idle
            throw error
        }
    }
}
