// NOVA Voice Banking AI
// RAGEngine - Retrieval Augmented Generation for contextual banking AI

import Foundation

protocol RAGEngineProtocol: Sendable {
    func query(_ text: String) async throws -> RAGResult
}

struct RAGResult: Sendable {
    let answer: String
    let context: [RAGDocument]
    let confidence: Float
}

struct RAGDocument: Sendable, Identifiable {
    let id: String
    let content: String
    let source: String
    let relevanceScore: Float

    init(id: String = UUID().uuidString, content: String, source: String, relevanceScore: Float = 0) {
        self.id = id
        self.content = content
        self.source = source
        self.relevanceScore = relevanceScore
    }
}

final class RAGEngine: RAGEngineProtocol {
    private let knowledgeBase: [RAGDocument]
    private let bankingRepository: BankingRepositoryProtocol
    private let transactionRepository: TransactionRepositoryProtocol

    init(bankingRepository: BankingRepositoryProtocol, transactionRepository: TransactionRepositoryProtocol) {
        self.bankingRepository = bankingRepository
        self.transactionRepository = transactionRepository
        self.knowledgeBase = Self.buildKnowledgeBase()
    }

    func query(_ text: String) async throws -> RAGResult {
        // Retrieve relevant documents
        let relevant = retrieveDocuments(for: text, topK: 3)

        // Build context from retrieved documents
        let contextText = relevant.map(\.content).joined(separator: "\n\n")

        // Generate answer from context + user financial data
        let accounts = try await bankingRepository.getAccounts()
        let balance = accounts.first?.balance ?? 0

        let answer = generateAnswer(query: text, context: contextText, balance: balance)

        return RAGResult(
            answer: answer,
            context: relevant,
            confidence: relevant.first?.relevanceScore ?? 0.5
        )
    }

    // MARK: - Retrieval (TF-IDF-style keyword scoring)

    private func retrieveDocuments(for query: String, topK: Int) -> [RAGDocument] {
        let queryTokens = tokenize(query)

        let scored = knowledgeBase.map { doc -> RAGDocument in
            let docTokens = tokenize(doc.content)
            let score = calculateRelevance(queryTokens: queryTokens, docTokens: docTokens)
            return RAGDocument(id: doc.id, content: doc.content, source: doc.source, relevanceScore: score)
        }
        .sorted { $0.relevanceScore > $1.relevanceScore }
        .prefix(topK)

        return Array(scored)
    }

    private func tokenize(_ text: String) -> Set<String> {
        Set(text.lowercased()
            .components(separatedBy: .alphanumerics.inverted)
            .filter { $0.count > 2 })
    }

    private func calculateRelevance(queryTokens: Set<String>, docTokens: Set<String>) -> Float {
        let intersection = queryTokens.intersection(docTokens)
        guard !queryTokens.isEmpty else { return 0 }
        return Float(intersection.count) / Float(queryTokens.count)
    }

    private func generateAnswer(query: String, context: String, balance: Decimal) -> String {
        // Template-based answer generation with context
        if context.isEmpty {
            return "I don't have specific information about that. Please contact customer service for more details."
        }
        return "Based on our banking information:\n\n\(context)\n\nYour current account balance is AED \(balance). Is there anything specific you'd like to know?"
    }

    // MARK: - Knowledge Base

    private static func buildKnowledgeBase() -> [RAGDocument] {
        [
            RAGDocument(content: "NOVA Bank offers current accounts with zero minimum balance requirements. Monthly maintenance fees are waived for balances above AED 5,000. Current accounts come with a free Visa debit card.", source: "Account Types"),
            RAGDocument(content: "Savings accounts earn up to 3.5% annual interest rate. Interest is calculated daily and paid monthly. Minimum balance for interest is AED 1,000.", source: "Savings Accounts"),
            RAGDocument(content: "Domestic transfers within UAE are free of charge. International wire transfers cost AED 50 for standard (2-3 business days) and AED 100 for express (same day). Transfer limits: AED 100,000 per day for personal accounts.", source: "Transfer Policies"),
            RAGDocument(content: "NOVA Bank credit cards offer 2% cashback on dining, 1.5% on shopping, and 1% on all other purchases. Annual fee is waived for the first year. Credit limit is based on salary assignment.", source: "Credit Card Benefits"),
            RAGDocument(content: "Card freeze feature instantly blocks all transactions on your card. You can freeze and unfreeze from the app anytime. Frozen cards cannot be used for ATM, POS, or online transactions.", source: "Card Security"),
            RAGDocument(content: "NOVA Bank investment accounts offer access to UAE and international stock markets, gold trading, cryptocurrency, real estate funds, and government bonds. Minimum investment is AED 1,000.", source: "Investment Options"),
            RAGDocument(content: "Two-factor authentication is required for all transfers above AED 10,000. Biometric authentication (Face ID/Touch ID) can be used for app login and transaction authorization.", source: "Security Features"),
            RAGDocument(content: "Auto-save feature rounds up every purchase to the nearest AED and deposits the difference into your savings account. Average customers save AED 300-500 per month with this feature.", source: "Auto-Save Feature"),
            RAGDocument(content: "NOVA Bank personal loans offer rates starting from 3.99% APR. Maximum loan amount is 20x monthly salary. Tenure options from 12 to 48 months. No early settlement fees.", source: "Personal Loans"),
            RAGDocument(content: "Foreign exchange rates are updated in real-time. NOVA Bank offers competitive rates for AED to USD, EUR, GBP, and INR. No commission on forex transactions above AED 5,000.", source: "Foreign Exchange"),
            RAGDocument(content: "NOVA Rewards program earns 1 point per AED spent. Points can be redeemed for cashback (1000 points = AED 10), airline miles, or gift vouchers. Points expire after 24 months.", source: "Rewards Program"),
            RAGDocument(content: "Customer support is available 24/7 via phone (+971-4-XXX-XXXX), in-app chat, and email. Priority support for premium customers with dedicated relationship managers.", source: "Customer Support"),
            RAGDocument(content: "Bill payment service supports DEWA, Etisalat, du, Salik, traffic fines, and school fees. Auto-pay can be set up for recurring bills. No charges for bill payments.", source: "Bill Payments"),
            RAGDocument(content: "NOVA Bank mortgage rates start from 3.25% fixed for 5 years. Maximum financing is 80% of property value for UAE nationals and 75% for expatriates. Pre-approval available within 24 hours.", source: "Mortgage"),
            RAGDocument(content: "Insurance products include life insurance, health insurance, motor insurance, and travel insurance. Bundled discounts available for multiple products. Claims can be filed through the app.", source: "Insurance Products")
        ]
    }
}
