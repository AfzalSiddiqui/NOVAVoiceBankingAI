// NOVA Voice Banking AI
// CardRepository - Card operations data layer implementation

import Foundation

final class CardRepository: CardRepositoryProtocol, @unchecked Sendable {

    private let networkClient: NetworkClientProtocol

    private var mockCards: [Card] = [
        Card(
            id: "CARD001",
            accountId: "ACC001",
            cardNumber: "4532123456789012",
            cardType: .debit,
            cardNetwork: .visa,
            holderName: "AHMED AL MAKTOUM",
            expiryDate: "12/28",
            dailyLimit: 10_000,
            monthlyLimit: 50_000,
            currentMonthSpend: 8_750
        ),
        Card(
            id: "CARD002",
            accountId: "ACC001",
            cardNumber: "5412345678901234",
            cardType: .credit,
            cardNetwork: .mastercard,
            holderName: "AHMED AL MAKTOUM",
            expiryDate: "06/29",
            dailyLimit: 25_000,
            monthlyLimit: 100_000,
            currentMonthSpend: 15_200
        )
    ]

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func getCards() async throws -> [Card] {
        try await simulateDelay()
        return mockCards
    }

    func getCard(id: String) async throws -> Card {
        try await simulateDelay()
        guard let card = mockCards.first(where: { $0.id == id }) else {
            throw CardError.notFound
        }
        return card
    }

    func freezeCard(id: String) async throws -> Card {
        try await simulateDelay()
        guard let index = mockCards.firstIndex(where: { $0.id == id }) else {
            throw CardError.notFound
        }
        mockCards[index].isFrozen = true
        return mockCards[index]
    }

    func unfreezeCard(id: String) async throws -> Card {
        try await simulateDelay()
        guard let index = mockCards.firstIndex(where: { $0.id == id }) else {
            throw CardError.notFound
        }
        mockCards[index].isFrozen = false
        return mockCards[index]
    }

    func setDailyLimit(cardId: String, limit: Decimal) async throws -> Card {
        try await simulateDelay()
        guard let index = mockCards.firstIndex(where: { $0.id == cardId }) else {
            throw CardError.notFound
        }
        guard limit > 0 else { throw CardError.invalidLimit }
        mockCards[index].dailyLimit = limit
        return mockCards[index]
    }

    private func simulateDelay() async throws {
        try await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...300_000_000))
    }
}

// MARK: - Errors

enum CardError: LocalizedError, Sendable {
    case notFound
    case invalidLimit
    case alreadyFrozen
    case alreadyActive

    var errorDescription: String? {
        switch self {
        case .notFound: return "Card not found"
        case .invalidLimit: return "Invalid card limit"
        case .alreadyFrozen: return "Card is already frozen"
        case .alreadyActive: return "Card is already active"
        }
    }
}
