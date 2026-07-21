// NOVA Voice Banking AI
// WealthView - Investment portfolio overview and asset management

import SwiftUI
import Charts

struct WealthView: View {
    @StateObject private var viewModel = WealthViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading && viewModel.portfolio == nil {
                    ProgressView("Loading portfolio...")
                        .padding(.top, 100)
                } else if let portfolio = viewModel.portfolio {
                    VStack(spacing: 20) {
                        portfolioHeader(portfolio)
                        performanceChart
                        allocationSection
                        assetsSection(portfolio)
                    }
                    .padding()
                }
            }
            .navigationTitle("Wealth")
            .refreshable {
                await viewModel.loadPortfolio()
            }
            .task {
                await viewModel.loadPortfolio()
            }
        }
    }

    // MARK: - Portfolio Header

    private func portfolioHeader(_ portfolio: WealthPortfolio) -> some View {
        VStack(spacing: 12) {
            Text("Portfolio Value")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Text("AED \(portfolio.totalValue, format: .number.precision(.fractionLength(2)))")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 4) {
                Image(systemName: portfolio.totalGainLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                Text("AED \(abs(portfolio.totalGainLoss), format: .number.precision(.fractionLength(2)))")
                Text("(\(String(format: "%.2f", portfolio.totalGainLossPercentage))%)")
            }
            .font(.subheadline.bold())
            .foregroundStyle(portfolio.totalGainLoss >= 0 ? .green : .red)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(
                colors: [.indigo, .purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Performance Chart

    private var performanceChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.headline)

            // Period selector
            HStack(spacing: 0) {
                ForEach(PerformancePeriod.allCases, id: \.self) { period in
                    Button {
                        Task { await viewModel.changePeriod(period) }
                    } label: {
                        Text(period.displayName)
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(viewModel.selectedPeriod == period ? Color.blue : Color.clear)
                            .foregroundStyle(viewModel.selectedPeriod == period ? .white : .secondary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(4)
            .background(Color(.tertiarySystemBackground))
            .clipShape(Capsule())

            if !viewModel.performanceHistory.isEmpty {
                Chart(viewModel.performanceHistory) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", Double(truncating: point.value as NSDecimalNumber))
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Value", Double(truncating: point.value as NSDecimalNumber))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .blue.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Allocation Section

    private var allocationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Asset Allocation")
                .font(.headline)

            ForEach(viewModel.allocation, id: \.id) { item in
                HStack {
                    Image(systemName: item.type.icon)
                        .foregroundStyle(.blue)
                        .frame(width: 24)

                    Text(item.type.displayName)
                        .font(.subheadline)

                    Spacer()

                    Text("\(String(format: "%.1f", item.percentage))%")
                        .font(.subheadline.bold())
                }

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue.opacity(0.2))
                        .frame(height: 6)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.blue)
                                .frame(width: geo.size.width * item.percentage / 100, height: 6)
                        }
                }
                .frame(height: 6)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Assets Section

    private func assetsSection(_ portfolio: WealthPortfolio) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assets")
                .font(.headline)

            ForEach(portfolio.assets) { asset in
                HStack(spacing: 12) {
                    Image(systemName: asset.type.icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(asset.name)
                            .font(.subheadline.bold())
                        Text(asset.type.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("AED \(asset.totalValue, format: .number.precision(.fractionLength(0)))")
                            .font(.subheadline.bold())

                        HStack(spacing: 2) {
                            Image(systemName: asset.isPositive ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption2)
                            Text("\(String(format: "%.2f", abs(asset.change24h)))%")
                                .font(.caption)
                        }
                        .foregroundStyle(asset.isPositive ? .green : .red)
                    }
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
