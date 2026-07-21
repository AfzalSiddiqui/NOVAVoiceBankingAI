// NOVA Voice Banking AI
// Wealth Repository Protocol - Domain layer contract for wealth/investment operations

import Foundation

protocol WealthRepositoryProtocol: Sendable {
    func getPortfolio() async throws -> WealthPortfolio
    func getAsset(id: String) async throws -> Asset
    func getPerformanceHistory(period: PerformancePeriod) async throws -> [PerformancePoint]
    func getAssetAllocation() async throws -> [AssetAllocation]
}

// MARK: - Performance Period

enum PerformancePeriod: String, Sendable, CaseIterable {
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    case all = "ALL"

    var displayName: String {
        rawValue
    }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .year: return 365
        case .all: return 730
        }
    }
}

// MARK: - Asset Allocation

struct AssetAllocation: Identifiable, Sendable, Codable, Equatable {
    let id: String
    let type: Asset.AssetType
    let percentage: Double
    let value: Decimal

    init(id: String = UUID().uuidString, type: Asset.AssetType, percentage: Double, value: Decimal) {
        self.id = id
        self.type = type
        self.percentage = percentage
        self.value = value
    }
}
