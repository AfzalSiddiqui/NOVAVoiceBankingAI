// NOVA Voice Banking AI
// Banking Repository Protocol - Domain layer contract for banking operations

import Foundation

protocol BankingRepositoryProtocol: Sendable {
    func getAccounts() async throws -> [Account]
    func getAccount(id: String) async throws -> Account
    func getBalance(accountId: String) async throws -> Decimal
    func getTotalBalance() async throws -> Decimal
    func transferMoney(from: String, to: String, amount: Decimal, currency: String, note: String?) async throws -> Transaction
}
