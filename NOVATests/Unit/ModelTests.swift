// NOVA Voice Banking AI
// ModelTests - Unit tests for domain models

import XCTest
@testable import NOVA

final class AccountModelTests: XCTestCase {

    func testMockAccount() {
        let account = Account.mock
        XCTAssertEqual(account.id, "ACC001")
        XCTAssertEqual(account.accountType, .current)
        XCTAssertEqual(account.balance, 45_750.50)
        XCTAssertEqual(account.currency, "AED")
        XCTAssertTrue(account.isActive)
    }

    func testMockSavingsAccount() {
        let account = Account.mockSavings
        XCTAssertEqual(account.accountType, .savings)
        XCTAssertEqual(account.balance, 125_000)
    }
}

final class TransactionModelTests: XCTestCase {

    func testMockTransaction() {
        let txn = Transaction.mock
        XCTAssertEqual(txn.type, .debit)
        XCTAssertEqual(txn.amount, 125.50)
        XCTAssertEqual(txn.category, .food)
    }

    func testSignedAmount() {
        let credit = Transaction(type: .credit, amount: 100, description: "Credit", category: .salary)
        let debit = Transaction(type: .debit, amount: 100, description: "Debit", category: .food)

        XCTAssertEqual(credit.signedAmount, 100)
        XCTAssertEqual(debit.signedAmount, -100)
    }

    func testIsCreditDebit() {
        let credit = Transaction(type: .credit, amount: 100, description: "Credit", category: .salary)
        let debit = Transaction(type: .debit, amount: 100, description: "Debit", category: .food)
        let payment = Transaction(type: .payment, amount: 100, description: "Payment", category: .utilities)

        XCTAssertTrue(credit.isCredit)
        XCTAssertFalse(credit.isDebit)
        XCTAssertTrue(debit.isDebit)
        XCTAssertTrue(payment.isDebit)
    }

    func testTransactionFilterEmpty() {
        let filter = TransactionFilter.empty
        XCTAssertNil(filter.startDate)
        XCTAssertNil(filter.category)
        XCTAssertNil(filter.minAmount)
    }

    func testCategoryIcons() {
        XCTAssertEqual(Transaction.Category.food.icon, "fork.knife")
        XCTAssertEqual(Transaction.Category.transport.icon, "car.fill")
        XCTAssertEqual(Transaction.Category.shopping.icon, "bag.fill")
    }
}

final class CardModelTests: XCTestCase {

    func testMaskedNumber() {
        let card = Card.mock
        XCTAssertTrue(card.maskedNumber.hasSuffix("9012"))
        XCTAssertTrue(card.maskedNumber.hasPrefix("••••"))
    }

    func testRemainingDailyLimit() {
        let card = Card.mock
        XCTAssertEqual(card.remainingDailyLimit, card.dailyLimit - card.currentMonthSpend)
    }
}

final class FraudScoreModelTests: XCTestCase {

    func testRiskLevelFromScore() {
        XCTAssertEqual(FraudScore.RiskLevel.from(score: 0.1), .low)
        XCTAssertEqual(FraudScore.RiskLevel.from(score: 0.4), .medium)
        XCTAssertEqual(FraudScore.RiskLevel.from(score: 0.7), .high)
        XCTAssertEqual(FraudScore.RiskLevel.from(score: 0.9), .critical)
    }

    func testRecommendationFromRiskLevel() {
        XCTAssertEqual(FraudScore.Recommendation.from(riskLevel: .low), .approve)
        XCTAssertEqual(FraudScore.Recommendation.from(riskLevel: .medium), .approve)
        XCTAssertEqual(FraudScore.Recommendation.from(riskLevel: .high), .requireVerification)
        XCTAssertEqual(FraudScore.Recommendation.from(riskLevel: .critical), .block)
    }
}

final class WealthPortfolioModelTests: XCTestCase {

    func testMockPortfolio() {
        let portfolio = WealthPortfolio.mock
        XCTAssertGreaterThan(portfolio.totalValue, 0)
        XCTAssertFalse(portfolio.assets.isEmpty)
        XCTAssertEqual(portfolio.currency, "AED")
    }

    func testAssetCalculations() {
        let asset = Asset(name: "Test", type: .stock, quantity: 10, currentPrice: 100, purchasePrice: 80)
        XCTAssertEqual(asset.totalValue, 1000)
        XCTAssertEqual(asset.totalCost, 800)
        XCTAssertEqual(asset.gainLoss, 200)
        XCTAssertEqual(asset.gainLossPercentage, 25.0)
    }

    func testAssetTypeDisplayNames() {
        XCTAssertEqual(Asset.AssetType.stock.displayName, "Stocks")
        XCTAssertEqual(Asset.AssetType.gold.displayName, "Gold")
        XCTAssertEqual(Asset.AssetType.crypto.displayName, "Crypto")
    }
}

final class BankingIntentModelTests: XCTestCase {

    func testIntentDisplayNames() {
        XCTAssertEqual(BankingIntent.checkBalance.displayName, "Check Balance")
        XCTAssertEqual(BankingIntent.transferMoney(amount: 100, recipient: "Test").displayName, "Transfer Money")
        XCTAssertEqual(BankingIntent.blockCard(cardId: nil).displayName, "Block Card")
    }

    func testIntentIcons() {
        XCTAssertEqual(BankingIntent.checkBalance.icon, "banknote")
        XCTAssertEqual(BankingIntent.spendingAnalysis(category: nil).icon, "chart.bar")
    }

    func testClassificationResultHighConfidence() {
        let highConf = IntentClassificationResult(intent: .checkBalance, confidence: 0.9)
        let lowConf = IntentClassificationResult(intent: .checkBalance, confidence: 0.5)

        XCTAssertTrue(highConf.isHighConfidence)
        XCTAssertFalse(lowConf.isHighConfidence)
    }
}

final class PerformancePeriodTests: XCTestCase {

    func testAllCases() {
        XCTAssertEqual(PerformancePeriod.allCases.count, 6)
    }

    func testDays() {
        XCTAssertEqual(PerformancePeriod.week.days, 7)
        XCTAssertEqual(PerformancePeriod.month.days, 30)
        XCTAssertEqual(PerformancePeriod.year.days, 365)
    }

    func testDisplayName() {
        XCTAssertEqual(PerformancePeriod.week.displayName, "1W")
        XCTAssertEqual(PerformancePeriod.all.displayName, "ALL")
    }
}
