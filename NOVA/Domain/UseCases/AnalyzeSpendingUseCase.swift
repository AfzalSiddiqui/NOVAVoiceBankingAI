// NOVA Voice Banking AI
// AnalyzeSpendingUseCase - Analyzes user spending patterns

import Foundation

final class AnalyzeSpendingUseCase: Sendable {

    private let transactionRepository: TransactionRepositoryProtocol

    init(transactionRepository: TransactionRepositoryProtocol) {
        self.transactionRepository = transactionRepository
    }

    func execute(from: Date? = nil, to: Date? = nil) async throws -> SpendingAnalysisResult {
        let startDate = from ?? Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        let endDate = to ?? Date()

        let breakdown = try await transactionRepository.getSpendingByCategory(from: startDate, to: endDate)
        let monthlySpending = try await transactionRepository.getMonthlySpending(months: 6)
        let totalSpending = breakdown.reduce(Decimal.zero) { $0 + $1.amount }

        return SpendingAnalysisResult(
            breakdown: breakdown,
            totalSpending: totalSpending,
            monthlySpending: monthlySpending,
            period: startDate...endDate
        )
    }
}

struct SpendingAnalysisResult: Sendable {
    let breakdown: [SpendingBreakdown]
    let totalSpending: Decimal
    let monthlySpending: [(month: String, amount: Decimal)]
    let period: ClosedRange<Date>
}
