// NOVA Voice Banking AI
// GetTransactionsUseCase - Retrieves and filters transactions

import Foundation

final class GetTransactionsUseCase: Sendable {

    private let repository: TransactionRepositoryProtocol

    init(repository: TransactionRepositoryProtocol) {
        self.repository = repository
    }

    func execute(accountId: String? = nil, filter: TransactionFilter? = nil) async throws -> [Transaction] {
        try await repository.getTransactions(accountId: accountId, filter: filter)
    }

    func getRecent(limit: Int = 10) async throws -> [Transaction] {
        try await repository.getRecentTransactions(limit: limit)
    }

    func search(query: String) async throws -> [Transaction] {
        try await repository.searchTransactions(query: query)
    }
}
