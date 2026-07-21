// NOVA Voice Banking AI
// FinancialAdvisorUseCase - AI-powered financial advice generation

import Foundation

final class FinancialAdvisorUseCase: Sendable {

    private let transactionRepository: TransactionRepositoryProtocol
    private let bankingRepository: BankingRepositoryProtocol
    private let aiResponseGenerator: AIResponseGeneratorProtocol

    init(
        transactionRepository: TransactionRepositoryProtocol,
        bankingRepository: BankingRepositoryProtocol,
        aiResponseGenerator: AIResponseGeneratorProtocol
    ) {
        self.transactionRepository = transactionRepository
        self.bankingRepository = bankingRepository
        self.aiResponseGenerator = aiResponseGenerator
    }

    func execute(query: String) async throws -> AIResponse {
        let accounts = try await bankingRepository.getAccounts()
        let savings = accounts.filter { $0.accountType == .savings }.reduce(Decimal.zero) { $0 + $1.balance }
        let monthlySpending = try await transactionRepository.getMonthlySpending(months: 1)
        let monthlyExpenses = monthlySpending.first?.amount ?? 15_000

        let breakdown = try await transactionRepository.getSpendingByCategory(
            from: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
            to: Date()
        )

        let topCategories = breakdown.prefix(3).map { ($0.category.displayName, $0.amount) }

        let summary = FinancialSummary(
            monthlyIncome: 25_000,
            monthlyExpenses: monthlyExpenses,
            savings: savings,
            topCategories: topCategories
        )

        return await aiResponseGenerator.generateFinancialAdvice(query: query, financialData: summary)
    }

    func getInsights() async throws -> [FinancialInsight] {
        FinancialInsight.mockInsights
    }
}
