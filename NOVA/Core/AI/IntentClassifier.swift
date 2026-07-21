// NOVA Voice Banking AI
// IntentClassifier - NLP-based intent classification for banking commands

import NaturalLanguage
import Foundation

protocol IntentClassifierProtocol: Sendable {
    func classify(text: String) async -> IntentClassificationResult
}

final class IntentClassifier: IntentClassifierProtocol, Sendable {

    // MARK: - Keyword Patterns

    private let balanceKeywords = ["balance", "how much", "account", "money do i have", "available"]
    private let transferKeywords = ["transfer", "send", "pay", "wire"]
    private let transactionKeywords = ["transactions", "history", "recent", "statement", "activity"]
    private let blockCardKeywords = ["block", "freeze", "disable", "lock"]
    private let unblockCardKeywords = ["unblock", "unfreeze", "enable", "unlock"]
    private let spendingKeywords = ["spend", "spending", "spent", "expenses", "expense"]
    private let adviceKeywords = ["advice", "recommend", "suggest", "afford", "should i", "can i buy", "budget", "save"]
    private let cardKeywords = ["card"]

    // MARK: - Classification

    func classify(text: String) async -> IntentClassificationResult {
        let normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var entities: [String: String] = [:]

        // Check each intent pattern in priority order
        if detectKeywords(in: normalizedText, keywords: adviceKeywords) {
            return IntentClassificationResult(
                intent: .financialAdvice(query: normalizedText),
                confidence: 0.85,
                entities: entities,
                rawText: text
            )
        }

        if detectKeywords(in: normalizedText, keywords: transferKeywords) {
            let amount = extractAmount(from: normalizedText) ?? 0
            let recipient = extractRecipient(from: normalizedText) ?? "Unknown"
            entities["amount"] = "\(amount)"
            entities["recipient"] = recipient
            return IntentClassificationResult(
                intent: .transferMoney(amount: amount, recipient: recipient),
                confidence: amount > 0 ? 0.9 : 0.7,
                entities: entities,
                rawText: text
            )
        }

        if detectKeywords(in: normalizedText, keywords: blockCardKeywords),
           detectKeywords(in: normalizedText, keywords: cardKeywords) {
            return IntentClassificationResult(
                intent: .blockCard(cardId: nil),
                confidence: 0.9,
                entities: entities,
                rawText: text
            )
        }

        if detectKeywords(in: normalizedText, keywords: unblockCardKeywords),
           detectKeywords(in: normalizedText, keywords: cardKeywords) {
            return IntentClassificationResult(
                intent: .unblockCard(cardId: nil),
                confidence: 0.9,
                entities: entities,
                rawText: text
            )
        }

        if detectKeywords(in: normalizedText, keywords: spendingKeywords) {
            let category = extractCategory(from: normalizedText)
            return IntentClassificationResult(
                intent: .spendingAnalysis(category: category),
                confidence: 0.85,
                entities: entities,
                rawText: text
            )
        }

        if detectKeywords(in: normalizedText, keywords: transactionKeywords) {
            return IntentClassificationResult(
                intent: .getTransactions(filter: nil),
                confidence: 0.85,
                entities: entities,
                rawText: text
            )
        }

        if detectKeywords(in: normalizedText, keywords: balanceKeywords) {
            return IntentClassificationResult(
                intent: .checkBalance,
                confidence: 0.9,
                entities: entities,
                rawText: text
            )
        }

        return IntentClassificationResult(
            intent: .unknown(rawText: text),
            confidence: 0.3,
            entities: entities,
            rawText: text
        )
    }

    // MARK: - Entity Extraction

    private func extractAmount(from text: String) -> Decimal? {
        // Match patterns: "500", "500 AED", "$500", "AED 500", "1,000.50"
        let pattern = #"(?:AED|USD|\$|aed)?\s*([0-9]{1,3}(?:,?[0-9]{3})*(?:\.[0-9]{1,2})?)\s*(?:AED|USD|aed|dirhams?)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        let amountString = String(text[range]).replacingOccurrences(of: ",", with: "")
        return Decimal(string: amountString)
    }

    private func extractRecipient(from text: String) -> String? {
        // Look for names after "to" keyword
        let toPattern = #"(?:to|for)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)"#
        if let regex = try? NSRegularExpression(pattern: toPattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }

        // Fallback: use NLTagger to find personal names
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        var name: String?

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if tag == .personalName {
                name = String(text[range])
                return false
            }
            return true
        }

        return name
    }

    private func extractCategory(from text: String) -> Transaction.Category? {
        let categoryMap: [String: Transaction.Category] = [
            "food": .food, "restaurant": .food, "dining": .food, "eat": .food,
            "transport": .transport, "uber": .transport, "careem": .transport, "taxi": .transport,
            "shopping": .shopping, "shop": .shopping, "buy": .shopping, "purchase": .shopping,
            "utilities": .utilities, "electric": .utilities, "water": .utilities, "dewa": .utilities,
            "entertainment": .entertainment, "movie": .entertainment, "netflix": .entertainment,
            "health": .health, "medical": .health, "doctor": .health, "hospital": .health,
            "education": .education, "school": .education, "university": .education, "course": .education
        ]

        let words = text.lowercased().split(separator: " ").map(String.init)
        for word in words {
            if let category = categoryMap[word] {
                return category
            }
        }
        return nil
    }

    private func detectKeywords(in text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}
