// NOVA Voice Banking AI
// TransactionsViewModel - Transactions screen business logic

import Foundation
import Combine

@MainActor
final class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var filteredTransactions: [Transaction] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: Transaction.Category?
    @Published var selectedType: Transaction.TransactionType?
    @Published var isLoading = false
    @Published var error: String?

    private let container: DependencyContainer
    private var cancellables = Set<AnyCancellable>()

    init(container: DependencyContainer = .shared) {
        self.container = container
        setupSearch()
    }

    private func setupSearch() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }

    func loadTransactions() async {
        isLoading = true
        error = nil

        do {
            transactions = try await container.getTransactionsUseCase.execute()
            applyFilters()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func applyFilters() {
        var result = transactions

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.description.lowercased().contains(query) ||
                ($0.merchantName?.lowercased().contains(query) ?? false) ||
                $0.category.displayName.lowercased().contains(query) ||
                ($0.counterpartyName?.lowercased().contains(query) ?? false)
            }
        }

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if let type = selectedType {
            result = result.filter { $0.type == type }
        }

        filteredTransactions = result
    }

    func clearFilters() {
        selectedCategory = nil
        selectedType = nil
        searchText = ""
        applyFilters()
    }

    var totalDebit: Decimal {
        filteredTransactions.filter { $0.isDebit }.reduce(Decimal.zero) { $0 + $1.amount }
    }

    var totalCredit: Decimal {
        filteredTransactions.filter { $0.isCredit }.reduce(Decimal.zero) { $0 + $1.amount }
    }
}
