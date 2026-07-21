// NOVA Voice Banking AI
// Transaction - Banking transaction domain model

import Foundation

struct Transaction: Identifiable, Codable, Sendable, Equatable {

    enum TransactionType: String, Codable, Sendable, CaseIterable {
        case credit
        case debit
        case transfer
        case payment
    }

    enum Category: String, Codable, Sendable, CaseIterable {
        case food
        case transport
        case shopping
        case utilities
        case entertainment
        case health
        case education
        case salary
        case transfer
        case other

        var icon: String {
            switch self {
            case .food: return "fork.knife"
            case .transport: return "car.fill"
            case .shopping: return "bag.fill"
            case .utilities: return "bolt.fill"
            case .entertainment: return "tv.fill"
            case .health: return "heart.fill"
            case .education: return "book.fill"
            case .salary: return "banknote.fill"
            case .transfer: return "arrow.left.arrow.right"
            case .other: return "ellipsis.circle.fill"
            }
        }

        var displayName: String {
            rawValue.capitalized
        }
    }

    enum Status: String, Codable, Sendable, CaseIterable {
        case completed
        case pending
        case failed
        case cancelled
    }

    let id: String
    let accountId: String
    let type: TransactionType
    let amount: Decimal
    let currency: String
    let description: String
    let merchantName: String?
    let category: Category
    let date: Date
    let status: Status
    let reference: String
    let counterpartyName: String?
    let counterpartyAccount: String?
    let location: String?

    init(
        id: String = UUID().uuidString,
        accountId: String = "ACC001",
        type: TransactionType,
        amount: Decimal,
        currency: String = "AED",
        description: String,
        merchantName: String? = nil,
        category: Category,
        date: Date = Date(),
        status: Status = .completed,
        reference: String = "REF\(Int.random(in: 100000...999999))",
        counterpartyName: String? = nil,
        counterpartyAccount: String? = nil,
        location: String? = nil
    ) {
        self.id = id
        self.accountId = accountId
        self.type = type
        self.amount = amount
        self.currency = currency
        self.description = description
        self.merchantName = merchantName
        self.category = category
        self.date = date
        self.status = status
        self.reference = reference
        self.counterpartyName = counterpartyName
        self.counterpartyAccount = counterpartyAccount
        self.location = location
    }

    var isCredit: Bool { type == .credit }
    var isDebit: Bool { type == .debit || type == .payment }

    var signedAmount: Decimal {
        isCredit ? amount : -amount
    }

    static var mock: Transaction {
        Transaction(
            type: .debit,
            amount: 125.50,
            description: "Lunch at Zuma",
            merchantName: "Zuma Restaurant",
            category: .food,
            location: "Dubai, UAE"
        )
    }
}

// MARK: - Transaction Filter

struct TransactionFilter: Sendable, Codable, Equatable {
    var startDate: Date?
    var endDate: Date?
    var category: Transaction.Category?
    var minAmount: Decimal?
    var maxAmount: Decimal?
    var type: Transaction.TransactionType?
    var status: Transaction.Status?

    static var empty: TransactionFilter { TransactionFilter() }
}
