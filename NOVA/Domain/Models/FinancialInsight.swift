// NOVA Voice Banking AI
// FinancialInsight - AI-generated financial insight model

import Foundation

struct FinancialInsight: Identifiable, Codable, Sendable, Equatable {

    enum InsightType: String, Codable, Sendable {
        case spending
        case saving
        case investment
        case budget
        case warning

        var icon: String {
            switch self {
            case .spending: return "chart.bar.fill"
            case .saving: return "banknote.fill"
            case .investment: return "chart.line.uptrend.xyaxis"
            case .budget: return "target"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
    }

    let id: String
    let type: InsightType
    let title: String
    let description: String
    let confidence: Float
    let actionItems: [String]
    let relatedTransactionIds: [String]
    let generatedAt: Date

    init(
        id: String = UUID().uuidString,
        type: InsightType,
        title: String,
        description: String,
        confidence: Float = 0.8,
        actionItems: [String] = [],
        relatedTransactionIds: [String] = [],
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.confidence = confidence
        self.actionItems = actionItems
        self.relatedTransactionIds = relatedTransactionIds
        self.generatedAt = generatedAt
    }

    static var mockInsights: [FinancialInsight] {
        [
            FinancialInsight(
                type: .spending,
                title: "Restaurant Spending Up 23%",
                description: "Your dining expenses increased by 23% compared to last month. Consider setting a dining budget.",
                confidence: 0.92,
                actionItems: ["Set a monthly dining budget of AED 2,000", "Try cooking at home 3 times a week"]
            ),
            FinancialInsight(
                type: .saving,
                title: "Great Saving Streak!",
                description: "You've saved AED 5,200 this month, which is 15% above your target. Keep it up!",
                confidence: 0.88,
                actionItems: ["Consider moving excess savings to a high-yield account"]
            ),
            FinancialInsight(
                type: .investment,
                title: "Portfolio Rebalancing Opportunity",
                description: "Your crypto allocation has grown to 25% of your portfolio. Consider rebalancing to maintain your target allocation.",
                confidence: 0.85,
                actionItems: ["Sell 5% of crypto holdings", "Reinvest in bonds or gold"]
            ),
            FinancialInsight(
                type: .warning,
                title: "Upcoming Bill Payment",
                description: "Your DEWA utility bill of AED 850 is due in 3 days. Ensure sufficient balance.",
                confidence: 0.95,
                actionItems: ["Verify account balance", "Set up auto-pay"]
            )
        ]
    }
}

// MARK: - Spending Breakdown

struct SpendingBreakdown: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let category: Transaction.Category
    let amount: Decimal
    let percentage: Double
    let trend: Trend

    enum Trend: String, Codable, Sendable {
        case increasing
        case decreasing
        case stable
    }

    init(
        id: String = UUID().uuidString,
        category: Transaction.Category,
        amount: Decimal,
        percentage: Double,
        trend: Trend = .stable
    ) {
        self.id = id
        self.category = category
        self.amount = amount
        self.percentage = percentage
        self.trend = trend
    }
}
