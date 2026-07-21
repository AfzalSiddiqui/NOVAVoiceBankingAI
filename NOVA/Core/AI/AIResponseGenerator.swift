// NOVA Voice Banking AI
// AIResponseGenerator - Contextual natural language response generation

import Foundation

// MARK: - Protocol

protocol AIResponseGeneratorProtocol: Sendable {
    func generateResponse(for intent: BankingIntent, context: ResponseContext) async -> AIResponse
    func generateFinancialAdvice(query: String, financialData: FinancialSummary) async -> AIResponse
}

// MARK: - Supporting Models

struct ResponseContext: Sendable {
    let userName: String
    let accountBalance: Decimal?
    let recentTransactions: [Transaction]?
    let spendingBreakdown: [SpendingBreakdown]?

    static var empty: ResponseContext {
        ResponseContext(userName: "Ahmed", accountBalance: nil, recentTransactions: nil, spendingBreakdown: nil)
    }
}

struct FinancialSummary: Sendable {
    let monthlyIncome: Decimal
    let monthlyExpenses: Decimal
    let savings: Decimal
    let topCategories: [(category: String, amount: Decimal)]
}

struct AIResponse: Sendable, Identifiable {
    let id: String
    let text: String
    let suggestions: [String]
    let data: ResponseData?
    let timestamp: Date

    enum ResponseData: Sendable {
        case balance(Decimal)
        case transactions([Transaction])
        case transfer(Transaction)
        case card(Card)
        case spending([SpendingBreakdown])
        case insight(FinancialInsight)
    }

    init(
        id: String = UUID().uuidString,
        text: String,
        suggestions: [String] = [],
        data: ResponseData? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.suggestions = suggestions
        self.data = data
        self.timestamp = timestamp
    }
}

// MARK: - Implementation

final class AIResponseGenerator: AIResponseGeneratorProtocol, Sendable {

    func generateResponse(for intent: BankingIntent, context: ResponseContext) async -> AIResponse {
        switch intent {
        case .checkBalance:
            return generateBalanceResponse(context: context)

        case .transferMoney(let amount, let recipient):
            return generateTransferResponse(amount: amount, recipient: recipient, context: context)

        case .getTransactions:
            return generateTransactionsResponse(context: context)

        case .blockCard:
            return generateBlockCardResponse(context: context)

        case .unblockCard:
            return generateUnblockCardResponse(context: context)

        case .spendingAnalysis(let category):
            return generateSpendingResponse(category: category, context: context)

        case .financialAdvice(let query):
            let summary = FinancialSummary(
                monthlyIncome: 25_000,
                monthlyExpenses: 15_000,
                savings: context.accountBalance ?? 125_000,
                topCategories: [("Food", 3500), ("Shopping", 2800), ("Transport", 1200)]
            )
            return await generateFinancialAdvice(query: query, financialData: summary)

        case .unknown(let rawText):
            return AIResponse(
                text: "I'm not sure I understood that. Could you rephrase your request? You can ask me about your balance, transactions, transfers, or spending analysis.",
                suggestions: ["Check my balance", "Show recent transactions", "How much did I spend?"]
            )
        }
    }

    func generateFinancialAdvice(query: String, financialData: FinancialSummary) async -> AIResponse {
        let disposableIncome = financialData.monthlyIncome - financialData.monthlyExpenses
        let savingsRate = Double(truncating: (disposableIncome / financialData.monthlyIncome * 100) as NSDecimalNumber)

        let queryLower = query.lowercased()

        if queryLower.contains("afford") || queryLower.contains("buy") || queryLower.contains("can i") {
            let maxMonthlyPayment = disposableIncome * Decimal(0.3) // 30% rule
            return AIResponse(
                text: "Based on your financial profile:\n\n• Monthly income: AED \(financialData.monthlyIncome)\n• Monthly expenses: AED \(financialData.monthlyExpenses)\n• Savings rate: \(String(format: "%.0f", savingsRate))%\n\nYour recommended maximum monthly payment is AED \(maxMonthlyPayment). I'd suggest keeping any new financial commitment below this to maintain a healthy budget.",
                suggestions: ["Show my spending breakdown", "How can I save more?", "Show my investments"]
            )
        }

        if queryLower.contains("save") || queryLower.contains("saving") {
            return AIResponse(
                text: "Here are your savings insights:\n\n• Current savings rate: \(String(format: "%.0f", savingsRate))%\n• Monthly savings: AED \(disposableIncome)\n• Total savings: AED \(financialData.savings)\n\nTop tip: Your highest expense category is \(financialData.topCategories.first?.category ?? "Food") at AED \(financialData.topCategories.first?.amount ?? 0). Reducing it by 20% could save you an extra AED \(Int(Double(truncating: (financialData.topCategories.first?.amount ?? 0) as NSDecimalNumber) * 0.2)) monthly.",
                suggestions: ["Show spending by category", "Set a budget", "Show investments"]
            )
        }

        return AIResponse(
            text: "Here's your financial summary:\n\n• Monthly income: AED \(financialData.monthlyIncome)\n• Monthly expenses: AED \(financialData.monthlyExpenses)\n• Disposable income: AED \(disposableIncome)\n• Savings rate: \(String(format: "%.0f", savingsRate))%\n\nYou're in a healthy financial position. Would you like specific advice on budgeting, investing, or making a purchase?",
            suggestions: ["Can I afford a new car?", "How to save more?", "Investment options"]
        )
    }

