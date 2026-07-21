// NOVA Voice Banking AI
// Card Repository Protocol - Domain layer contract for card operations

import Foundation

protocol CardRepositoryProtocol: Sendable {
    func getCards() async throws -> [Card]
    func getCard(id: String) async throws -> Card
    func freezeCard(id: String) async throws -> Card
    func unfreezeCard(id: String) async throws -> Card
    func setDailyLimit(cardId: String, limit: Decimal) async throws -> Card
}
