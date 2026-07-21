// NOVA Voice Banking AI
// BankingIntent - Intent classification result model

import Foundation

enum BankingIntent: Sendable, Equatable {
    case checkBalance
    case transferMoney(amount: Decimal, recipient: String)
    case getTransactions(filter: TransactionFilter?)
    case blockCard(cardId: String?)
    case unblockCard(cardId: String?)
    case spendingAnalysis(category: Transaction.Category?)
    case financialAdvice(query: String)
    case unknown(rawText: String)

    var displayName: String {
        switch self {
        case .checkBalance: return "Check Balance"
        case .transferMoney: return "Transfer Money"
        case .getTransactions: return "View Transactions"
        case .blockCard: return "Block Card"
        case .unblockCard: return "Unblock Card"
        case .spendingAnalysis: return "Spending Analysis"
        case .financialAdvice: return "Financial Advice"
        case .unknown: return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .checkBalance: return "banknote"
        case .transferMoney: return "arrow.right.circle"
        case .getTransactions: return "list.bullet.rectangle"
        case .blockCard: return "lock.shield"
        case .unblockCard: return "lock.open"
        case .spendingAnalysis: return "chart.bar"
        case .financialAdvice: return "lightbulb"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Intent Classification Result

struct IntentClassificationResult: Sendable, Equatable {
    let intent: BankingIntent
    let confidence: Float
    let entities: [String: String]
    let rawText: String

    init(
        intent: BankingIntent,
        confidence: Float,
        entities: [String: String] = [:],
        rawText: String = ""
    ) {
        self.intent = intent
        self.confidence = confidence
        self.entities = entities
        self.rawText = rawText
    }

    var isHighConfidence: Bool { confidence >= 0.7 }

    static var mock: IntentClassificationResult {
        IntentClassificationResult(
            intent: .checkBalance,
            confidence: 0.95,
            rawText: "show my account balance"
        )
    }
}
