// NOVA Voice Banking AI
// Account - Banking account domain model

import Foundation

struct Account: Identifiable, Codable, Sendable, Equatable {

    enum AccountType: String, Codable, Sendable, CaseIterable {
        case current
        case savings
        case investment
    }

    let id: String
    let accountNumber: String
    let accountType: AccountType
    let currency: String
    let balance: Decimal
    let availableBalance: Decimal
    let holderName: String
    let iban: String
    let bankName: String
    let isActive: Bool
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        accountNumber: String,
        accountType: AccountType,
        currency: String = "AED",
        balance: Decimal,
        availableBalance: Decimal,
        holderName: String,
        iban: String,
        bankName: String = "NOVA Bank",
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.accountNumber = accountNumber
        self.accountType = accountType
        self.currency = currency
        self.balance = balance
        self.availableBalance = availableBalance
        self.holderName = holderName
        self.iban = iban
        self.bankName = bankName
        self.isActive = isActive
        self.createdAt = createdAt
    }

    static var mock: Account {
        Account(
            id: "ACC001",
            accountNumber: "1234567890",
            accountType: .current,
            balance: 45_750.50,
            availableBalance: 44_500.00,
            holderName: "Ahmed Al Maktoum",
            iban: "AE070331234567890123456"
        )
    }

    static var mockSavings: Account {
        Account(
            id: "ACC002",
            accountNumber: "0987654321",
            accountType: .savings,
            balance: 125_000.00,
            availableBalance: 125_000.00,
            holderName: "Ahmed Al Maktoum",
            iban: "AE070330987654321098765"
        )
    }
}
