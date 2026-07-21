// NOVA Voice Banking AI
// WealthPortfolio - Investment portfolio domain model

import Foundation

struct WealthPortfolio: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let totalValue: Decimal
    let currency: String
    let lastUpdated: Date
    let assets: [Asset]
    let performanceHistory: [PerformancePoint]
    let totalGainLoss: Decimal
    let totalGainLossPercentage: Double

    init(
        id: String = UUID().uuidString,
        totalValue: Decimal,
        currency: String = "AED",
        lastUpdated: Date = Date(),
        assets: [Asset],
        performanceHistory: [PerformancePoint] = [],
        totalGainLoss: Decimal,
        totalGainLossPercentage: Double
    ) {
        self.id = id
        self.totalValue = totalValue
        self.currency = currency
        self.lastUpdated = lastUpdated
        self.assets = assets
        self.performanceHistory = performanceHistory
        self.totalGainLoss = totalGainLoss
        self.totalGainLossPercentage = totalGainLossPercentage
    }

    static var mock: WealthPortfolio {
        let assets = Asset.mockAssets
        let totalValue = assets.reduce(Decimal.zero) { $0 + ($1.currentPrice * Decimal($1.quantity)) }
        let totalCost = assets.reduce(Decimal.zero) { $0 + ($1.purchasePrice * Decimal($1.quantity)) }
        let gainLoss = totalValue - totalCost
        let gainLossPercent = totalCost > 0 ? Double(truncating: (gainLoss / totalCost * 100) as NSDecimalNumber) : 0

        return WealthPortfolio(
            totalValue: totalValue,
            assets: assets,
            performanceHistory: PerformancePoint.mockHistory,
            totalGainLoss: gainLoss,
            totalGainLossPercentage: gainLossPercent
        )
    }
}

// MARK: - Asset

struct Asset: Identifiable, Codable, Sendable, Equatable {

    enum AssetType: String, Codable, Sendable, CaseIterable {
        case stock
        case gold
        case crypto
        case realEstate
        case bond
        case mutualFund

        var icon: String {
            switch self {
            case .stock: return "chart.line.uptrend.xyaxis"
            case .gold: return "diamond.fill"
            case .crypto: return "bitcoinsign.circle.fill"
            case .realEstate: return "house.fill"
            case .bond: return "doc.text.fill"
            case .mutualFund: return "chart.pie.fill"
            }
        }

        var displayName: String {
            switch self {
            case .stock: return "Stocks"
            case .gold: return "Gold"
            case .crypto: return "Crypto"
            case .realEstate: return "Real Estate"
            case .bond: return "Bonds"
            case .mutualFund: return "Mutual Funds"
            }
        }
    }

    let id: String
    let name: String
    let type: AssetType
    let quantity: Double
    let currentPrice: Decimal
    let purchasePrice: Decimal
    let currency: String
    let change24h: Double
    let allocation: Double

    init(
        id: String = UUID().uuidString,
        name: String,
        type: AssetType,
        quantity: Double,
        currentPrice: Decimal,
        purchasePrice: Decimal,
        currency: String = "AED",
        change24h: Double = 0,
        allocation: Double = 0
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.quantity = quantity
        self.currentPrice = currentPrice
        self.purchasePrice = purchasePrice
        self.currency = currency
        self.change24h = change24h
        self.allocation = allocation
    }

    var totalValue: Decimal { currentPrice * Decimal(quantity) }
    var totalCost: Decimal { purchasePrice * Decimal(quantity) }
    var gainLoss: Decimal { totalValue - totalCost }
    var gainLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return Double(truncating: (gainLoss / totalCost * 100) as NSDecimalNumber)
    }
    var isPositive: Bool { change24h >= 0 }

    static var mockAssets: [Asset] {
        [
            Asset(name: "Apple Inc.", type: .stock, quantity: 15, currentPrice: 785.50, purchasePrice: 650.00, change24h: 1.25, allocation: 18),
            Asset(name: "Tesla Inc.", type: .stock, quantity: 8, currentPrice: 920.30, purchasePrice: 800.00, change24h: -0.85, allocation: 12),
            Asset(name: "Emirates NBD", type: .stock, quantity: 200, currentPrice: 18.50, purchasePrice: 14.75, change24h: 0.45, allocation: 6),
            Asset(name: "Gold (XAU)", type: .gold, quantity: 5, currentPrice: 8_750.00, purchasePrice: 7_200.00, change24h: 0.32, allocation: 22),
            Asset(name: "Bitcoin", type: .crypto, quantity: 0.5, currentPrice: 245_000.00, purchasePrice: 180_000.00, change24h: 2.15, allocation: 15),
            Asset(name: "Ethereum", type: .crypto, quantity: 3.2, currentPrice: 14_500.00, purchasePrice: 11_000.00, change24h: -1.20, allocation: 8),
            Asset(name: "UAE REIT Fund", type: .realEstate, quantity: 100, currentPrice: 52.50, purchasePrice: 48.00, change24h: 0.10, allocation: 10),
            Asset(name: "UAE Govt Bond 2030", type: .bond, quantity: 50, currentPrice: 102.30, purchasePrice: 100.00, change24h: 0.05, allocation: 5),
            Asset(name: "Emirates Growth Fund", type: .mutualFund, quantity: 75, currentPrice: 35.80, purchasePrice: 30.00, change24h: 0.55, allocation: 4)
        ]
    }
}

// MARK: - Performance Point

struct PerformancePoint: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let date: Date
    let value: Decimal

    init(id: String = UUID().uuidString, date: Date, value: Decimal) {
        self.id = id
        self.date = date
        self.value = value
    }

    static var mockHistory: [PerformancePoint] {
        let calendar = Calendar.current
        let baseValue: Decimal = 280_000
        return (0..<30).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            let fluctuation = Decimal(Double.random(in: -5000...8000))
            let trend = Decimal(daysAgo) * 200
            return PerformancePoint(date: date, value: baseValue + trend + fluctuation)
        }
    }
}
