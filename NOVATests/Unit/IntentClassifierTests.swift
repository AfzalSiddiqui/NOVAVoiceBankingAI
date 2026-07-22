// NOVA Voice Banking AI
// IntentClassifierTests - Unit tests for intent classification

import XCTest
@testable import NOVA

final class IntentClassifierTests: XCTestCase {

    private var classifier: IntentClassifier!

    override func setUp() {
        super.setUp()
        classifier = IntentClassifier()
    }

    // MARK: - Balance Intent

    func testClassifyBalanceIntent() async {
        let result = await classifier.classify(text: "Show my account balance")
        if case .checkBalance = result.intent {
            XCTAssertGreaterThanOrEqual(result.confidence, 0.7)
        } else {
            XCTFail("Expected checkBalance intent, got \(result.intent)")
        }
    }

    func testClassifyBalanceWithHowMuch() async {
        let result = await classifier.classify(text: "How much money do I have")
        if case .checkBalance = result.intent {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected checkBalance intent")
        }
    }

    // MARK: - Transfer Intent

    func testClassifyTransferIntent() async {
        let result = await classifier.classify(text: "Transfer 500 AED to Ahmed")
        if case .transferMoney(let amount, let recipient) = result.intent {
            XCTAssertEqual(amount, 500)
            XCTAssertEqual(recipient, "Ahmed")
        } else {
            XCTFail("Expected transferMoney intent, got \(result.intent)")
        }
    }

    func testClassifyTransferWithoutAmount() async {
        let result = await classifier.classify(text: "Send money to someone")
        if case .transferMoney = result.intent {
            XCTAssertLessThan(result.confidence, 0.9)
        } else {
            XCTFail("Expected transferMoney intent")
        }
    }

    // MARK: - Transaction Intent

    func testClassifyTransactionIntent() async {
        let result = await classifier.classify(text: "Show my recent transactions")
        if case .getTransactions = result.intent {
            XCTAssertGreaterThanOrEqual(result.confidence, 0.7)
        } else {
            XCTFail("Expected getTransactions intent, got \(result.intent)")
        }
    }

    // MARK: - Card Block Intent

    func testClassifyBlockCardIntent() async {
        let result = await classifier.classify(text: "Block my card")
        if case .blockCard = result.intent {
            XCTAssertGreaterThanOrEqual(result.confidence, 0.8)
        } else {
            XCTFail("Expected blockCard intent, got \(result.intent)")
        }
    }

    func testClassifyUnblockCardIntent() async {
        let result = await classifier.classify(text: "Unfreeze my card")
        if case .unblockCard = result.intent {
            XCTAssertGreaterThanOrEqual(result.confidence, 0.8)
        } else {
            XCTFail("Expected unblockCard intent, got \(result.intent)")
        }
    }

    // MARK: - Spending Intent

    func testClassifySpendingIntent() async {
        let result = await classifier.classify(text: "How much did I spend on food")
        if case .spendingAnalysis(let category) = result.intent {
            XCTAssertEqual(category, .food)
        } else {
            XCTFail("Expected spendingAnalysis intent, got \(result.intent)")
        }
    }

    func testClassifySpendingWithoutCategory() async {
        let result = await classifier.classify(text: "Show my spending")
        if case .spendingAnalysis(let category) = result.intent {
            XCTAssertNil(category)
        } else {
            XCTFail("Expected spendingAnalysis intent")
        }
    }

    // MARK: - Financial Advice Intent

    func testClassifyAdviceIntent() async {
        let result = await classifier.classify(text: "Can I afford a new car")
        if case .financialAdvice = result.intent {
            XCTAssertGreaterThanOrEqual(result.confidence, 0.7)
        } else {
            XCTFail("Expected financialAdvice intent, got \(result.intent)")
        }
    }

    // MARK: - Unknown Intent

    func testClassifyUnknownIntent() async {
        let result = await classifier.classify(text: "Hello there")
        if case .unknown = result.intent {
            XCTAssertLessThan(result.confidence, 0.5)
        } else {
            XCTFail("Expected unknown intent, got \(result.intent)")
        }
    }

    // MARK: - Confidence

    func testHighConfidenceResult() async {
        let result = await classifier.classify(text: "Check my balance")
        XCTAssertTrue(result.isHighConfidence)
    }

    func testLowConfidenceForAmbiguousInput() async {
        let result = await classifier.classify(text: "xyz abc")
        XCTAssertFalse(result.isHighConfidence)
    }
}
