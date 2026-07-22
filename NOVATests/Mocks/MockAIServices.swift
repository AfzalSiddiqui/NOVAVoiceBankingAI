// NOVA Voice Banking AI
// MockAIServices - Test doubles for AI service protocols

import Foundation
import Combine
import AVFoundation
@testable import NOVA

final class MockIntentClassifier: IntentClassifierProtocol, Sendable {
    var mockResult = IntentClassificationResult.mock

    func classify(text: String) async -> IntentClassificationResult {
        mockResult
    }
}

final class MockAIResponseGenerator: AIResponseGeneratorProtocol, Sendable {
    var mockResponse = AIResponse(text: "Mock response", suggestions: ["Option 1"])

    func generateResponse(for intent: BankingIntent, context: ResponseContext) async -> AIResponse {
        mockResponse
    }

    func generateFinancialAdvice(query: String, financialData: FinancialSummary) async -> AIResponse {
        AIResponse(text: "Mock financial advice for: \(query)", suggestions: ["Save more"])
    }
}
