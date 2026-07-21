// NOVA Voice Banking AI
// Card - Banking card domain model

import Foundation

struct Card: Identifiable, Codable, Sendable, Equatable {

    enum CardType: String, Codable, Sendable, CaseIterable {
        case debit
        case credit
        case prepaid
    }

    enum CardNetwork: String, Codable, Sendable, CaseIterable {
        case visa
        case mastercard
    }

    let id: String
    let accountId: String
    let cardNumber: String
    let cardType: CardType
    let cardNetwork: CardNetwork
    let holderName: String
    let expiryDate: String
    var isFrozen: Bool
    let isActive: Bool
    var dailyLimit: Decimal
    let monthlyLimit: Decimal
    let currentMonthSpend: Decimal

    init(
        id: String = UUID().uuidString,
        accountId: String,
        cardNumber: String,
        cardType: CardType,
        cardNetwork: CardNetwork,
        holderName: String,
        expiryDate: String,
        isFrozen: Bool = false,
        isActive: Bool = true,
        dailyLimit: Decimal = 10_000,
        monthlyLimit: Decimal = 50_000,
        currentMonthSpend: Decimal = 0
    ) {
        self.id = id
        self.accountId = accountId
        self.cardNumber = cardNumber
        self.cardType = cardType
        self.cardNetwork = cardNetwork
        self.holderName = holderName
        self.expiryDate = expiryDate
        self.isFrozen = isFrozen
        self.isActive = isActive
        self.dailyLimit = dailyLimit
        self.monthlyLimit = monthlyLimit
        self.currentMonthSpend = currentMonthSpend
    }

    var maskedNumber: String {
        "•••• •••• •••• " + String(cardNumber.suffix(4))
    }

    var remainingDailyLimit: Decimal {
        dailyLimit - currentMonthSpend
    }

    static var mock: Card {
        Card(
            id: "CARD001",
            accountId: "ACC001",
            cardNumber: "4532123456789012",
            cardType: .debit,
            cardNetwork: .visa,
            holderName: "AHMED AL MAKTOUM",
            expiryDate: "12/28",
            dailyLimit: 10_000,
            monthlyLimit: 50_000,
            currentMonthSpend: 8_750
        )
    }

    static var mockCredit: Card {
        Card(
            id: "CARD002",
            accountId: "ACC001",
            cardNumber: "5412345678901234",
            cardType: .credit,
            cardNetwork: .mastercard,
            holderName: "AHMED AL MAKTOUM",
            expiryDate: "06/29",
            dailyLimit: 25_000,
            monthlyLimit: 100_000,
            currentMonthSpend: 15_200
        )
    }
}
