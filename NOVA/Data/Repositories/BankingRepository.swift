// NOVA Voice Banking AI
// BankingRepository - Banking operations data layer implementation

import Foundation

final class BankingRepository: BankingRepositoryProtocol, @unchecked Sendable {

    private let networkClient: NetworkClientProtocol
    private let storage: SecureStorageManagerProtocol

    private let mockAccounts: [Account] = [
        Account(
            id: "ACC001",
            accountNumber: "1234567890",
            accountType: .current,
            balance: 45_750.50,
            availableBalance: 44_500.00,
            holderName: "Ahmed Al Maktoum",
            iban: "AE070331234567890123456"
        ),
        Account(
            id: "ACC002",
            accountNumber: "0987654321",
            accountType: .savings,
            balance: 125_000.00,
            availableBalance: 125_000.00,
            holderName: "Ahmed Al Maktoum",
            iban: "AE070330987654321098765"
        ),
        Account(
            id: "ACC003",
            accountNumber: "5678901234",
            accountType: .investment,
            balance: 320_000.00,
            availableBalance: 320_000.00,
            holderName: "Ahmed Al Maktoum",
            iban: "AE070335678901234567890"
        )
    ]

    init(networkClient: NetworkClientProtocol, storage: SecureStorageManagerProtocol) {
        self.networkClient = networkClient
        self.storage = storage
    }

    func getAccounts() async throws -> [Account] {
        try await simulateDelay()
        return mockAccounts
    }

    func getAccount(id: String) async throws -> Account {
        try await simulateDelay()
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
        try await simulateDelay()
        return mockAccounts.reduce(Decimal.zero) { $0 + $1.balance }
    }

    func transferMoney(from: String, to: String, amount: Decimal, currency: String, note: String?) async throws -> Transaction {
        try await simulateDelay()

        guard amount > 0 else { throw BankingError.invalidAmount }
        let sourceAccount = try await getAccount(id: from)
        guard sourceAccount.availableBalance >= amount else { throw BankingError.insufficientFunds }

        return Transaction(
            accountId: from,
            type: .transfer,
            amount: amount,
            currency: currency,
            description: note ?? "Transfer to \(to)",
            category: .transfer,
            status: .completed,
            counterpartyName: to
        )
    }

    private func simulateDelay() async throws {
        try await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...400_000_000))
    }
}

// MARK: - Errors

enum BankingError: LocalizedError, Sendable {
    case accountNotFound
    case insufficientFunds
    case invalidAmount
    case transferFailed

    var errorDescription: String? {
        switch self {
        case .accountNotFound: return "Account not found"
        case .insufficientFunds: return "Insufficient funds for this transaction"
        case .invalidAmount: return "Invalid transaction amount"
        case .transferFailed: return "Transfer failed. Please try again."
        }
    }
}
