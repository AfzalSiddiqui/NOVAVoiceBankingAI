// NOVA Voice Banking AI
// Transaction Repository Protocol - Domain layer contract for transaction operations

import Foundation

protocol TransactionRepositoryProtocol: Sendable {
    func getTransactions(accountId: String?, filter: TransactionFilter?) async throws -> [Transaction]
    func getTransaction(id: String) async throws -> Transaction
    func getRecentTransactions(limit: Int) async throws -> [Transaction]
    func getSpendingByCategory(from: Date, to: Date) async throws -> [SpendingBreakdown]
    func getMonthlySpending(months: Int) async throws -> [(month: String, amount: Decimal)]
    func searchTransactions(query: String) async throws -> [Transaction]
}
