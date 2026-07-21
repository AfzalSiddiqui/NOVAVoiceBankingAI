// NOVA Voice Banking AI
// FreezeCardUseCase - Handles card freeze/unfreeze operations

import Foundation

final class FreezeCardUseCase: Sendable {

    private let repository: CardRepositoryProtocol

    init(repository: CardRepositoryProtocol) {
        self.repository = repository
    }

    func freeze(cardId: String) async throws -> Card {
        try await repository.freezeCard(id: cardId)
    }

    func unfreeze(cardId: String) async throws -> Card {
        try await repository.unfreezeCard(id: cardId)
    }

    func getCards() async throws -> [Card] {
        try await repository.getCards()
    }

    func setLimit(cardId: String, dailyLimit: Decimal) async throws -> Card {
        try await repository.setDailyLimit(cardId: cardId, limit: dailyLimit)
    }
}
