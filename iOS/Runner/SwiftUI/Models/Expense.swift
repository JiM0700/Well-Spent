import Foundation
import SwiftUI

public enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case food = "food"
    case transport = "transport"
    case utilities = "utilities"
    case entertainment = "entertainment"
    case health = "health"
    case shopping = "shopping"
    case housing = "housing"
    case other = "other"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .food: return "Food & Dining"
        case .transport: return "Transport"
        case .utilities: return "Utilities"
        case .entertainment: return "Entertainment"
        case .health: return "Health & Fitness"
        case .shopping: return "Shopping"
        case .housing: return "Housing & Rent"
        case .other: return "Other"
        }
    }

    public var sfSymbol: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .utilities: return "bolt.fill"
        case .entertainment: return "tv.fill"
        case .health: return "heart.fill"
        case .shopping: return "bag.fill"
        case .housing: return "house.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    public var color: Color {
        switch self {
        case .food: return .orange
        case .transport: return .blue
        case .utilities: return .yellow
        case .entertainment: return .purple
        case .health: return .red
        case .shopping: return .pink
        case .housing: return .teal
        case .other: return .gray
        }
    }
}

public struct Expense: Identifiable, Codable, Hashable {
    public let id: String
    public var title: String
    public var amount: Double
    public var category: ExpenseCategory
    public var date: Date
    public var notes: String
    public var isExpense: Bool

    public init(
        id: String = UUID().uuidString,
        title: String,
        amount: Double,
        category: ExpenseCategory,
        date: Date = Date(),
        notes: String = "",
        isExpense: Bool = true
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.notes = notes
        self.isExpense = isExpense
    }
}

public struct RecurringBill: Identifiable, Codable, Hashable {
    public let id: String
    public var title: String
    public var amount: Double
    public var category: ExpenseCategory
    public var dueDay: Int
    public var isPaid: Bool

    public init(
        id: String = UUID().uuidString,
        title: String,
        amount: Double,
        category: ExpenseCategory,
        dueDay: Int,
        isPaid: Bool = false
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.dueDay = dueDay
        self.isPaid = isPaid
    }
}
