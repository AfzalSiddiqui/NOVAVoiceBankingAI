// NOVA Voice Banking AI
// TransactionsView - Transaction list with search and filters

import SwiftUI

struct TransactionsView: View {
    @StateObject private var viewModel = TransactionsViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary bar
                summaryBar

                // Filter chips
                filterChips

                // Transaction list
                if viewModel.isLoading && viewModel.transactions.isEmpty {
                    Spacer()
                    ProgressView("Loading transactions...")
                    Spacer()
                } else if viewModel.filteredTransactions.isEmpty {
                    Spacer()
                    ContentUnavailableView("No Transactions", systemImage: "tray", description: Text("No transactions match your filters."))
                    Spacer()
                } else {
                    transactionList
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $viewModel.searchText, prompt: "Search transactions")
            .refreshable {
                await viewModel.loadTransactions()
            }
            .task {
                await viewModel.loadTransactions()
            }
        }
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("Income")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("AED \(viewModel.totalCredit, format: .number.precision(.fractionLength(0)))")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }

            Divider()
                .frame(height: 30)

            VStack(spacing: 4) {
                Text("Expenses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("AED \(viewModel.totalDebit, format: .number.precision(.fractionLength(0)))")
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
            }

            Divider()
                .frame(height: 30)

            VStack(spacing: 4) {
                Text("Count")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.filteredTransactions.count)")
                    .font(.subheadline.bold())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Category filters
                ForEach(Transaction.Category.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        if viewModel.selectedCategory == category {
                            viewModel.selectedCategory = nil
                        } else {
                            viewModel.selectedCategory = category
                        }
                        viewModel.applyFilters()
                    }
                }

                if viewModel.selectedCategory != nil || viewModel.selectedType != nil {
                    Button("Clear") {
                        viewModel.clearFilters()
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Transaction List

    private var transactionList: some View {
        List {
            ForEach(groupedTransactions, id: \.0) { dateString, transactions in
                Section(dateString) {
                    ForEach(transactions) { transaction in
                        TransactionDetailRow(transaction: transaction)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var groupedTransactions: [(String, [Transaction])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        let grouped = Dictionary(grouping: viewModel.filteredTransactions) { transaction in
            formatter.string(from: transaction.date)
        }

        return grouped.sorted { first, second in
            guard let d1 = first.value.first?.date, let d2 = second.value.first?.date else { return false }
            return d1 > d2
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.tertiarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Transaction Detail Row

struct TransactionDetailRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.category.icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(categoryColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.merchantName ?? transaction.description)
                    .font(.subheadline.bold())
                HStack(spacing: 4) {
                    Text(transaction.category.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let location = transaction.location {
                        Text("- \(location)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.isCredit ? "+" : "-") AED \(transaction.amount, format: .number.precision(.fractionLength(2)))")
                    .font(.subheadline.bold())
                    .foregroundStyle(transaction.isCredit ? .green : .primary)

                Text(transaction.status.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundStyle(transaction.status == .completed ? .green : .orange)
            }
        }
        .padding(.vertical, 2)
    }

    private var categoryColor: Color {
        switch transaction.category {
        case .food: return .orange
        case .transport: return .blue
        case .shopping: return .purple
        case .utilities: return .yellow
        case .entertainment: return .pink
        case .health: return .red
        case .education: return .indigo
        case .salary: return .green
        case .transfer: return .cyan
        case .other: return .gray
        }
    }
}
