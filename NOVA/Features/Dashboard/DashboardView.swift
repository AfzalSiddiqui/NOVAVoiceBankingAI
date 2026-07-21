// NOVA Voice Banking AI
// DashboardView - Home screen with account overview, spending, and insights

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Total Balance Card
                    balanceCard

                    // Account Cards
                    accountsSection

                    // Spending Breakdown
                    if !viewModel.spendingBreakdown.isEmpty {
                        spendingSection
                    }

                    // Recent Transactions
                    if !viewModel.recentTransactions.isEmpty {
                        recentTransactionsSection
                    }

                    // AI Insights
                    if !viewModel.insights.isEmpty {
                        insightsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.loadDashboard()
            }
            .overlay {
                if viewModel.isLoading && viewModel.accounts.isEmpty {
                    ProgressView("Loading...")
                }
            }
            .task {
                await viewModel.loadDashboard()
            }
        }
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        VStack(spacing: 12) {
            Text("Total Balance")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Text("AED \(viewModel.totalBalance, format: .number.precision(.fractionLength(2)))")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 24) {
                ForEach(viewModel.accounts, id: \.id) { account in
                    VStack(spacing: 4) {
                        Text(account.accountType.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        Text("AED \(account.balance, format: .number.precision(.fractionLength(0)))")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(
                colors: [.blue, .blue.opacity(0.7), .purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Accounts Section

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accounts")
                .font(.headline)

            ForEach(viewModel.accounts) { account in
                HStack {
                    Image(systemName: accountIcon(for: account.accountType))
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.accountType.rawValue.capitalized + " Account")
                            .font(.subheadline.bold())
                        Text(account.accountNumber)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("AED \(account.balance, format: .number.precision(.fractionLength(2)))")
                        .font(.subheadline.bold())
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Spending Section

    private var spendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending This Month")
                .font(.headline)

            ForEach(viewModel.spendingBreakdown) { item in
                HStack {
                    Image(systemName: item.category.icon)
                        .foregroundStyle(.blue)
                        .frame(width: 30)

                    Text(item.category.displayName)
                        .font(.subheadline)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("AED \(item.amount, format: .number.precision(.fractionLength(0)))")
                            .font(.subheadline.bold())
                        Text("\(String(format: "%.0f", item.percentage))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if item.id != viewModel.spendingBreakdown.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recent Transactions Section

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                Spacer()
            }

            ForEach(viewModel.recentTransactions) { transaction in
                TransactionRow(transaction: transaction)

                if transaction.id != viewModel.recentTransactions.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Insights")
                .font(.headline)

            ForEach(viewModel.insights) { insight in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: insight.type.icon)
                        .font(.title3)
                        .foregroundStyle(insightColor(for: insight.type))
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.subheadline.bold())
                        Text(insight.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Helpers

    private func accountIcon(for type: Account.AccountType) -> String {
        switch type {
        case .current: return "creditcard.fill"
        case .savings: return "banknote.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        }
    }

    private func insightColor(for type: FinancialInsight.InsightType) -> Color {
        switch type {
        case .spending: return .orange
        case .saving: return .green
        case .investment: return .blue
        case .budget: return .purple
        case .warning: return .red
        }
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.category.icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.merchantName ?? transaction.description)
                    .font(.subheadline.bold())
                Text(transaction.date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(transaction.isCredit ? "+" : "-") AED \(transaction.amount, format: .number.precision(.fractionLength(2)))")
                .font(.subheadline.bold())
                .foregroundStyle(transaction.isCredit ? .green : .primary)
        }
    }
}
