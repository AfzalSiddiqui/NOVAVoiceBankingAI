// NOVA Voice Banking AI
// FraudDetectionUseCase - Fraud risk scoring engine

import Foundation

final class FraudDetectionUseCase: Sendable {

    func execute(amount: Decimal, location: String, isNewRecipient: Bool) async -> FraudScore {
        // Simulate processing delay
        try? await Task.sleep(nanoseconds: 100_000_000)

        var factors: [RiskFactor] = []
        var totalScore: Float = 0

        // Amount risk
        let amountScore: Float
        switch amount {
        case ..<1000: amountScore = 0.1
        case 1000..<5000: amountScore = 0.3
        case 5000..<20000: amountScore = 0.6
        default: amountScore = 0.9
        }
        factors.append(RiskFactor(name: "Amount", weight: amountScore, description: amount >= 20000 ? "Unusually large transaction: \(amount) AED" : "Normal transaction amount"))
        totalScore += amountScore * 0.4

        // Location risk
        let locationScore: Float = location.contains("Dubai") || location.contains("Abu Dhabi") ? 0.1 : 0.7
        factors.append(RiskFactor(name: "Location", weight: locationScore, description: locationScore < 0.3 ? "Transaction from known location" : "Transaction from new location"))
        totalScore += locationScore * 0.3

        // New recipient risk
        let recipientScore: Float = isNewRecipient ? 0.5 : 0.1
        factors.append(RiskFactor(name: "Recipient", weight: recipientScore, description: isNewRecipient ? "New recipient" : "Known recipient"))
        totalScore += recipientScore * 0.3

        let riskLevel = FraudScore.RiskLevel.from(score: totalScore)
        let recommendation = FraudScore.Recommendation.from(riskLevel: riskLevel)

        return FraudScore(
            transactionId: UUID().uuidString,
            riskScore: totalScore,
            riskLevel: riskLevel,
            factors: factors,
            recommendation: recommendation
        )
    }
}
