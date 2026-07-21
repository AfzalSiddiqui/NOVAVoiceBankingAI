// NOVA Voice Banking AI
// TransactionRepository - Transaction operations data layer implementation

import Foundation

final class TransactionRepository: TransactionRepositoryProtocol, @unchecked Sendable {

    private let networkClient: NetworkClientProtocol

    private let mockTransactions: [Transaction] = [
        Transaction(id: "TXN001", type: .debit, amount: 125.50, description: "Lunch at Zuma", merchantName: "Zuma Restaurant", category: .food, date: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, location: "Dubai, UAE"),
        Transaction(id: "TXN002", type: .debit, amount: 45.00, description: "Uber ride", merchantName: "Uber", category: .transport, date: Calendar.current.date(byAdding: .hour, value: -5, to: Date())!, location: "Dubai, UAE"),
        Transaction(id: "TXN003", type: .credit, amount: 25_000.00, description: "Salary deposit", category: .salary, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, counterpartyName: "NOVA Corp"),
        Transaction(id: "TXN004", type: .debit, amount: 850.00, description: "DEWA electricity bill", merchantName: "DEWA", category: .utilities, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!),
        Transaction(id: "TXN005", type: .debit, amount: 1_250.00, description: "Apple Store purchase", merchantName: "Apple Store", category: .shopping, date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, location: "Dubai Mall"),
        Transaction(id: "TXN006", type: .debit, amount: 200.00, description: "Cinema tickets", merchantName: "VOX Cinemas", category: .entertainment, date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!),
        Transaction(id: "TXN007", type: .transfer, amount: 5_000.00, description: "Transfer to Fatima", category: .transfer, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, counterpartyName: "Fatima Al Rashid"),
        Transaction(id: "TXN008", type: .debit, amount: 350.00, description: "Pharmacy", merchantName: "Life Pharmacy", category: .health, date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!),
        Transaction(id: "TXN009", type: .debit, amount: 75.00, description: "Coffee shop", merchantName: "Starbucks", category: .food, date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!),
        Transaction(id: "TXN010", type: .debit, amount: 3_500.00, description: "Online course", merchantName: "Udemy", category: .education, date: Calendar.current.date(byAdding: .day, value: -8, to: Date())!),
        Transaction(id: "TXN011", type: .debit, amount: 180.00, description: "Dinner at Nobu", merchantName: "Nobu Dubai", category: .food, date: Calendar.current.date(byAdding: .day, value: -9, to: Date())!, location: "Atlantis"),
        Transaction(id: "TXN012", type: .debit, amount: 60.00, description: "Careem ride", merchantName: "Careem", category: .transport, date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!),
        Transaction(id: "TXN013", type: .debit, amount: 2_200.00, description: "Zara shopping", merchantName: "Zara", category: .shopping, date: Calendar.current.date(byAdding: .day, value: -12, to: Date())!, location: "Mall of the Emirates"),
        Transaction(id: "TXN014", type: .debit, amount: 450.00, description: "Gym membership", merchantName: "Fitness First", category: .health, date: Calendar.current.date(byAdding: .day, value: -15, to: Date())!),
        Transaction(id: "TXN015", type: .credit, amount: 25_000.00, description: "Salary deposit", category: .salary, date: Calendar.current.date(byAdding: .month, value: -1, to: Date())!, counterpartyName: "NOVA Corp")
    ]

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func getTransactions(accountId: String?, filter: TransactionFilter?) async throws -> [Transaction] {
        try await simulateDelay()

        var results = mockTransactions

        if let accountId {
            results = results.filter { $0.accountId == accountId }
        }

        if let filter {
            if let startDate = filter.startDate {
                results = results.filter { $0.date >= startDate }
            }
            if let endDate = filter.endDate {
                results = results.filter { $0.date <= endDate }
            }
            if let category = filter.category {
                results = results.filter { $0.category == category }
            }
            if let minAmount = filter.minAmount {
                results = results.filter { $0.amount >= minAmount }
            }
            if let maxAmount = filter.maxAmount {
                results = results.filter { $0.amount <= maxAmount }
            }
            if let type = filter.type {
                results = results.filter { $0.type == type }
            }
            if let status = filter.status {
                results = results.filter { $0.status == status }
            }
        }

        return results.sorted { $0.date > $1.date }
    }

    func getTransaction(id: String) async throws -> Transaction {
        try await simulateDelay()
        guard let transaction = mockTransactions.first(where: { $0.id == id }) else {
            throw TransactionError.notFound
        }
        return transaction
    }

    func getRecentTransactions(limit: Int) async throws -> [Transaction] {
        try await simulateDelay()
        return Array(mockTransactions.sorted { $0.date > $1.date }.prefix(limit))
    }

    func getSpendingByCategory(from: Date, to: Date) async throws -> [SpendingBreakdown] {
        try await simulateDelay()

        let filtered = mockTransactions.filter { $0.date >= from && $0.date <= to && $0.isDebit }
        let totalSpending = filtered.reduce(Decimal.zero) { $0 + $1.amount }

        var categoryTotals: [Transaction.Category: Decimal] = [:]
        for txn in filtered {
            categoryTotals[txn.category, default: 0] += txn.amount
        }

        return categoryTotals.map { category, amount in
            let percentage = totalSpending > 0 ? Double(truncating: (amount / totalSpending * 100) as NSDecimalNumber) : 0
            return SpendingBreakdown(
                category: category,
                amount: amount,
                percentage: percentage,
                trend: [.increasing, .decreasing, .stable].randomElement()!
            )
        }.sorted { $0.amount > $1.amount }
    }

    func getMonthlySpending(months: Int) async throws -> [(month: String, amount: Decimal)] {
        try await simulateDelay()

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        let calendar = Calendar.current

        return (0..<months).map { monthOffset in
            let date = calendar.date(byAdding: .month, value: -monthOffset, to: Date())!
            let amount = Decimal(Double.random(in: 8000...18000))
            return (month: formatter.string(from: date), amount: amount)
        }.reversed()
    }

    func searchTransactions(query: String) async throws -> [Transaction] {
        try await simulateDelay()
        let lowered = query.lowercased()
        return mockTransactions.filter {
            $0.description.lowercased().contains(lowered) ||
            ($0.merchantName?.lowercased().contains(lowered) ?? false) ||
            $0.category.rawValue.lowercased().contains(lowered) ||
            ($0.counterpartyName?.lowercased().contains(lowered) ?? false)
        }
    }

    private func simulateDelay() async throws {
        try await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...300_000_000))
    }
}

// MARK: - Errors

enum TransactionError: LocalizedError, Sendable {
    case notFound
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .notFound: return "Transaction not found"
        case .fetchFailed: return "Failed to fetch transactions"
        }
    }
}
