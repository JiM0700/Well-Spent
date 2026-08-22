import Foundation
import SwiftUI

// ── Hex Color Initializer ───────────────────────────────────────────────────

extension Color {
    public init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    public var hexString: String {
        #if os(iOS)
        let uic = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uic.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        #elseif os(macOS)
        let nsc = NSColor(self)
        guard let rgb = nsc.usingColorSpace(.sRGB) else { return "#007AFF" }
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(rgb.redComponent * 255)), lroundf(Float(rgb.greenComponent * 255)), lroundf(Float(rgb.blueComponent * 255)))
        #else
        return "#007AFF"
        #endif
    }
}

// ── Expense Category (Built-in + User-Defined Custom Categories) ──────────────

public struct ExpenseCategory: Identifiable, Codable, Hashable, RawRepresentable {
    public let id: String
    public var rawValue: String { id }
    public var displayName: String
    public var sfSymbol: String
    public var colorHex: String
    public var isCustom: Bool

    public var color: Color {
        Color(hex: colorHex)
    }

    public init(id: String, displayName: String, sfSymbol: String, colorHex: String, isCustom: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.sfSymbol = sfSymbol
        self.colorHex = colorHex
        self.isCustom = isCustom
    }

    public init(rawValue: String) {
        let clean = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let builtin = Self.builtInCategories.first(where: { $0.id == clean }) {
            self = builtin
        } else {
            self.id = rawValue
            self.displayName = rawValue.capitalized
            self.sfSymbol = "tag.fill"
            self.colorHex = "#007AFF"
            self.isCustom = true
        }
    }

    // Built-in Presets
    public static let food = ExpenseCategory(id: "food", displayName: "Food & Dining", sfSymbol: "fork.knife", colorHex: "#FF9500", isCustom: false)
    public static let transport = ExpenseCategory(id: "transport", displayName: "Transport", sfSymbol: "car.fill", colorHex: "#007AFF", isCustom: false)
    public static let utilities = ExpenseCategory(id: "utilities", displayName: "Utilities", sfSymbol: "bolt.fill", colorHex: "#FFCC00", isCustom: false)
    public static let entertainment = ExpenseCategory(id: "entertainment", displayName: "Entertainment", sfSymbol: "tv.fill", colorHex: "#AF52DE", isCustom: false)
    public static let health = ExpenseCategory(id: "health", displayName: "Health & Fitness", sfSymbol: "heart.fill", colorHex: "#FF3B30", isCustom: false)
    public static let shopping = ExpenseCategory(id: "shopping", displayName: "Shopping", sfSymbol: "bag.fill", colorHex: "#FF2D55", isCustom: false)
    public static let housing = ExpenseCategory(id: "housing", displayName: "Housing & Rent", sfSymbol: "house.fill", colorHex: "#5AC8FA", isCustom: false)
    public static let investment = ExpenseCategory(id: "investment", displayName: "Investments", sfSymbol: "chart.line.uptrend.xyaxis", colorHex: "#34C759", isCustom: false)
    public static let other = ExpenseCategory(id: "other", displayName: "Other", sfSymbol: "ellipsis.circle.fill", colorHex: "#8E8E93", isCustom: false)

    public static var builtInCategories: [ExpenseCategory] {
        [.food, .transport, .utilities, .entertainment, .health, .shopping, .housing, .investment, .other]
    }

    public static var allCases: [ExpenseCategory] {
        builtInCategories
    }

    public static func from(string: String) -> ExpenseCategory {
        let clean = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let direct = builtInCategories.first(where: { $0.id == clean || $0.displayName.lowercased() == clean }) {
            return direct
        }
        if clean.contains("invest") || clean.contains("stock") || clean.contains("mutual") || clean.contains("sip") || clean.contains("crypto") || clean.contains("gold") || clean.contains("equity") || clean.contains("share") || clean.contains("trading") {
            return .investment
        }
        if clean.contains("food") || clean.contains("dining") || clean.contains("cafe") || clean.contains("restaurant") || clean.contains("coffee") || clean.contains("grocery") || clean.contains("groceries") {
            return .food
        }
        if clean.contains("transport") || clean.contains("transit") || clean.contains("fuel") || clean.contains("cab") || clean.contains("uber") || clean.contains("travel") || clean.contains("flight") {
            return .transport
        }
        if clean.contains("utilit") || clean.contains("bill") || clean.contains("power") || clean.contains("electric") || clean.contains("wifi") || clean.contains("water") || clean.contains("gas") {
            return .utilities
        }
        if clean.contains("entertain") || clean.contains("movie") || clean.contains("music") || clean.contains("game") || clean.contains("netflix") || clean.contains("spotify") || clean.contains("cinema") {
            return .entertainment
        }
        if clean.contains("health") || clean.contains("fit") || clean.contains("medic") || clean.contains("doctor") || clean.contains("gym") || clean.contains("pharma") {
            return .health
        }
        if clean.contains("shop") || clean.contains("cloth") || clean.contains("retail") || clean.contains("store") || clean.contains("amazon") || clean.contains("electronics") {
            return .shopping
        }
        if clean.contains("hous") || clean.contains("rent") || clean.contains("home") || clean.contains("maintain") || clean.contains("mortgage") {
            return .housing
        }
        return .other
    }

