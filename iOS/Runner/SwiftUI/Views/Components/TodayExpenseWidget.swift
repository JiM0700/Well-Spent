import SwiftUI
import WidgetKit

// ── Timeline Entry ────────────────────────────────────────────────────────────

public struct TodayExpenseEntry: TimelineEntry {
    public let date: Date
    public let data: TodayExpenseWidgetData

    public init(date: Date, data: TodayExpenseWidgetData) {
        self.date = date
        self.data = data
    }
}

// ── Timeline Provider ─────────────────────────────────────────────────────────

public struct TodayExpenseTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> TodayExpenseEntry {
        TodayExpenseEntry(date: Date(), data: .placeholder)
    }

    public func getSnapshot(in context: Context, completion: @escaping (TodayExpenseEntry) -> Void) {
        let data = WidgetDataManager.shared.getWidgetData()
        let entry = TodayExpenseEntry(date: Date(), data: data)
        completion(entry)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<TodayExpenseEntry>) -> Void) {
        let data = WidgetDataManager.shared.getWidgetData()
        let currentDate = Date()
        let entry = TodayExpenseEntry(date: currentDate, data: data)

        // Schedule reload at start of next hour and at midnight
        let calendar = Calendar.current
        let nextUpdate = calendar.date(byAdding: .minute, value: 30, to: currentDate) ?? currentDate.addingTimeInterval(1800)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// ── Main Widget Entry View ────────────────────────────────────────────────────

public struct TodayExpenseWidgetEntryView: View {
    var entry: TodayExpenseTimelineProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    public init(entry: TodayExpenseTimelineProvider.Entry) {
        self.entry = entry
    }

    public var body: some View {
        switch family {
        case .systemSmall:
            SmallTodayWidgetView(data: entry.data)
        case .systemMedium:
            MediumTodayWidgetView(data: entry.data)
        #if os(iOS)
        case .accessoryRectangular:
            AccessoryRectangularWidgetView(data: entry.data)
        case .accessoryCircular:
            AccessoryCircularWidgetView(data: entry.data)
        case .accessoryInline:
            AccessoryInlineWidgetView(data: entry.data)
        #endif
        default:
            SmallTodayWidgetView(data: entry.data)
        }
    }
}

// ── Small Widget (.systemSmall) ───────────────────────────────────────────────

struct SmallTodayWidgetView: View {
    let data: TodayExpenseWidgetData
    @Environment(\.colorScheme) var colorScheme

    var accentColor: Color {
        accentColorFromName(data.accentColorName)
    }

    var progress: Double {
        data.dailyBudget > 0 ? min(1.0, data.todayTotal / data.dailyBudget) : 0.0
    }

    var isOver: Bool {
        data.todayTotal > data.dailyBudget && data.dailyBudget > 0
    }

    var body: some View {
        ZStack {
            // Ambient Liquid Glow Aura
            RadialGradient(
                colors: [
                    accentColor.opacity(0.18),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 5,
                endRadius: 90
            )

            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack(spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 22, height: 22)
                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(accentColor)
                    }

                    Text("Today's Pulse")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(isOver ? "OVER" : "\(Int(progress * 100))%")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(isOver ? Color.red : accentColor)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background((isOver ? Color.red : accentColor).opacity(0.15))
                        .clipShape(Capsule())
                }

                Spacer(minLength: 2)

                // Spend Hero
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("₹")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f", data.todayTotal))
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Text("of ₹\(Int(data.dailyBudget)) daily allowance")
                        .font(.system(size: 9.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Glowing Liquid Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08))
                            .frame(height: 5)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: isOver ? [Color.orange, Color.red] : [accentColor, accentColor.opacity(0.75)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(4, geo.size.width * CGFloat(progress)), height: 5)
                            .shadow(color: (isOver ? Color.red : accentColor).opacity(0.4), radius: 3, x: 0, y: 1)
                    }
                }
                .frame(height: 5)

                // Footer Status
                HStack {
                    Text(isOver ? "₹\(Int(data.todayTotal - data.dailyBudget)) over" : "₹\(Int(data.remainingDaily)) left")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(isOver ? Color.red : Color.primary)

                    Spacer()

                    Text("\(data.transactionCount) items")
                        .font(.system(size: 9.5))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
        }
        .containerBackground(for: .widget) {
            colorScheme == .dark ? Color.black : Color(red: 0.96, green: 0.96, blue: 0.97)
        }
    }
}

// ── Medium Widget (.systemMedium) ─────────────────────────────────────────────

struct MediumTodayWidgetView: View {
    let data: TodayExpenseWidgetData
    @Environment(\.colorScheme) var colorScheme

    var accentColor: Color {
        accentColorFromName(data.accentColorName)
    }

    var progress: Double {
        data.dailyBudget > 0 ? min(1.0, data.todayTotal / data.dailyBudget) : 0.0
    }

