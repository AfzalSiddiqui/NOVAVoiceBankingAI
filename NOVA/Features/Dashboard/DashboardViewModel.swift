// NOVA Voice Banking AI
// DashboardViewModel - Dashboard screen business logic

import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var totalBalance: Decimal = 0
    @Published var recentTransactions: [Transaction] = []
    @Published var insights: [FinancialInsight] = []
    @Published var spendingBreakdown: [SpendingBreakdown] = []
    @Published var isLoading = false
    @Published var error: String?

    private let container: DependencyContainer

    init(container: DependencyContainer = .shared) {
        self.container = container
    }

    func loadDashboard() async {
        isLoading = true
        error = nil

        do {
            async let accountsTask = container.bankingRepository.getAccounts()
            async let balanceTask = container.bankingRepository.getTotalBalance()
            async let transactionsTask = container.transactionRepository.getRecentTransactions(limit: 5)
            async let insightsTask = container.financialAdvisorUseCase.getInsights()
            async let spendingTask = container.transactionRepository.getSpendingByCategory(
                from: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
                to: Date()
            )

            accounts = try await accountsTask
            totalBalance = try await balanceTask
            recentTransactions = try await transactionsTask
            insights = try await insightsTask
            spendingBreakdown = try await spendingTask
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