    // MARK: - Private Response Generators

    private func generateBalanceResponse(context: ResponseContext) -> AIResponse {
        let balance = context.accountBalance ?? 45_750.50
        return AIResponse(
            text: "Hi \(context.userName)! Your current balance is AED \(balance). Your available balance is AED \(balance - 1250).",
            suggestions: ["Show recent transactions", "Transfer money", "Spending analysis"],
            data: .balance(balance)
        )
    }

    private func generateTransferResponse(amount: Decimal, recipient: String, context: ResponseContext) -> AIResponse {
        let newBalance = (context.accountBalance ?? 45_750.50) - amount
        let transaction = Transaction(
            type: .transfer,
            amount: amount,
            description: "Transfer to \(recipient)",
            category: .transfer,
            status: .completed,
            counterpartyName: recipient
        )

        return AIResponse(
            text: "Successfully transferred AED \(amount) to \(recipient). Your new balance is AED \(newBalance). Reference: \(transaction.reference).",
            suggestions: ["Check balance", "Show recent transactions"],
            data: .transfer(transaction)
        )
    }

    private func generateTransactionsResponse(context: ResponseContext) -> AIResponse {
        let transactions = context.recentTransactions ?? []
        let count = transactions.count

        if transactions.isEmpty {
            return AIResponse(
                text: "You have no recent transactions to display.",
                suggestions: ["Check balance", "Transfer money"]
            )
        }

        let summary = transactions.prefix(5).map { txn in
            "• \(txn.merchantName ?? txn.description): AED \(txn.amount) (\(txn.category.displayName))"
        }.joined(separator: "\n")

        return AIResponse(
            text: "Here are your \(min(count, 5)) most recent transactions:\n\n\(summary)",
            suggestions: ["Show more transactions", "Spending by category", "Check balance"],
            data: .transactions(Array(transactions.prefix(5)))
        )
    }

    private func generateBlockCardResponse(context: ResponseContext) -> AIResponse {
        let card = Card.mock
        return AIResponse(
            text: "Your \(card.cardNetwork.rawValue.capitalized) \(card.cardType.rawValue) card ending in \(card.cardNumber.suffix(4)) has been frozen. No transactions will be processed until you unfreeze it.",
            suggestions: ["Unfreeze card", "Check balance", "Report fraud"],
            data: .card(card)
        )
    }

    private func generateUnblockCardResponse(context: ResponseContext) -> AIResponse {
        let card = Card.mock
        return AIResponse(
            text: "Your \(card.cardNetwork.rawValue.capitalized) \(card.cardType.rawValue) card ending in \(card.cardNumber.suffix(4)) has been unfrozen and is now active.",
            suggestions: ["Check balance", "Show transactions"],
            data: .card(card)
        )
    }

    private func generateSpendingResponse(category: Transaction.Category?, context: ResponseContext) -> AIResponse {
        if let category, let breakdown = context.spendingBreakdown {
            let catSpending = breakdown.first(where: { $0.category == category })
            let amount = catSpending?.amount ?? 0
            return AIResponse(
                text: "You've spent AED \(amount) on \(category.displayName) this month. That's \(String(format: "%.0f", catSpending?.percentage ?? 0))% of your total spending.",
                suggestions: ["Show all categories", "Set a budget", "Show transactions"],
                data: .spending(breakdown)
            )
        }

        let breakdown = context.spendingBreakdown ?? []
        let total = breakdown.reduce(Decimal.zero) { $0 + $1.amount }
        let summary = breakdown.prefix(5).map { b in
            "• \(b.category.displayName): AED \(b.amount) (\(String(format: "%.0f", b.percentage))%)"
        }.joined(separator: "\n")

        return AIResponse(
            text: "Your spending breakdown this month (Total: AED \(total)):\n\n\(summary)",
            suggestions: ["How can I save?", "Show transactions", "Set a budget"],
            data: .spending(breakdown)
        )
    }
}