    var isOver: Bool {
        data.todayTotal > data.dailyBudget && data.dailyBudget > 0
    }

    var body: some View {
        HStack(spacing: 14) {
            // Left Half: Spend Pulse & Progress Meter (44% width)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 22, height: 22)
                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(accentColor)
                    }

                    Text("Today's Pulse")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 2)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("₹")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", data.todayTotal))
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.primary)
                }

                // Glowing Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08))
                            .frame(height: 5)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: isOver ? [Color.orange, Color.red] : [accentColor, accentColor.opacity(0.75)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(4, geo.size.width * CGFloat(progress)), height: 5)
                            .shadow(color: (isOver ? Color.red : accentColor).opacity(0.4), radius: 3, x: 0, y: 1)
                    }
                }
                .frame(height: 5)

                HStack {
                    Text("₹\(Int(data.remainingDaily)) left")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundStyle(isOver ? Color.red : Color.primary)
                    Spacer()
                    Text("\(Int(progress * 100))% used")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .opacity(0.3)

            // Right Half: Today's Recent Transactions (56% width)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("ACTIVITY")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(data.transactionCount) total")
                        .font(.system(size: 9.5))
                        .foregroundStyle(.secondary)
                }

                if data.recentTransactions.isEmpty {
                    Spacer()
                    VStack(alignment: .center, spacing: 4) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(accentColor)
                        Text("No transactions today")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    VStack(spacing: 5) {
                        ForEach(data.recentTransactions.prefix(3)) { item in
                            HStack(spacing: 7) {
                                Image(systemName: symbolForCategory(item.category))
                                    .font(.system(size: 11))
                                    .foregroundStyle(colorForCategory(item.category))
                                    .frame(width: 18, height: 18)
                                    .background(colorForCategory(item.category).opacity(0.15))
                                    .clipShape(Circle())

                                Text(item.title)
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundStyle(Color.primary)
                                    .lineLimit(1)

                                Spacer()

                                Text("₹\(Int(item.amount))")
                                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.primary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            colorScheme == .dark ? Color.black : Color(red: 0.96, green: 0.96, blue: 0.97)
        }
    }
}

// ── iOS Lock Screen & StandBy Accessory Views ─────────────────────────────────

#if os(iOS)
struct AccessoryRectangularWidgetView: View {
    let data: TodayExpenseWidgetData

    var progress: Double {
        data.dailyBudget > 0 ? min(1.0, data.todayTotal / data.dailyBudget) : 0.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("TODAY")
                    .font(.system(size: 10, weight: .bold))
                Spacer()
                Text("₹\(Int(data.todayTotal))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            ProgressView(value: progress)
            Text("₹\(Int(data.remainingDaily)) remaining today")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}

struct AccessoryCircularWidgetView: View {
    let data: TodayExpenseWidgetData

    var progress: Double {
        data.dailyBudget > 0 ? min(1.0, data.todayTotal / data.dailyBudget) : 0.0
    }

    var body: some View {
        Gauge(value: progress) {
            Image(systemName: "wallet.pass")
        } currentValueLabel: {
            Text("\(Int(data.todayTotal))")
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct AccessoryInlineWidgetView: View {
    let data: TodayExpenseWidgetData

    var body: some View {
        Text("Today: ₹\(Int(data.todayTotal)) (₹\(Int(data.remainingDaily)) left)")
    }
}
#endif

// ── Helper Helpers ────────────────────────────────────────────────────────────

func accentColorFromName(_ name: String) -> Color {
    switch name {
    case "blue": return Color.blue
    case "indigo": return Color.indigo
    case "purple": return Color.purple
    case "orange": return Color.orange
    case "teal": return Color.teal
    case "pink": return Color.pink
    default: return Color.green
    }
}

func symbolForCategory(_ category: String) -> String {
    switch category.lowercased() {
    case "food": return "fork.knife"
    case "transport": return "car.fill"
    case "utilities": return "bolt.fill"
    case "entertainment": return "tv.fill"
    case "health": return "heart.fill"
    case "shopping": return "bag.fill"
    case "housing": return "house.fill"
    default: return "ellipsis.circle.fill"
    }
}

func colorForCategory(_ category: String) -> Color {
    switch category.lowercased() {
    case "food": return .orange
    case "transport": return .blue
    case "utilities": return .yellow
    case "entertainment": return .purple
    case "health": return .red
    case "shopping": return .pink
    case "housing": return .teal
    default: return .gray
    }
}

// ── Widget Configuration ──────────────────────────────────────────────────────

public struct TodayExpenseWidget: Widget {
    public let kind: String = "TodayExpenseWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayExpenseTimelineProvider()) { entry in
            TodayExpenseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today's Expense Pulse")
        .description("Track your daily spend, remaining allowance, and recent transactions at a glance.")
        #if os(iOS)
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline
        ])
        #else
        .supportedFamilies([
            .systemSmall,
            .systemMedium
        ])
        #endif
    }
}
