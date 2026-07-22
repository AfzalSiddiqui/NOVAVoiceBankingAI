// NOVA Voice Banking AI
// RepositoryTests - Unit tests for repository implementations

import XCTest
@testable import NOVA

final class BankingRepositoryTests: XCTestCase {

    private var repository: BankingRepository!

    override func setUp() {
        super.setUp()
        let networkClient = NetworkClient()
        let keychain = KeychainManager(serviceName: "com.nova.test")
        let encryption = EncryptionService()
        let storage = SecureStorageManager(keychainManager: keychain, encryptionService: encryption)
        repository = BankingRepository(networkClient: networkClient, storage: storage)
    }

    func testGetAccounts() async throws {
        let accounts = try await repository.getAccounts()
        XCTAssertFalse(accounts.isEmpty)
        XCTAssertTrue(accounts.contains(where: { $0.accountType == .current }))
        XCTAssertTrue(accounts.contains(where: { $0.accountType == .savings }))
    }

    func testGetAccountById() async throws {
        let account = try await repository.getAccount(id: "ACC001")
        XCTAssertEqual(account.id, "ACC001")
        XCTAssertEqual(account.accountType, .current)
    }

    func testGetAccountByInvalidIdThrows() async {
        do {
            _ = try await repository.getAccount(id: "INVALID")
            XCTFail("Should throw for invalid ID")
        } catch {
            XCTAssertTrue(error is BankingError)
        }
    }

    func testGetTotalBalance() async throws {
        let total = try await repository.getTotalBalance()
        XCTAssertGreaterThan(total, 0)
    }

    func testTransferMoney() async throws {
        let txn = try await repository.transferMoney(
            from: "ACC001", to: "ACC002", amount: 100, currency: "AED", note: "Test transfer"
        )
        XCTAssertEqual(txn.type, .transfer)
        XCTAssertEqual(txn.amount, 100)
    }

    func testTransferInvalidAmountThrows() async {
        do {
            _ = try await repository.transferMoney(
                from: "ACC001", to: "ACC002", amount: -50, currency: "AED", note: nil
            )
            XCTFail("Should throw for negative amount")
        } catch {
            XCTAssertTrue(error is BankingError)
        }
    }
}

final class TransactionRepositoryTests: XCTestCase {

    private var repository: TransactionRepository!

    override func setUp() {
        super.setUp()
        repository = TransactionRepository(networkClient: NetworkClient())
    }

    func testGetAllTransactions() async throws {
        let transactions = try await repository.getTransactions(accountId: nil, filter: nil)
        XCTAssertGreaterThan(transactions.count, 0)
    }

    func testGetRecentTransactions() async throws {
        let recent = try await repository.getRecentTransactions(limit: 3)
        XCTAssertLessThanOrEqual(recent.count, 3)
    }

    func testGetTransactionById() async throws {
        let txn = try await repository.getTransaction(id: "TXN001")
        XCTAssertEqual(txn.id, "TXN001")
    }

    func testGetTransactionByInvalidIdThrows() async {
        do {
            _ = try await repository.getTransaction(id: "INVALID")
            XCTFail("Should throw")
        } catch {
            XCTAssertTrue(error is TransactionError)
        }
    }

    func testSearchTransactions() async throws {
        let results = try await repository.searchTransactions(query: "Zuma")
        XCTAssertTrue(results.allSatisfy {
            $0.description.lowercased().contains("zuma") ||
            ($0.merchantName?.lowercased().contains("zuma") ?? false)
        })
    }

    func testGetSpendingByCategory() async throws {
        let start = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        let breakdown = try await repository.getSpendingByCategory(from: start, to: Date())
        XCTAssertFalse(breakdown.isEmpty)
        // Percentages should roughly sum to 100
        let totalPercentage = breakdown.reduce(0.0) { $0 + $1.percentage }
        XCTAssertEqual(totalPercentage, 100.0, accuracy: 1.0)
    }

    func testFilterByCategory() async throws {
        let filter = TransactionFilter(category: .food)
        let results = try await repository.getTransactions(accountId: nil, filter: filter)
        XCTAssertTrue(results.allSatisfy { $0.category == .food })
    }

    func testTransactionsAreSortedByDate() async throws {
        let transactions = try await repository.getTransactions(accountId: nil, filter: nil)
        for i in 1..<transactions.count {
            XCTAssertGreaterThanOrEqual(transactions[i - 1].date, transactions[i].date)
        }
    }
}

final class CardRepositoryTests: XCTestCase {

    private var repository: CardRepository!

    override func setUp() {
        super.setUp()
        repository = CardRepository(networkClient: NetworkClient())
    }

    func testGetCards() async throws {
        let cards = try await repository.getCards()
        XCTAssertEqual(cards.count, 2)
    }

    func testFreezeCard() async throws {
        let card = try await repository.freezeCard(id: "CARD001")
        XCTAssertTrue(card.isFrozen)
    }

    func testUnfreezeCard() async throws {
        _ = try await repository.freezeCard(id: "CARD001")
        let card = try await repository.unfreezeCard(id: "CARD001")
        XCTAssertFalse(card.isFrozen)
    }

    func testSetDailyLimit() async throws {
        let card = try await repository.setDailyLimit(cardId: "CARD001", limit: 20_000)
        XCTAssertEqual(card.dailyLimit, 20_000)
    }

    func testFreezeInvalidCardThrows() async {
        do {
            _ = try await repository.freezeCard(id: "INVALID")
            XCTFail("Should throw")
        } catch {
            XCTAssertTrue(error is CardError)
        }
    }
}

final class WealthRepositoryTests: XCTestCase {

    private var repository: WealthRepository!

    override func setUp() {
        super.setUp()
        repository = WealthRepository(networkClient: NetworkClient())
    }

    func testGetPortfolio() async throws {
        let portfolio = try await repository.getPortfolio()
        XCTAssertGreaterThan(portfolio.totalValue, 0)
        XCTAssertFalse(portfolio.assets.isEmpty)
    }

    func testGetAssetAllocation() async throws {
        let allocation = try await repository.getAssetAllocation()
        XCTAssertFalse(allocation.isEmpty)
        let total = allocation.reduce(0.0) { $0 + $1.percentage }
        XCTAssertEqual(total, 100.0, accuracy: 1.0)
    }

    func testGetPerformanceHistory() async throws {
        let history = try await repository.getPerformanceHistory(period: .week)
        XCTAssertEqual(history.count, PerformancePeriod.week.days)
    }
}
