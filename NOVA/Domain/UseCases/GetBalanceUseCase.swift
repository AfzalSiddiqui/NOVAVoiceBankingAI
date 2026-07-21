// NOVA Voice Banking AI
// GetBalanceUseCase - Retrieves account balance information

import Foundation

final class GetBalanceUseCase: Sendable {

    private let repository: BankingRepositoryProtocol

    init(repository: BankingRepositoryProtocol) {
        self.repository = repository
    }

    func execute(accountId: String? = nil) async throws -> BalanceResult {
        if let accountId {
            let account = try await repository.getAccount(id: accountId)
            return BalanceResult(
                totalBalance: account.balance,
                availableBalance: account.availableBalance,
                accounts: [account]
            )
        }

        let accounts = try await repository.getAccounts()
        let totalBalance = try await repository.getTotalBalance()
        let availableBalance = accounts.reduce(Decimal.zero) { $0 + $1.availableBalance }

        return BalanceResult(
            totalBalance: totalBalance,
            availableBalance: availableBalance,
            accounts: accounts
        )
    }
}

struct BalanceResult: Sendable {
    let totalBalance: Decimal
    let availableBalance: Decimal
    let accounts: [Account]
}
