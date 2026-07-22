// NOVA Voice Banking AI
// MockRepositories - Test doubles for repository protocols

import Foundation
@testable import NOVA

final class MockBankingRepository: BankingRepositoryProtocol, @unchecked Sendable {
    var mockAccounts: [Account] = [Account.mock, Account.mockSavings]
    var mockTotalBalance: Decimal = 170_750.50
    var shouldThrow = false

    func getAccounts() async throws -> [Account] {
        if shouldThrow { throw BankingError.accountNotFound }
        return mockAccounts
    }

    func getAccount(id: String) async throws -> Account {
        if shouldThrow { throw BankingError.accountNotFound }
        guard let account = mockAccounts.first(where: { $0.id == id }) else {
            throw BankingError.accountNotFound
        }
        return account
    }

    func getBalance(accountId: String) async throws -> Decimal {
        let account = try await getAccount(id: accountId)
        return account.balance
    }

    func getTotalBalance() async throws -> Decimal {
        if shouldThrow { throw BankingError.accountNotFound }
        return mockTotalBalance
    }

    func transferMoney(from: String, to: String, amount: Decimal, currency: String, note: String?) async throws -> Transaction {
        if shouldThrow { throw BankingError.transferFailed }
        if amount <= 0 { throw BankingError.invalidAmount }
        return Transaction(
            accountId: from,
            type: .transfer,
            amount: amount,
            currency: currency,
            description: note ?? "Transfer",
            category: .transfer,
            counterpartyName: to
        )
    }
}

final class MockTransactionRepository: TransactionRepositoryProtocol, @unchecked Sendable {
    var mockTransactions: [Transaction] = [Transaction.mock]
    var shouldThrow = false

    func getTransactions(accountId: String?, filter: TransactionFilter?) async throws -> [Transaction] {
        if shouldThrow { throw TransactionError.fetchFailed }
        return mockTransactions
    }

    func getTransaction(id: String) async throws -> Transaction {
        if shouldThrow { throw TransactionError.notFound }
        guard let txn = mockTransactions.first(where: { $0.id == id }) else {
            throw TransactionError.notFound
        }
        return txn
    }

    func getRecentTransactions(limit: Int) async throws -> [Transaction] {
        if shouldThrow { throw TransactionError.fetchFailed }
        return Array(mockTransactions.prefix(limit))
    }

    func getSpendingByCategory(from: Date, to: Date) async throws -> [SpendingBreakdown] {
        if shouldThrow { throw TransactionError.fetchFailed }
        return [
            SpendingBreakdown(category: .food, amount: 3500, percentage: 35),
            SpendingBreakdown(category: .shopping, amount: 2800, percentage: 28),
            SpendingBreakdown(category: .transport, amount: 1200, percentage: 12)
        ]
    }

    func getMonthlySpending(months: Int) async throws -> [(month: String, amount: Decimal)] {
        if shouldThrow { throw TransactionError.fetchFailed }
        return [("Jul 2026", 15000), ("Jun 2026", 12500)]
    }

    func searchTransactions(query: String) async throws -> [Transaction] {
        if shouldThrow { throw TransactionError.fetchFailed }
        return mockTransactions.filter { $0.description.lowercased().contains(query.lowercased()) }
    }
}

final class MockCardRepository: CardRepositoryProtocol, @unchecked Sendable {
    var mockCards: [Card] = [Card.mock, Card.mockCredit]
    var shouldThrow = false

    func getCards() async throws -> [Card] {
        if shouldThrow { throw CardError.notFound }
        return mockCards
    }

    func getCard(id: String) async throws -> Card {
        if shouldThrow { throw CardError.notFound }
        guard let card = mockCards.first(where: { $0.id == id }) else {
            throw CardError.notFound
        }
        return card
    }

    func freezeCard(id: String) async throws -> Card {
        if shouldThrow { throw CardError.notFound }
        guard let index = mockCards.firstIndex(where: { $0.id == id }) else {
            throw CardError.notFound
        }
        mockCards[index].isFrozen = true
        return mockCards[index]
    }

    func unfreezeCard(id: String) async throws -> Card {
        if shouldThrow { throw CardError.notFound }
        guard let index = mockCards.firstIndex(where: { $0.id == id }) else {
            throw CardError.notFound
        }
        mockCards[index].isFrozen = false
        return mockCards[index]
    }

    func setDailyLimit(cardId: String, limit: Decimal) async throws -> Card {
        if shouldThrow { throw CardError.notFound }
        guard let index = mockCards.firstIndex(where: { $0.id == cardId }) else {
            throw CardError.notFound
        }
        mockCards[index].dailyLimit = limit
        return mockCards[index]
    }
}

final class MockWealthRepository: WealthRepositoryProtocol, @unchecked Sendable {
    var shouldThrow = false

    func getPortfolio() async throws -> WealthPortfolio {
        if shouldThrow { throw WealthError.portfolioUnavailable }
        return WealthPortfolio.mock
    }

    func getAsset(id: String) async throws -> Asset {
        if shouldThrow { throw WealthError.assetNotFound }
        guard let asset = Asset.mockAssets.first(where: { $0.id == id }) else {
            throw WealthError.assetNotFound
        }
        return asset
    }

    func getPerformanceHistory(period: PerformancePeriod) async throws -> [PerformancePoint] {
        if shouldThrow { throw WealthError.portfolioUnavailable }
        return PerformancePoint.mockHistory
    }

    func getAssetAllocation() async throws -> [AssetAllocation] {
        if shouldThrow { throw WealthError.portfolioUnavailable }
        return [AssetAllocation(type: .stock, percentage: 40, value: 120000)]
    }
}
