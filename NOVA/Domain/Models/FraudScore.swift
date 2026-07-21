// NOVA Voice Banking AI
// FraudScore - Fraud detection result model

import Foundation

struct FraudScore: Identifiable, Sendable, Equatable {
    let id: String
    let transactionId: String
    let riskScore: Float
    let riskLevel: RiskLevel
    let factors: [RiskFactor]
    let recommendation: Recommendation
    let timestamp: Date

    init(
        id: String = UUID().uuidString,
        transactionId: String,
        riskScore: Float,
        riskLevel: RiskLevel,
        factors: [RiskFactor],
        recommendation: Recommendation,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.transactionId = transactionId
        self.riskScore = riskScore
        self.riskLevel = riskLevel
        self.factors = factors
        self.recommendation = recommendation
        self.timestamp = timestamp
    }

    enum RiskLevel: String, Codable, Sendable {
        case low
        case medium
        case high
        case critical

        var displayColor: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }

        static func from(score: Float) -> RiskLevel {
            switch score {
            case 0..<0.3: return .low
            case 0.3..<0.6: return .medium
            case 0.6..<0.85: return .high
            default: return .critical
            }
        }
    }

    enum Recommendation: String, Codable, Sendable {
        case approve
        case requireVerification
        case block

        var displayName: String {
            switch self {
            case .approve: return "Approve"
            case .requireVerification: return "Require Verification"
            case .block: return "Block"
            }
        }

        static func from(riskLevel: RiskLevel) -> Recommendation {
            switch riskLevel {
            case .low: return .approve
            case .medium: return .approve
            case .high: return .requireVerification
            case .critical: return .block
            }
        }
    }

    static var mock: FraudScore {
        FraudScore(
            transactionId: "TXN001",
            riskScore: 0.25,
            riskLevel: .low,
            factors: [
                RiskFactor(name: "Amount", weight: 0.2, description: "Normal transaction amount"),
                RiskFactor(name: "Location", weight: 0.1, description: "Transaction from known location")
            ],
            recommendation: .approve
        )
    }

    static var mockHighRisk: FraudScore {
        FraudScore(
            transactionId: "TXN002",
            riskScore: 0.95,
            riskLevel: .critical,
            factors: [
                RiskFactor(name: "Amount", weight: 0.9, description: "Unusually large transaction: 20,000 AED"),
                RiskFactor(name: "Location", weight: 0.8, description: "Transaction from new location"),
                RiskFactor(name: "Device", weight: 0.7, description: "Unrecognized device")
            ],
            recommendation: .block
        )
    }
}

// MARK: - Risk Factor

struct RiskFactor: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let name: String
    let weight: Float
    let description: String

    init(id: String = UUID().uuidString, name: String, weight: Float, description: String) {
        self.id = id
        self.name = name
        self.weight = weight
        self.description = description
    }
}
