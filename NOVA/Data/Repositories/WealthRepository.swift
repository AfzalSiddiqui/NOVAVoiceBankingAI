// NOVA Voice Banking AI
// WealthRepository - Wealth/investment operations data layer implementation

import Foundation

final class WealthRepository: WealthRepositoryProtocol, @unchecked Sendable {

    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func getPortfolio() async throws -> WealthPortfolio {
        try await simulateDelay()
        return WealthPortfolio.mock
    }

    func getAsset(id: String) async throws -> Asset {
        try await simulateDelay()
        guard let asset = Asset.mockAssets.first(where: { $0.id == id }) else {
            throw WealthError.assetNotFound
        }
        return asset
    }

    func getPerformanceHistory(period: PerformancePeriod) async throws -> [PerformancePoint] {
        try await simulateDelay()

        let calendar = Calendar.current
        let days = period.days
        let baseValue: Decimal = 280_000

        return (0..<days).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            let fluctuation = Decimal(Double.random(in: -5000...8000))
            let trend = Decimal(daysAgo) * 150
            return PerformancePoint(date: date, value: baseValue + trend + fluctuation)
        }
    }

    func getAssetAllocation() async throws -> [AssetAllocation] {
        try await simulateDelay()

        let assets = Asset.mockAssets
        let totalValue = assets.reduce(Decimal.zero) { $0 + $1.totalValue }

        var typeValues: [Asset.AssetType: Decimal] = [:]
        for asset in assets {
            typeValues[asset.type, default: 0] += asset.totalValue
        }

        return typeValues.map { type, value in
            let percentage = totalValue > 0 ? Double(truncating: (value / totalValue * 100) as NSDecimalNumber) : 0
            return AssetAllocation(type: type, percentage: percentage, value: value)
        }.sorted { $0.percentage > $1.percentage }
    }

    private func simulateDelay() async throws {
        try await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...300_000_000))
    }
}

// MARK: - Errors

enum WealthError: LocalizedError, Sendable {
    case assetNotFound
    case portfolioUnavailable

    var errorDescription: String? {
        switch self {
        case .assetNotFound: return "Asset not found"
        case .portfolioUnavailable: return "Portfolio data unavailable"
        }
    }
}
