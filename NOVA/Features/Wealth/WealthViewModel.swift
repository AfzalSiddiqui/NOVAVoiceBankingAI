// NOVA Voice Banking AI
// WealthViewModel - Wealth/investment screen business logic

import Foundation

@MainActor
final class WealthViewModel: ObservableObject {
    @Published var portfolio: WealthPortfolio?
    @Published var allocation: [AssetAllocation] = []
    @Published var performanceHistory: [PerformancePoint] = []
    @Published var selectedPeriod: PerformancePeriod = .month
    @Published var isLoading = false
    @Published var error: String?

    private let container: DependencyContainer

    init(container: DependencyContainer = .shared) {
        self.container = container
    }

    func loadPortfolio() async {
        isLoading = true
        error = nil

        do {
            async let portfolioTask = container.wealthRepository.getPortfolio()
            async let allocationTask = container.wealthRepository.getAssetAllocation()
            async let historyTask = container.wealthRepository.getPerformanceHistory(period: selectedPeriod)

            portfolio = try await portfolioTask
            allocation = try await allocationTask
            performanceHistory = try await historyTask
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func changePeriod(_ period: PerformancePeriod) async {
        selectedPeriod = period
        do {
            performanceHistory = try await container.wealthRepository.getPerformanceHistory(period: period)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
