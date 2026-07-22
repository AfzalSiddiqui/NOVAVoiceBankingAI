// NOVA Voice Banking AI
// UseCaseTests - Unit tests for domain use cases

import XCTest
@testable import NOVA

final class GetBalanceUseCaseTests: XCTestCase {

    func testGetTotalBalance() async throws {
        let mockRepo = MockBankingRepository()
        let useCase = GetBalanceUseCase(repository: mockRepo)

        let result = try await useCase.execute()

        XCTAssertEqual(result.totalBalance, 170_750.50)
        XCTAssertEqual(result.accounts.count, 2)
    }

    func testGetSingleAccountBalance() async throws {
        let mockRepo = MockBankingRepository()
        let useCase = GetBalanceUseCase(repository: mockRepo)

        let result = try await useCase.execute(accountId: "ACC001")

        XCTAssertEqual(result.accounts.count, 1)
        XCTAssertEqual(result.totalBalance, 45_750.50)
    }

    func testGetBalanceThrowsForInvalidAccount() async {
        let mockRepo = MockBankingRepository()
        let useCase = GetBalanceUseCase(repository: mockRepo)

        do {
            _ = try await useCase.execute(accountId: "INVALID")
            XCTFail("Should have thrown")
        } catch {
            XCTAssertTrue(error is BankingError)
        }
    }
}

final class GetTransactionsUseCaseTests: XCTestCase {

    func testGetAllTransactions() async throws {
        let mockRepo = MockTransactionRepository()
        let useCase = GetTransactionsUseCase(repository: mockRepo)

        let result = try await useCase.execute()

        XCTAssertFalse(result.isEmpty)
    }

    func testGetRecentTransactions() async throws {
        let mockRepo = MockTransactionRepository()
        let useCase = GetTransactionsUseCase(repository: mockRepo)

        let result = try await useCase.getRecent(limit: 5)

        XCTAssertLessThanOrEqual(result.count, 5)
    }

    func testSearchTransactions() async throws {
        let mockRepo = MockTransactionRepository()
        let useCase = GetTransactionsUseCase(repository: mockRepo)

        let result = try await useCase.search(query: "Zuma")

        XCTAssertTrue(result.allSatisfy { $0.description.lowercased().contains("zuma") })
    }

    func testGetTransactionsThrowsOnError() async {
        let mockRepo = MockTransactionRepository()
        mockRepo.shouldThrow = true
        let useCase = GetTransactionsUseCase(repository: mockRepo)

        do {
            _ = try await useCase.execute()
            XCTFail("Should have thrown")
        } catch {
            XCTAssertTrue(error is TransactionError)
        }
    }
}

final class FreezeCardUseCaseTests: XCTestCase {

    func testFreezeCard() async throws {
        let mockRepo = MockCardRepository()
        let useCase = FreezeCardUseCase(repository: mockRepo)

        let card = try await useCase.freeze(cardId: "CARD001")

        XCTAssertTrue(card.isFrozen)
    }

    func testUnfreezeCard() async throws {
        let mockRepo = MockCardRepository()
        let useCase = FreezeCardUseCase(repository: mockRepo)

        // Freeze first then unfreeze
        _ = try await useCase.freeze(cardId: "CARD001")
        let card = try await useCase.unfreeze(cardId: "CARD001")

        XCTAssertFalse(card.isFrozen)
    }

    func testGetCards() async throws {
        let mockRepo = MockCardRepository()
        let useCase = FreezeCardUseCase(repository: mockRepo)

        let cards = try await useCase.getCards()

        XCTAssertEqual(cards.count, 2)
    }

    func testSetDailyLimit() async throws {
        let mockRepo = MockCardRepository()
        let useCase = FreezeCardUseCase(repository: mockRepo)

        let card = try await useCase.setLimit(cardId: "CARD001", dailyLimit: 15_000)

        XCTAssertEqual(card.dailyLimit, 15_000)
    }

    func testFreezeInvalidCardThrows() async {
        let mockRepo = MockCardRepository()
        let useCase = FreezeCardUseCase(repository: mockRepo)

        do {
            _ = try await useCase.freeze(cardId: "INVALID")
            XCTFail("Should have thrown")
        } catch {
            XCTAssertTrue(error is CardError)
        }
    }
}

final class FraudDetectionUseCaseTests: XCTestCase {

    func testLowRiskTransaction() async {
        let useCase = FraudDetectionUseCase()

        let result = await useCase.execute(amount: 100, location: "Dubai, UAE", isNewRecipient: false)

        XCTAssertEqual(result.riskLevel, .low)
        XCTAssertEqual(result.recommendation, .approve)
    }

    func testHighAmountIncreasesRisk() async {
        let useCase = FraudDetectionUseCase()

        let result = await useCase.execute(amount: 25_000, location: "Dubai, UAE", isNewRecipient: false)

        XCTAssertGreaterThan(result.riskScore, 0.3)
    }

    func testNewRecipientIncreasesRisk() async {
        let useCase = FraudDetectionUseCase()

        let lowRisk = await useCase.execute(amount: 500, location: "Dubai, UAE", isNewRecipient: false)
        let higherRisk = await useCase.execute(amount: 500, location: "Dubai, UAE", isNewRecipient: true)

        XCTAssertGreaterThan(higherRisk.riskScore, lowRisk.riskScore)
    }

    func testRiskFactorsPresent() async {
        let useCase = FraudDetectionUseCase()

        let result = await useCase.execute(amount: 1000, location: "Dubai, UAE", isNewRecipient: false)

        XCTAssertEqual(result.factors.count, 3)
        XCTAssertTrue(result.factors.contains(where: { $0.name == "Amount" }))
        XCTAssertTrue(result.factors.contains(where: { $0.name == "Location" }))
        XCTAssertTrue(result.factors.contains(where: { $0.name == "Recipient" }))
    }
}

final class TransferMoneyUseCaseTests: XCTestCase {

    func testSuccessfulTransfer() async throws {
        let mockRepo = MockBankingRepository()
        let fraudDetector = FraudDetectionUseCase()
        let useCase = TransferMoneyUseCase(repository: mockRepo, fraudDetector: fraudDetector)

        let result = try await useCase.execute(from: "ACC001", to: "Ahmed", amount: 500)

        XCTAssertEqual(result.status, .completed)
        XCTAssertNotNil(result.transaction)
    }

    func testTransferWithInvalidAmount() async {
        let mockRepo = MockBankingRepository()
        let fraudDetector = FraudDetectionUseCase()
        let useCase = TransferMoneyUseCase(repository: mockRepo, fraudDetector: fraudDetector)

        do {
            _ = try await useCase.execute(from: "ACC001", to: "Ahmed", amount: -100)
            XCTFail("Should have thrown for invalid amount")
        } catch {
            XCTAssertTrue(error is BankingError)
        }
    }
}
