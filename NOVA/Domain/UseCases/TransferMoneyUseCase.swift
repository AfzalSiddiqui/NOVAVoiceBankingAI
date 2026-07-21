// NOVA Voice Banking AI
// TransferMoneyUseCase - Handles money transfers with fraud checking

import Foundation

final class TransferMoneyUseCase: Sendable {

    private let repository: BankingRepositoryProtocol
    private let fraudDetector: FraudDetectionUseCase

    init(repository: BankingRepositoryProtocol, fraudDetector: FraudDetectionUseCase) {
        self.repository = repository
        self.fraudDetector = fraudDetector
    }

    func execute(from: String, to: String, amount: Decimal, currency: String = "AED", note: String? = nil) async throws -> TransferResult {
        // Run fraud check
        let fraudScore = await fraudDetector.execute(
            amount: amount,
            location: "Dubai, UAE",
            isNewRecipient: false
        )

        if fraudScore.recommendation == .block {
            return TransferResult(
                transaction: nil,
                fraudScore: fraudScore,
                status: .blocked
            )
        }

        if fraudScore.recommendation == .requireVerification {
            return TransferResult(
                transaction: nil,
                fraudScore: fraudScore,
                status: .requiresVerification
            )
        }

        let transaction = try await repository.transferMoney(
            from: from, to: to, amount: amount, currency: currency, note: note
        )

        return TransferResult(
            transaction: transaction,
            fraudScore: fraudScore,
            status: .completed
        )
    }
}

struct TransferResult: Sendable {
    let transaction: Transaction?
    let fraudScore: FraudScore
    let status: TransferStatus

    enum TransferStatus: Sendable {
        case completed
        case requiresVerification
        case blocked
    }
}
