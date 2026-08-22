import Charts
import SwiftUI

public struct InsightsView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var showNewBillSheet: Bool = false
    @State private var editingBill: RecurringBill? = nil
    @State private var selectedDayOffset: Int? = nil
    @State private var activeInfoSection: TrendsInfoSection? = nil
    @Environment(\.colorScheme) var colorScheme

    public enum TrendsInfoSection: Identifiable {
        case last7Days
        case weekOverWeek
        case monthOverMonth
        case weekendWeekday
        case recurringBills

        public var id: String {
            switch self {
            case .last7Days: return "last7Days"
            case .weekOverWeek: return "weekOverWeek"
            case .monthOverMonth: return "monthOverMonth"
            case .weekendWeekday: return "weekendWeekday"
            case .recurringBills: return "recurringBills"
            }
        }
    }

    public init() {}

    public var body: some View {
        #if os(macOS)
        macOSDesktopBody
        #else
        iOSBody
        #endif
    }

    // ── iOS Clean Trends & Comparative Analysis Body ───────────────────────

    #if os(iOS)
    private var iOSBody: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    // 1. Last 7 Days Activity & Interactive Chart
                    last7DaysActivityCard
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                    // 2. Comparison with Previous 7 Days (Week-over-Week)
                    weekOverWeekCard
                        .padding(.horizontal, 16)

                    // 3. Comparison with Past Month (Month-over-Month)
                    monthOverMonthCard
                        .padding(.horizontal, 16)

                    // 4. Weekend vs Weekday Spend Rhythm
                    weekendWeekdayCard
                        .padding(.horizontal, 16)

                    // 5. Recurring Subscriptions & Bills
                    recurringBillsSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 36)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.appGroupedBackground.ignoresSafeArea())
            .navigationTitle("Trends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        PlatformFeedback.impact(.rigid)
                        showNewBillSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .accessibilityLabel("New Subscription")
                }
            }
            .sheet(item: $activeInfoSection) { section in
                trendsInfoSheet(for: section)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showNewBillSheet) {
                BillFormSheet(billToEdit: nil)
                    .environmentObject(store)
            }
            .sheet(item: $editingBill) { bill in
                BillFormSheet(billToEdit: bill)
                    .environmentObject(store)
            }
        }
    }
    #endif

    // ── 1. Last 7 Days Activity & Interactive Chart ───────────────────────

    private struct Daily7Point: Identifiable {
        var id: Int { offset }
        let offset: Int // 0 is today, 6 is 6 days ago
        let dayName: String
        let date: Date
        let amount: Double
        let transactionCount: Int
    }

    private var last7DaysPoints: [Daily7Point] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            let dayName = (offset == 0) ? "Today" : formatter.string(from: date)
            let matchingExpenses = store.expenses.filter {
                $0.isExpense && $0.date >= date && $0.date < nextDate
            }
            let total = matchingExpenses.reduce(0.0) { $0 + $1.amount }
            return Daily7Point(
                offset: offset,
                dayName: dayName,
                date: date,
                amount: total,
                transactionCount: matchingExpenses.count
            )
        }
    }

    private var last7DaysActivityCard: some View {
        let points = last7DaysPoints
        let totalSpend = points.map(\.amount).reduce(0.0, +)
        let dailyAvg = totalSpend / 7.0
        let peakPoint = points.max(by: { $0.amount < $1.amount })
        let txCount = points.map(\.transactionCount).reduce(0, +)

        return VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text("LAST 7 DAYS SPENDING")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(0.6)

                        Button {
                            PlatformFeedback.impact(.light)
                            activeInfoSection = .last7Days
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(store.accentColor.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("₹")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundStyle(store.accentColor)

                        Text(formatCurrency(totalSpend))
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.primary)
                            .contentTransition(.numericText())

                        Text("• ₹\(Int(dailyAvg))/day avg")
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 2)
                    }
                }

                Spacer()

                Button {
                    PlatformFeedback.impact(.light)
                    activeInfoSection = .last7Days
                } label: {
                    ZStack {
                        Circle()
                            .fill(store.accentColor.opacity(0.16))
                            .frame(width: 42, height: 42)
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(store.accentColor)
                    }
                }
                .buttonStyle(.plain)
            }

            // Interactive Day Inspection Pill (if selected)
            if let selectedOffset = selectedDayOffset,
               let pt = points.first(where: { $0.offset == selectedOffset }) {
                HStack(spacing: 8) {
                    Text(pt.dayName)
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(store.accentColor)

                    Text("₹\(formatCurrency(pt.amount))")
                        .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.primary)

                    Spacer()

                    Text("\(pt.transactionCount) \(pt.transactionCount == 1 ? "expense" : "expenses")")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(colorScheme == .dark ? Color(white: 0.16) : Color(white: 0.94))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            // Interactive Swift Chart
            Chart {
                RuleMark(y: .value("7-Day Avg", dailyAvg))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color.secondary.opacity(0.40))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Avg: ₹\(Int(dailyAvg))")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(colorScheme == .dark ? Color(white: 0.14) : Color.white)
                            .clipShape(Capsule())
                    }

                ForEach(points) { pt in
                    BarMark(
                        x: .value("Day", pt.dayName),
                        y: .value("Amount", pt.amount)
                    )
                    .foregroundStyle(
                        selectedDayOffset == pt.offset
                            ? LinearGradient(colors: [store.accentColor, store.accentColor.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                            : (pt.amount >= dailyAvg && dailyAvg > 0
                                ? LinearGradient(colors: [Color.orange, store.accentColor], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [store.accentColor.opacity(0.85), store.accentColor.opacity(0.45)], startPoint: .top, endPoint: .bottom))
                    )
                    .cornerRadius(6)
                }
            }
            .frame(height: 130)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { val in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.secondary.opacity(0.10))
                    AxisValueLabel {
                        if let dVal = val.as(Double.self) {
                            Text("₹\(Int(dVal))")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Divider().opacity(0.3)

            // Highlights Row
            HStack {
                if let peak = peakPoint, peak.amount > 0 {
                    HStack(spacing: 4) {
                        Text("🔥 Peak:")
                            .font(.system(size: 11, weight: .bold))
                        Text("\(peak.dayName) (₹\(formatCurrency(peak.amount)))")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.primary)
                    }
                } else {
                    Text("No transactions logged in last 7 days")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(txCount) \(txCount == 1 ? "transaction" : "transactions") total")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .luxuryCard(glowColor: store.accentColor, glowIntensity: 0.08)
        .contentShape(Rectangle())
        .onTapGesture {
            PlatformFeedback.impact(.light)
            activeInfoSection = .last7Days
        }
    }

    // ── 2. Comparison with Previous 7 Days (Week-over-Week) ────────────────

    private var weekOverWeekCard: some View {
        let current7Spend = store.last7DaysSpend
        let previous7Spend = store.previous7DaysSpend
        let diff = current7Spend - previous7Spend
        let percentChange = previous7Spend > 0 ? ((diff) / previous7Spend) * 100 : 0.0
        let isImproved = diff <= 0 // Lower spending is savings

        return VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text("7-DAY COMPARISON (WEEK-OVER-WEEK)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(0.6)

                        Button {
                            PlatformFeedback.impact(.light)
                            activeInfoSection = .weekOverWeek
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(store.accentColor.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: isImproved ? "arrow.down.right.circle.fill" : "arrow.up.right.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(isImproved ? Color.green : Color.orange)

                        Text(
                            previous7Spend > 0
                                ? "\(String(format: "%.1f", abs(percentChange)))% \(isImproved ? "decrease" : "increase") vs prior 7 days"
                                : (current7Spend > 0 ? "First tracked 7-day period" : "No spend recorded")
                        )
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(isImproved ? Color.green : Color.orange)
                    }
                }

                Spacer()

                Button {
                    PlatformFeedback.impact(.light)
                    activeInfoSection = .weekOverWeek
                } label: {
                    ZStack {
                        Circle()
                            .fill((isImproved ? Color.green : Color.orange).opacity(0.16))
                            .frame(width: 40, height: 40)
                        Image(systemName: isImproved ? "arrow.down.right" : "arrow.up.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isImproved ? Color.green : Color.orange)
                    }
                }
                .buttonStyle(.plain)
            }

            // Side-by-Side Metric Comparison Deck
            HStack(spacing: 12) {
                comparativeMetricPill(
                    title: "THIS 7 DAYS",
                    amount: current7Spend,
                    subtitle: "Last 7 days total",
                    accent: store.accentColor
                )

                comparativeMetricPill(
                    title: "PRIOR 7 DAYS",
                    amount: previous7Spend,
                    subtitle: "Preceding 7 days",
                    accent: Color.secondary
                )

                comparativeMetricPill(
                    title: "DELTA",
                    amount: abs(diff),
                    subtitle: isImproved ? "saved" : "more",
                    prefix: isImproved ? "-₹" : "+₹",
                    accent: isImproved ? Color.green : Color.orange
                )
            }

            // Comparative Visual Dual Bars
            let maxWeekSpend = max(1.0, max(current7Spend, previous7Spend))
            VStack(spacing: 8) {
                comparativeBarRow(
                    label: "This 7 Days",
                    amount: current7Spend,
                    ratio: current7Spend / maxWeekSpend,
                    color: store.accentColor
                )

                comparativeBarRow(
                    label: "Prior 7 Days",
                    amount: previous7Spend,
                    ratio: previous7Spend / maxWeekSpend,
                    color: Color.secondary.opacity(0.7)
                )
            }

            // Plain-English Takeaway
            Text(
                isImproved
                    ? "✨ You spent ₹\(formatCurrency(abs(diff))) less over the last 7 days than during the previous 7 days."
                    : "⚠️ Spending is up by ₹\(formatCurrency(abs(diff))) compared to the previous 7-day period."
            )
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.top, 2)
        }
        .padding(18)
        .luxuryCard(glowColor: isImproved ? Color.green : Color.orange, glowIntensity: 0.08)
        .contentShape(Rectangle())
        .onTapGesture {
            PlatformFeedback.impact(.light)
            activeInfoSection = .weekOverWeek
        }
    }

    // ── 3. Comparison with Past Month (Month-over-Month) ───────────────────

    private var monthOverMonthCard: some View {
        let currentMonthPaced = store.currentPeriodTotal
        let previousMonthPaced = store.previousPeriodPacedSpend
        let previousMonthTotal = store.previousPeriodTotal
        let daysElapsed = store.daysElapsedInCycle
        let pacedDiff = currentMonthPaced - previousMonthPaced
        let percentChange = previousMonthPaced > 0 ? ((pacedDiff) / previousMonthPaced) * 100 : 0.0
        let isPacingLower = pacedDiff <= 0

        return VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text("MONTH-OVER-MONTH PACING")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(0.6)

                        Button {
                            PlatformFeedback.impact(.light)
                            activeInfoSection = .monthOverMonth
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(store.accentColor.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: isPacingLower ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(isPacingLower ? Color.green : Color.orange)

                        Text(
                            previousMonthPaced > 0
                                ? "\(String(format: "%.1f", abs(percentChange)))% \(isPacingLower ? "below" : "above") last month pace"
                                : "Current Cycle vs Previous Cycle"
                        )
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(isPacingLower ? Color.green : Color.orange)
                    }
                }

                Spacer()

                Button {
                    PlatformFeedback.impact(.light)
                    activeInfoSection = .monthOverMonth
                } label: {
                    ZStack {
                        Circle()
                            .fill((isPacingLower ? Color.green : Color.orange).opacity(0.16))
                            .frame(width: 40, height: 40)
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isPacingLower ? Color.green : Color.orange)
                    }
                }
                .buttonStyle(.plain)
            }

            // Paced Apples-to-Apples Strip
            HStack(spacing: 12) {
                comparativeMetricPill(
                    title: "THIS MONTH (DAY \(daysElapsed))",
                    amount: currentMonthPaced,
                    subtitle: "\(daysElapsed) days elapsed",
                    accent: store.accentColor
                )

                comparativeMetricPill(
                    title: "LAST MONTH (DAY \(daysElapsed))",
                    amount: previousMonthPaced,
                    subtitle: "Same elapsed days",
                    accent: Color.secondary
                )

                comparativeMetricPill(
                    title: "PACED DELTA",
                    amount: abs(pacedDiff),
                    subtitle: isPacingLower ? "less spent" : "more spent",
                    prefix: isPacingLower ? "-₹" : "+₹",
                    accent: isPacingLower ? Color.green : Color.orange
                )
            }

            // Month Comparison Bar Gauges
            let maxMonthSpend = max(1.0, max(currentMonthPaced, max(previousMonthPaced, previousMonthTotal)))
            VStack(spacing: 8) {
                comparativeBarRow(
                    label: "This Month (Paced)",
                    amount: currentMonthPaced,
                    ratio: currentMonthPaced / maxMonthSpend,
                    color: isPacingLower ? Color.green : store.accentColor
                )

                comparativeBarRow(
                    label: "Last Month (Day \(daysElapsed))",
                    amount: previousMonthPaced,
                    ratio: previousMonthPaced / maxMonthSpend,
                    color: Color.secondary.opacity(0.7)
                )

                if previousMonthTotal > 0 {
                    comparativeBarRow(
                        label: "Last Month (Full Total)",
                        amount: previousMonthTotal,
                        ratio: previousMonthTotal / maxMonthSpend,
                        color: Color.secondary.opacity(0.4)
                    )
                }
            }

            // Plain-English Takeaway
            Text(
                isPacingLower
                    ? "✨ At Day \(daysElapsed) of your billing cycle, you are spending ₹\(formatCurrency(abs(pacedDiff))) less than at this exact point last month."
                    : "⚠️ At Day \(daysElapsed) of your cycle, you have spent ₹\(formatCurrency(abs(pacedDiff))) more than at this point last month."
            )
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.top, 2)
        }
        .padding(18)
        .luxuryCard(glowColor: isPacingLower ? Color.green : Color.orange, glowIntensity: 0.08)
        .contentShape(Rectangle())
        .onTapGesture {
            PlatformFeedback.impact(.light)
            activeInfoSection = .monthOverMonth
        }
    }

    // ── 4. Weekend vs Weekday Spend Rhythm (Exciting Lifestyle Insight) ─────

    private var weekendWeekdayData: (weekendDaily: Double, weekdayDaily: Double, weekendTotal: Double, weekdayTotal: Double, ratio: Double) {
        let calendar = Calendar.current
        let expenses = store.currentPeriodExpenses
        var weekendTotal = 0.0
        var weekdayTotal = 0.0
        var weekendDays = Set<Int>()
        var weekdayDays = Set<Int>()

        let start = store.cycleStartDate
        let daysElapsed = store.daysElapsedInCycle

        for d in 0..<daysElapsed {
            if let date = calendar.date(byAdding: .day, value: d, to: start) {
                let weekday = calendar.component(.weekday, from: date)
                let dayNumber = calendar.component(.day, from: date)
                if weekday == 1 || weekday == 7 { // Sun or Sat
                    weekendDays.insert(dayNumber)
                } else {
                    weekdayDays.insert(dayNumber)
                }
            }
        }

        for exp in expenses {
            let weekday = calendar.component(.weekday, from: exp.date)
            if weekday == 1 || weekday == 7 {
                weekendTotal += exp.amount
            } else {
                weekdayTotal += exp.amount
            }
        }

        let wDays = max(1, weekendDays.count)
        let wdDays = max(1, weekdayDays.count)
        let wAvg = weekendTotal / Double(wDays)
        let wdAvg = weekdayTotal / Double(wdDays)
        let ratio = wdAvg > 0 ? (wAvg / wdAvg) : 1.0

        return (weekendDaily: wAvg, weekdayDaily: wdAvg, weekendTotal: weekendTotal, weekdayTotal: weekdayTotal, ratio: ratio)
    }

    private var weekendWeekdayCard: some View {
        let data = weekendWeekdayData
        let isWeekendHigher = data.weekendDaily >= data.weekdayDaily

        return VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text("WEEKEND VS WEEKDAY SPEND RHYTHM")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(0.6)

                        Button {
                            PlatformFeedback.impact(.light)
                            activeInfoSection = .weekendWeekday
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(store.accentColor.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 6) {
                        Text(
                            data.weekdayDaily > 0
                                ? (isWeekendHigher
                                    ? "\(String(format: "%.1f", data.ratio))x higher burn on weekends"
                                    : "\(String(format: "%.1f", 1.0 / data.ratio))x higher burn on weekdays")
                                : "Analyzing spending rhythm"
                        )
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                    }
                }

                Spacer()

                Button {
                    PlatformFeedback.impact(.light)
                    activeInfoSection = .weekendWeekday
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.16))
                            .frame(width: 40, height: 40)
                        Image(systemName: "sun.and.horizon.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.purple)
                    }
                }
                .buttonStyle(.plain)
            }

            // Side-by-Side Metric Strip
            HStack(spacing: 12) {
                comparativeMetricPill(
                    title: "WEEKEND (SAT–SUN)",
                    amount: data.weekendDaily,
                    subtitle: "₹\(formatCurrency(data.weekendTotal)) total",
                    prefix: "₹",
                    accent: Color.purple
                )

                comparativeMetricPill(
                    title: "WEEKDAY (MON–FRI)",
                    amount: data.weekdayDaily,
                    subtitle: "₹\(formatCurrency(data.weekdayTotal)) total",
                    prefix: "₹",
                    accent: store.accentColor
                )
            }

            // Comparative Progress Bars
            let maxDaily = max(1.0, max(data.weekendDaily, data.weekdayDaily))
            VStack(spacing: 8) {
                comparativeBarRow(
                    label: "Weekend Daily Average",
                    amount: data.weekendDaily,
                    ratio: data.weekendDaily / maxDaily,
                    color: Color.purple
                )

                comparativeBarRow(
                    label: "Weekday Daily Average",
                    amount: data.weekdayDaily,
                    ratio: data.weekdayDaily / maxDaily,
                    color: store.accentColor
                )
            }

            // Plain-English Takeaway
            Text(
                isWeekendHigher
                    ? "🏖️ You spend an average of ₹\(Int(data.weekendDaily))/day on weekends vs ₹\(Int(data.weekdayDaily))/day on weekdays."
                    : "💼 Your weekday spending pace is higher than weekends."
            )
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.top, 2)
        }
        .padding(18)
        .luxuryCard(glowColor: Color.purple, glowIntensity: 0.08)
        .contentShape(Rectangle())
        .onTapGesture {
            PlatformFeedback.impact(.light)
            activeInfoSection = .weekendWeekday
        }
    }

    // ── Helper Views for Comparison Cards ─────────────────────────────────

    private func comparativeMetricPill(
        title: String,
        amount: Double,
        subtitle: String,
        prefix: String = "₹",
        accent: Color = .primary
    ) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .tracking(0.5)
                .lineLimit(1)

            Text("\(prefix)\(formatCurrency(amount))")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(accent)
                .contentTransition(.numericText())
                .lineLimit(1)

            Text(subtitle)
                .font(.system(size: 9.5))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func comparativeBarRow(label: String, amount: Double, ratio: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("₹\(formatCurrency(amount))")
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                        .frame(height: 6)

                    Capsule()
                        .fill(color)
                        .frame(width: max(6, geo.size.width * CGFloat(min(1.0, max(0.0, ratio)))), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    // ── 5. Recurring Subscriptions & Bills Section ─────────────────────────

    private var recurringBillsSection: some View {
        let bills = store.recurringBills
        let totalCommitted = bills.reduce(0.0) { $0 + $1.amount }
        let totalPaid = bills.filter { $0.isPaid }.reduce(0.0) { $0 + $1.amount }
        let remaining = max(0, totalCommitted - totalPaid)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text("RECURRING SUBSCRIPTIONS & BILLS")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(0.6)

                        Button {
                            PlatformFeedback.impact(.light)
                            activeInfoSection = .recurringBills
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(store.accentColor.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("₹\(formatCurrency(remaining)) remaining to pay (₹\(formatCurrency(totalCommitted)) total)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    PlatformFeedback.impact(.light)
                    showNewBillSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(store.accentColor)
                }
                .buttonStyle(.plain)
            }

            if bills.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 28))
                        .foregroundStyle(store.accentColor.opacity(0.6))
                    Text("No recurring subscriptions yet")
                        .font(.system(size: 13, weight: .medium))
                    Text("Add rent, Netflix, Spotify, or gym commitments.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 8) {
                    ForEach(bills) { bill in
                        recurringBillRow(bill)
                    }
                }
            }
        }
        .padding(18)
        .luxuryCard(glowColor: store.accentColor, glowIntensity: 0.08)
    }

    private func recurringBillRow(_ bill: RecurringBill) -> some View {
        HStack(spacing: 12) {
            // Checkmark button
            Button {
                PlatformFeedback.selection()
                store.toggleBillPaid(id: bill.id)
            } label: {
                ZStack {
                    Circle()
                        .fill(bill.isPaid ? Color.green : Color.secondary.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: bill.isPaid ? "checkmark" : "circle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(bill.isPaid ? Color.white : .secondary)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(bill.title)
                    .font(.system(size: 14, weight: .semibold))
                    .strikethrough(bill.isPaid, color: .secondary)
                    .foregroundStyle(bill.isPaid ? .secondary : Color.primary)

                Text("Due day \(bill.dueDay) • \(bill.category.displayName)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("₹\(formatCurrency(bill.amount))")
                .font(.system(size: 14.5, weight: .bold, design: .rounded))
                .foregroundStyle(bill.isPaid ? .secondary : Color.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            PlatformFeedback.selection()
            editingBill = bill
        }
    }

    // ── Interactive Info Sheets for Trends ─────────────────────────────────

    @ViewBuilder
    private func trendsInfoSheet(for section: TrendsInfoSection) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch section {
                    case .last7Days:
                        last7DaysInfoContent
                    case .weekOverWeek:
                        weekOverWeekInfoContent
                    case .monthOverMonth:
                        monthOverMonthInfoContent
                    case .weekendWeekday:
                        weekendWeekdayInfoContent
                    case .recurringBills:
                        recurringBillsInfoContent
                    }
                }
                .padding(20)
            }
            .background(Color.appGroupedBackground.ignoresSafeArea())
            .navigationTitle("Trend Explanation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        activeInfoSection = nil
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(store.accentColor)
                }
            }
        }
    }

    private var last7DaysInfoContent: some View {
        let totalSpend = store.last7DaysSpend
        let dailyAvg = totalSpend / 7.0

        return VStack(alignment: .leading, spacing: 16) {
            infoSectionHeader(
                title: "Last 7 Days Spending",
                subtitle: "Rolling 7-day transaction velocity",
                icon: "chart.bar.xaxis",
                accent: store.accentColor
            )

            infoFormulaBox(
                title: "Formula & Mechanics",
                formula: "7-Day Total = Sum(Expenses from Day D-6 to Today)\nDaily Average = 7-Day Total ÷ 7",
                explanation: "Tracks short-term spending momentum over the most recent 7-day rolling window, smoothing out single-day anomalies."
            )

            infoLiveMathBox(
                title: "Live Calculation",
                lines: [
                    ("Total Spend (Last 7 Days):", "₹\(formatCurrency(totalSpend))"),
                    ("Rolling Daily Average:", "₹\(Int(dailyAvg))/day"),
                    ("Benchmark Baseline:", "Bars above ₹\(Int(dailyAvg)) appear highlighted in amber.")
                ]
            )

            infoTakeawayBox(
                icon: "sparkles",
                title: "Financial Takeaway",
                text: "Monitoring your 7-day average lets you catch overspending spikes early before they impact your full monthly envelope cushion."
            )
        }
    }

    private var weekOverWeekInfoContent: some View {
        let current = store.last7DaysSpend
        let prior = store.previous7DaysSpend
        let diff = current - prior
        let pct = prior > 0 ? (diff / prior) * 100 : 0.0
        let isImproved = diff <= 0

        return VStack(alignment: .leading, spacing: 16) {
            infoSectionHeader(
                title: "Week-over-Week Comparison",
                subtitle: "Rolling 7 days vs Preceding 7 days",
                icon: isImproved ? "arrow.down.right.circle.fill" : "arrow.up.right.circle.fill",
                accent: isImproved ? Color.green : Color.orange
            )

            infoFormulaBox(
                title: "Formula & Mechanics",
                formula: "Delta = This 7 Days - Prior 7 Days\n% Change = (Delta ÷ Prior 7 Days) × 100",
                explanation: "Compares current 7-day outflow (Days D-6..D0) directly with the preceding 7 days (Days D-13..D-7). Green signifies reduction/savings."
            )

            infoLiveMathBox(
                title: "Live Calculation",
                lines: [
                    ("This 7 Days Total:", "₹\(formatCurrency(current))"),
                    ("Prior 7 Days Total:", "₹\(formatCurrency(prior))"),
                    ("Net Delta:", "\(isImproved ? "-₹" : "+₹")\(formatCurrency(abs(diff))) (\(String(format: "%.1f", abs(pct)))%)")
                ]
            )

            infoTakeawayBox(
                icon: isImproved ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                title: isImproved ? "Saving Momentum" : "Spending Acceleration",
                text: isImproved
                    ? "You reduced spending by ₹\(formatCurrency(abs(diff))) compared to last week. Keep this rate to expand your monthly savings buffer."
                    : "Spending rose by ₹\(formatCurrency(abs(diff))) compared to the prior week. Check high-outflow days to rebalance."
            )
        }
    }

    private var monthOverMonthInfoContent: some View {
        let current = store.currentPeriodTotal
        let priorPaced = store.previousPeriodPacedSpend
        let priorTotal = store.previousPeriodTotal
        let days = store.daysElapsedInCycle
        let diff = current - priorPaced
        let isImproved = diff <= 0

        return VStack(alignment: .leading, spacing: 16) {
            infoSectionHeader(
                title: "Month-over-Month Pacing",
                subtitle: "Apples-to-apples elapsed day comparison",
                icon: "calendar.badge.clock",
                accent: isImproved ? Color.green : Color.orange
            )

            infoFormulaBox(
                title: "Paced Comparison Engine",
                formula: "Paced Spend (Day \(days)) = Spend in current cycle (Days 1–\(days))\nvs Spend in prior cycle (Days 1–\(days))",
                explanation: "Avoids misleading comparisons between a partial month (e.g. Day \(days)) and a complete past month by comparing exact elapsed days."
            )

            infoLiveMathBox(
                title: "Live Calculation",
                lines: [
                    ("This Month (Day \(days)):", "₹\(formatCurrency(current))"),
                    ("Last Month (Day \(days)):", "₹\(formatCurrency(priorPaced))"),
                    ("Paced Difference:", "\(isImproved ? "-₹" : "+₹")\(formatCurrency(abs(diff))) \(isImproved ? "below" : "above") last month"),
                    ("Last Month Full Cycle:", "₹\(formatCurrency(priorTotal))")
                ]
            )

            infoTakeawayBox(
                icon: "sparkles",
                title: "Pacing Takeaway",
                text: isImproved
                    ? "At Day \(days) of your cycle, you have spent ₹\(formatCurrency(abs(diff))) less than you did at this exact same point last month."
                    : "At Day \(days) of your cycle, you have spent ₹\(formatCurrency(abs(diff))) more than at this same point last month."
            )
        }
    }

    private var weekendWeekdayInfoContent: some View {
        let data = weekendWeekdayData

        return VStack(alignment: .leading, spacing: 16) {
            infoSectionHeader(
                title: "Weekend vs Weekday Rhythm",
                subtitle: "Lifestyle outflow distribution",
                icon: "sun.and.horizon.fill",
                accent: Color.purple
            )

            infoFormulaBox(
                title: "Formula & Mechanics",
                formula: "Weekend Daily = Total Weekend Spend ÷ Weekend Days\nWeekday Daily = Total Weekday Spend ÷ Weekday Days",
                explanation: "Breaks down your average daily burn rate between Saturdays/Sundays and regular weekdays to reveal leisure spending patterns."
            )

            infoLiveMathBox(
                title: "Live Calculation",
                lines: [
                    ("Weekend Average (Sat–Sun):", "₹\(Int(data.weekendDaily))/day (₹\(formatCurrency(data.weekendTotal)) total)"),
                    ("Weekday Average (Mon–Fri):", "₹\(Int(data.weekdayDaily))/day (₹\(formatCurrency(data.weekdayTotal)) total)"),
                    ("Rhythm Factor:", "\(String(format: "%.1f", data.ratio))x burn rate on weekends")
                ]
            )

            infoTakeawayBox(
                icon: "lightbulb.fill",
                title: "Lifestyle Optimization",
                text: "Understanding your weekend velocity helps you budget specifically for dining, social outings, and leisure without catching you off-guard."
            )
        }
    }

    private var recurringBillsInfoContent: some View {
        let bills = store.recurringBills
        let total = bills.reduce(0.0) { $0 + $1.amount }
        let paid = bills.filter { $0.isPaid }.reduce(0.0) { $0 + $1.amount }
        let remaining = max(0, total - paid)

        return VStack(alignment: .leading, spacing: 16) {
            infoSectionHeader(
                title: "Recurring Subscriptions & Bills",
                subtitle: "Committed fixed monthly costs",
                icon: "calendar.badge.plus",
                accent: store.accentColor
            )

            infoFormulaBox(
                title: "Formula & Mechanics",
                formula: "Total Committed = Sum(All Active Subscriptions & Bills)\nUnpaid Balance = Total Committed - Paid Commitments",
                explanation: "Fixed obligations (rent, subscriptions, utilities) are ring-fenced to ensure cash flow availability before discretionary spending."
            )

            infoLiveMathBox(
                title: "Live Calculation",
                lines: [
                    ("Total Committed Bills:", "₹\(formatCurrency(total)) (\(bills.count) items)"),
                    ("Paid this Cycle:", "₹\(formatCurrency(paid))"),
                    ("Remaining to Pay:", "₹\(formatCurrency(remaining))")
                ]
            )

            infoTakeawayBox(
                icon: "shield.fill",
                title: "Cash Flow Protection",
                text: "Ticking off subscriptions as you pay them helps you track exact remaining fixed obligations for the rest of your monthly cycle."
            )
        }
    }

    // ── Shared Info Sheet UI Building Blocks ───────────────────────────────

    private func infoSectionHeader(title: String, subtitle: String, icon: String, accent: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func infoFormulaBox(title: String, formula: String, explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(store.accentColor)
                .tracking(0.5)

            Text(formula)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.primary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(explanation)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .luxuryCard()
    }

    private func infoLiveMathBox(title: String, lines: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(store.accentColor)
                .tracking(0.5)

            VStack(spacing: 6) {
                ForEach(lines, id: \.0) { label, val in
                    HStack {
                        Text(label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(val)
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                    }
                }
            }
        }
        .padding(14)
        .luxuryCard()
    }

    private func infoTakeawayBox(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(store.accentColor)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                Text(text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(store.accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    // ── macOS Desktop Body ────────────────────────────────────────────────

    #if os(macOS)
    private var macOSDesktopBody: some View {
        ScrollView {
            VStack(spacing: 20) {
                last7DaysActivityCard
                weekOverWeekCard
                monthOverMonthCard
                weekendWeekdayCard
                recurringBillsSection
            }
            .padding(24)
        }
    }
    #endif
}

// ── Recurring Bill Form Sheet (Edit / Create) ────────────────────────────────

public struct BillFormSheet: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) var dismiss
    var billToEdit: RecurringBill?

    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var dueDay: Int = 1
    @State private var category: ExpenseCategory = .utilities

    public init(billToEdit: RecurringBill? = nil) {
        self.billToEdit = billToEdit
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Subscription Details") {
                    TextField("Subscription Name (e.g. Netflix, Rent)", text: $title)
                    TextField("Amount (₹)", text: $amount)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }

                Section("Schedule & Category") {
                    Picker("Due Day of Month", selection: $dueDay) {
                        ForEach(1...28, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }

                    Picker("Category", selection: $category) {
                        ForEach(store.allCategories, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                }

                if billToEdit != nil {
                    Section {
                        Button("Delete Subscription", role: .destructive) {
                            if let id = billToEdit?.id {
                                PlatformFeedback.warning()
                                store.deleteRecurringBill(id: id)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle(billToEdit == nil ? "New Subscription" : "Edit Subscription")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBill()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || (Double(amount) ?? 0) <= 0)
                }
            }
            .onAppear {
                if let b = billToEdit {
                    title = b.title
                    amount = "\(Int(b.amount))"
                    dueDay = b.dueDay
                    category = b.category
                }
            }
        }
    }

    private func saveBill() {
        guard let amt = Double(amount), amt > 0 else { return }

        if let existing = billToEdit {
            var updated = existing
            updated.title = title
            updated.amount = amt
            updated.category = category
            updated.dueDay = dueDay
            store.updateRecurringBill(updated)
        } else {
            let newBill = RecurringBill(
                title: title,
                amount: amt,
                category: category,
                dueDay: dueDay
            )
            store.addRecurringBill(newBill)
        }
        PlatformFeedback.success()
        dismiss()
    }
}