    enum CodingKeys: String, CodingKey {
        case id, displayName, sfSymbol, colorHex, isCustom
    }

    public init(from decoder: Decoder) throws {
        if let singleContainer = try? decoder.singleValueContainer(), let str = try? singleContainer.decode(String.self) {
            self.init(rawValue: str)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? id.capitalized
        let sfSymbol = try container.decodeIfPresent(String.self, forKey: .sfSymbol) ?? "tag.fill"
        let colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? "#007AFF"
        let isCustom = try container.decodeIfPresent(Bool.self, forKey: .isCustom) ?? true
        self.init(id: id, displayName: displayName, sfSymbol: sfSymbol, colorHex: colorHex, isCustom: isCustom)
    }

    public func encode(to encoder: Encoder) throws {
        if !isCustom {
            var container = encoder.singleValueContainer()
            try container.encode(id)
        } else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(displayName, forKey: .displayName)
            try container.encode(sfSymbol, forKey: .sfSymbol)
            try container.encode(colorHex, forKey: .colorHex)
            try container.encode(isCustom, forKey: .isCustom)
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
    public var tags: [String]

    public init(
        id: String = UUID().uuidString,
        title: String,
        amount: Double,
        category: ExpenseCategory,
        date: Date = Date(),
        notes: String = "",
        isExpense: Bool = true,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.notes = notes
        self.isExpense = isExpense
        self.tags = tags
    }

    enum CodingKeys: String, CodingKey {
        case id, title, amount, category, date, notes, isExpense, tags
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.amount = try container.decodeIfPresent(Double.self, forKey: .amount) ?? 0.0
        self.category = try container.decodeIfPresent(ExpenseCategory.self, forKey: .category) ?? .other
        self.date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.isExpense = try container.decodeIfPresent(Bool.self, forKey: .isExpense) ?? true
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
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

    enum CodingKeys: String, CodingKey {
        case id, title, amount, category, dueDay, isPaid
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.amount = try container.decodeIfPresent(Double.self, forKey: .amount) ?? 0.0
        self.category = try container.decodeIfPresent(ExpenseCategory.self, forKey: .category) ?? .utilities
        self.dueDay = try container.decodeIfPresent(Int.self, forKey: .dueDay) ?? 1
        self.isPaid = try container.decodeIfPresent(Bool.self, forKey: .isPaid) ?? false
    }
}

public struct Goal: Identifiable, Codable, Hashable {
    public let id: String
    public var title: String
    public var targetAmount: Double
    public var currentAmount: Double
    public var deadline: Date?
    public var sfSymbol: String
    public var colorName: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        targetAmount: Double,
        currentAmount: Double = 0.0,
        deadline: Date? = nil,
        sfSymbol: String = "target",
        colorName: String = "blue"
    ) {
        self.id = id
        self.title = title
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.sfSymbol = sfSymbol
        self.colorName = colorName
    }

    public var progress: Double {
        guard targetAmount > 0 else { return 0.0 }
        return min(1.0, max(0.0, currentAmount / targetAmount))
    }

    public var isCompleted: Bool {
        currentAmount >= targetAmount && targetAmount > 0
    }

    public var color: Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "teal": return .teal
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
}

public struct NetWorth: Codable, Hashable {
    public var assets: Double
    public var liabilities: Double
    public var lastUpdated: Date

    public init(assets: Double = 0.0, liabilities: Double = 0.0, lastUpdated: Date = Date()) {
        self.assets = assets
        self.liabilities = liabilities
        self.lastUpdated = lastUpdated
    }

    public var total: Double {
        assets - liabilities
    }
}
