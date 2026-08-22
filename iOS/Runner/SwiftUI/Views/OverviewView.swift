import Charts
import SwiftUI

public struct TrajectoryPoint: Identifiable {
    public var id: Int { index }
    public let index: Int
    public let label: String
    public let ideal: Double
    public let actual: Double?
    public let projected: Double?

    public init(index: Int, label: String, ideal: Double, actual: Double?, projected: Double?) {
        self.index = index
        self.label = label
        self.ideal = ideal
        self.actual = actual
        self.projected = projected
    }
}

public struct OverviewView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var searchQuery: String = ""
    @State private var isSearchActive: Bool = false
    @State private var editingExpense: Expense? = nil
    @State private var selectedHeroTab: Int = 0 // 0: Envelope, 1: Net Worth
    @State private var selectedIndex: Int? = nil
    @State private var showTrajectoryInfo: Bool = false
    @State private var showEnvelopeInfo: Bool = false
    public enum PulseMetric: String, Identifiable {
        case dailyBurn = "Daily Burn Rate"
        case projected = "Projected Month-End"
        case runway = "Runway (Safe Allowance)"

        public var id: String { rawValue }
    }

    @State private var selectedPulseMetric: PulseMetric? = nil
    @Binding var showQuickAdd: Bool
    @Environment(\.colorScheme) var colorScheme

    public init(showQuickAdd: Binding<Bool>? = nil) {
        self._showQuickAdd = showQuickAdd ?? .constant(false)
    }

    public var body: some View {
        #if os(macOS)
        macOSDesktopBody
        #else
        iOSBody
        #endif
    }

    // ── iOS Clean Apple Wallet & Fitness Body ─────────────────────────────

    #if os(iOS)
    private var iOSBody: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Hero Spend Ring / Net Worth Card
                    if selectedHeroTab == 0 {
                        heroSpendRingCard
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                    } else {
                        heroNetWorthCard
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                    }

                    // 3-Card Glanceable Financial Pulse Deck
                    financialPulseDeck
                        .padding(.horizontal, 16)

                    // Spend Trajectory & Pacing
                    trajectorySparklineCard
                        .padding(.horizontal, 16)

                    // Horizontal Category Filter Rail
                    filterChipsBar
                        .padding(.top, 2)

                    // Transaction Feed Section
                    transactionFeedList
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.appGroupedBackground.ignoresSafeArea())
            .navigationTitle("Well Spent")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        PlatformFeedback.selection()
                        withAnimation(.appleSpring) {
                            selectedHeroTab = (selectedHeroTab == 0) ? 1 : 0
                        }
                    } label: {
                        Image(systemName: selectedHeroTab == 0 ? "banknote" : "gauge.with.needle")
                            .symbolEffect(.bounce, value: selectedHeroTab)
                    }
                    .accessibilityLabel(selectedHeroTab == 0 ? "Show Net Worth" : "Show Envelope")
                }

                // Trailing search button opening Apple Spotlight search sheet
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        PlatformFeedback.impact(.light)
                        isSearchActive = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .accessibilityLabel("Search Transactions")
                }
            }
            .sheet(isPresented: $isSearchActive) {
                SpotlightSearchView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showEnvelopeInfo) {
                envelopeInfoSheet
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedPulseMetric) { metric in
                singleMetricInfoSheet(for: metric)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingExpense) { expense in
                QuickAddView(expenseToEdit: expense)
                    .environmentObject(store)
            }
        }
    }
    #endif

    // ── Hero Spend Ring Card (Apple Fitness / Wallet Style) ────────────────

    private var heroSpendRingCard: some View {
        let budget = store.monthlyBudget
        let spent = store.currentPeriodTotal
        let usage = budget > 0 ? min(1.5, spent / budget) : 0.0
        let remaining = max(0, budget - spent)
        let isOver = spent > budget && budget > 0

        return VStack(spacing: 16) {
            HStack(spacing: 18) {
                // Left: Hero Circular Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 11)
                        .frame(width: 96, height: 96)

                    if usage > 0 {
                        Circle()
                            .trim(from: 0, to: CGFloat(min(1.0, usage)))
                            .stroke(
                                isOver ? Color.red : store.accentColor,
                                style: StrokeStyle(lineWidth: 11, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 96, height: 96)
                            .shadow(color: (isOver ? Color.red : store.accentColor).opacity(0.4), radius: 6, x: 0, y: 0)
                            .animation(.appleSpring, value: usage)
                    }

                    VStack(spacing: 1) {
                        Text("\(Int(usage * 100))%")
                            .font(.system(size: 19, weight: .heavy, design: .rounded))
                            .foregroundStyle(isOver ? Color.red : Color.primary)
                            .contentTransition(.numericText())

                        Text(isOver ? "OVER" : "USED")
                            .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(isOver ? Color.red : .secondary)
                            .tracking(0.5)
                    }
                }

                // Right: Hero Remaining Balance & Status
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("REMAINING ENVELOPE")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(0.6)

                        Spacer()

                        Button {
                            PlatformFeedback.impact(.light)
                            showEnvelopeInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("How Envelope Works")
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("₹")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(isOver ? Color.red : store.accentColor)

                        Text(formatCurrency(remaining))
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(isOver ? Color.red : Color.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .contentTransition(.numericText())

                        Image(systemName: isOver ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(isOver ? Color.red : Color.green)
                            .padding(.leading, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Bottom Mini Metrics Strip
            HStack {
                miniHeaderMetric(title: "SPENT", value: "₹\(formatCurrency(spent))", color: isOver ? .red : .primary)
                Spacer()
                Divider().frame(height: 20).opacity(0.3)
                Spacer()
                miniHeaderMetric(title: "BUDGET", value: "₹\(formatCurrency(budget))", color: .primary)
                Spacer()
                Divider().frame(height: 20).opacity(0.3)
                Spacer()
                miniHeaderMetric(title: "DAYS LEFT", value: "\(store.daysRemainingInCycle) Days", color: isOver ? .red : .primary)
            }
            .padding(.top, 4)
        }
        .padding(18)
        .luxuryCard(glowColor: isOver ? Color.red : store.accentColor, glowIntensity: isOver ? 0.18 : 0.12)
    }

    private func miniHeaderMetric(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
    }

    // ── Hero Net Worth Card ───────────────────────────────────────────────

    private var heroNetWorthCard: some View {
        let netWorth = store.netWorth
        let isPositive = netWorth.total >= 0

        return VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL NET WORTH")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .tracking(0.6)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("₹")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(isPositive ? Color.green : Color.red)
                        Text(formatCurrency(netWorth.total))
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(isPositive ? Color.green : Color.red)
                            .contentTransition(.numericText())
                    }
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill((isPositive ? Color.green : Color.red).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isPositive ? Color.green : Color.red)
                }
            }

            Divider().opacity(0.3)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TOTAL ASSETS")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("₹\(formatCurrency(netWorth.assets))")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                        .contentTransition(.numericText())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("TOTAL LIABILITIES")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("₹\(formatCurrency(netWorth.liabilities))")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.red)
                        .contentTransition(.numericText())
                }
            }
        }
        .padding(18)
        .luxuryCard(glowColor: isPositive ? Color.green : Color.red, glowIntensity: 0.12)
    }

    // ── 3-Card Glanceable Financial Pulse Deck ─────────────────────────────

    private var financialPulseDeck: some View {
        HStack(spacing: 10) {
            // Card 1: Daily Burn Rate
            financialTile(
                title: "DAILY BURN",
                value: "₹\(Int(store.dailySpendAverage))",
                subtext: "avg/day",
                icon: "flame.fill",
                accent: .orange
            ) {
                selectedPulseMetric = .dailyBurn
            }

            // Card 2: Projected Month-End
            let isOver = store.projectedMonthEnd > store.monthlyBudget && store.monthlyBudget > 0
            financialTile(
                title: "PROJECTED",
                value: "₹\(formatCompactCurrency(store.projectedMonthEnd))",
                subtext: isOver ? "over cap" : "on target",
                icon: "safari.fill",
                accent: isOver ? .red : .blue
            ) {
                selectedPulseMetric = .projected
            }

            // Card 3: Days Left / Runway
            financialTile(
                title: "RUNWAY",
                value: "₹\(Int(store.dailyBudget))",
                subtext: "\(store.daysRemainingInCycle) days left",
                icon: "calendar.badge.clock",
                accent: .green
            ) {
                selectedPulseMetric = .runway
            }
        }
    }

    private func financialTile(title: String, value: String, subtext: String, icon: String, accent: Color, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accent)
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(value)
                .font(.system(size: 15.5, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.primary)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(subtext)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .luxuryCard(cornerRadius: 16, glowColor: accent, glowIntensity: 0.08)
        .contentShape(Rectangle())
        .onTapGesture {
            PlatformFeedback.selection()
            action()
        }
    }

    // ── Apple Stock / Fitness Interactive Spend Trajectory (Crystal Clear) ───────────────

    private var trajectorySparklineCard: some View {
        let budget = store.monthlyBudget
        let projected = store.projectedMonthEnd
        let isOver = projected > budget && budget > 0
        let points = trajectoryPoints
        let maxActual = points.compactMap(\.actual).max() ?? 0
        let maxProj = points.compactMap(\.projected).max() ?? 0
        let highestSpend = max(maxActual, maxProj)
        let domainMax: Double = budget > 0 ? max(budget, highestSpend) : max(100.0, highestSpend)
        let delta = budget - projected

        return VStack(alignment: .leading, spacing: 14) {
            // Header Row with Title, Status Chip, and Info Button
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("SPENDING TRAJECTORY")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(isOver ? Color.red : Color.green)
                            .frame(width: 7, height: 7)

                        Text(isOver ? "Projected Over Budget" : "On Track to Save")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(isOver ? Color.red : Color.primary)

                        Text(isOver ? "(+₹\(formatCompactCurrency(abs(delta))))" : "(-₹\(formatCompactCurrency(delta)) buffer)")
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(isOver ? Color.red : Color.green)
                    }
                }

                Spacer()

                Button {
                    PlatformFeedback.impact(.light)
                    showTrajectoryInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("How Trajectory Works")
            }

            // Plain-English Human Takeaway Banner
            HStack(spacing: 8) {
                Image(systemName: isOver ? "exclamationmark.triangle.fill" : "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isOver ? Color.red : store.accentColor)

                Text(plainEnglishForecast(isOver: isOver, projected: projected, budget: budget, delta: delta))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isOver ? Color.red.opacity(0.10) : store.accentColor.opacity(0.08))
            )

            // Live Values Bar (Scrub Inspection)
            if let selected = selectedIndex, let point = points.first(where: { $0.index == selected }) {
                HStack(spacing: 12) {
                    Text("Day \(selected)")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(store.accentColor)

                    if let actual = point.actual {
                        Text("Spent: ₹\(Int(actual))")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                    } else if let proj = point.projected {
                        Text("Projected: ₹\(Int(proj))")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                    }

                    Spacer()

                    Text("Target Pace: ₹\(Int(point.ideal))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(colorScheme == .dark ? Color(white: 0.16) : Color(white: 0.94))
                )
            }

            // Interactive Swift Chart
            let currentPoint = points.filter { $0.actual != nil }.last
            let finalProjPoint = points.filter { $0.projected != nil }.last

            Chart {
                ForEach(points) { point in
                    // 1. Ideal Baseline (Target Pace)
                    LineMark(
                        x: .value("Interval", point.index),
                        y: .value("Ideal", point.ideal)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                    .foregroundStyle(Color.secondary.opacity(0.35))

                    // 2. Actual Spend Line (Logged so far)
                    if let actual = point.actual {
                        LineMark(
                            x: .value("Interval", point.index),
                            y: .value("Actual", actual)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .foregroundStyle(store.accentColor)
                    }

                    // 3. Projected Run-Rate Line (Future estimate)
                    if let proj = point.projected {
                        LineMark(
                            x: .value("Interval", point.index),
                            y: .value("Projected", proj)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4]))
                        .foregroundStyle(isOver ? Color.red.opacity(0.85) : Color.orange.opacity(0.85))
                    }
                }

                // Default resting in-graph milestone badges
                if selectedIndex == nil {
                    if let cur = currentPoint, let actual = cur.actual {
                        PointMark(x: .value("Current Interval", cur.index), y: .value("Actual", actual))
                            .symbolSize(50)
                            .foregroundStyle(store.accentColor)
                            .annotation(position: .top, alignment: .center, spacing: 4) {
                                HStack(spacing: 3) {
                                    Circle().fill(store.accentColor).frame(width: 4, height: 4)
                                    Text("Spent: ₹\(formatCompactCurrency(actual))")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.primary)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(colorScheme == .dark ? Color(white: 0.18) : Color.white)
                                        .shadow(color: Color.black.opacity(0.18), radius: 3, y: 1)
                                )
                                .overlay(
                                    Capsule().strokeBorder(store.accentColor.opacity(0.4), lineWidth: 0.75)
                                )
                            }
                    }

                    if let lastProj = finalProjPoint, let proj = lastProj.projected {
                        PointMark(x: .value("Projected Interval", lastProj.index), y: .value("Projected", proj))
                            .symbolSize(45)
                            .foregroundStyle(isOver ? Color.red : Color.orange)
                            .annotation(position: .topLeading, alignment: .trailing, spacing: 4) {
                                HStack(spacing: 3) {
                                    RoundedRectangle(cornerRadius: 1).fill(isOver ? Color.red : Color.orange).frame(width: 5, height: 2)
                                    Text("Proj: ₹\(formatCompactCurrency(proj))")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(isOver ? Color.red : Color.orange)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(colorScheme == .dark ? Color(white: 0.18) : Color.white)
                                        .shadow(color: Color.black.opacity(0.18), radius: 3, y: 1)
                                )
                                .overlay(
                                    Capsule().strokeBorder((isOver ? Color.red : Color.orange).opacity(0.4), lineWidth: 0.75)
                                )
                            }
                    }
                }

                // Active touch cursor rule & point
                if let selected = selectedIndex, let point = points.first(where: { $0.index == selected }), let actual = point.actual ?? point.projected {
                    RuleMark(x: .value("Selected Interval", selected))
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .foregroundStyle(store.accentColor.opacity(0.6))

                    PointMark(x: .value("Selected Interval", selected), y: .value("Actual", actual))
                        .symbolSize(45)
                        .foregroundStyle(store.accentColor)
                }

                // Budget cap limit line
                if budget > 0 {
                    RuleMark(y: .value("Budget Limit", budget))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(Color.red.opacity(0.50))
                }
            }
            .chartXSelection(value: $selectedIndex)
            .chartYScale(domain: 0...domainMax)
            .frame(height: 140)
            .chartXAxis {
                AxisMarks(values: [1, 7, 14, 21, 28]) { val in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.secondary.opacity(0.12))
                    AxisTick()
                    AxisValueLabel {
                        if let d = val.as(Int.self) {
                            Text("D\(d)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, domainMax * 0.5, domainMax]) { val in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.secondary.opacity(0.10))
                    AxisValueLabel {
                        if let dVal = val.as(Double.self) {
                            Text(formatCompactCurrency(dVal))
                                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onChange(of: selectedIndex) { _, newIdx in
                if newIdx != nil {
                    PlatformFeedback.impact(.light)
                }
            }

            // Visual Legend Strip (Explaining what each line means)
            HStack(spacing: 12) {
                legendItem(title: "Spent", color: store.accentColor, isDashed: false)
                legendItem(title: "Projected", color: isOver ? .red : .orange, isDashed: true)
                legendItem(title: "Target Pace", color: .secondary.opacity(0.6), isDotted: true)
                if budget > 0 {
                    legendItem(title: "Budget Cap", color: .red.opacity(0.7), isDashed: true)
                }
            }
            .padding(.top, 2)
        }
        .padding(16)
        .luxuryCard(glowColor: isOver ? Color.red : store.accentColor, glowIntensity: 0.08)
        .sheet(isPresented: $showTrajectoryInfo) {
            trajectoryInfoSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private func plainEnglishForecast(isOver: Bool, projected: Double, budget: Double, delta: Double) -> String {
        let dailyAvg = Int(store.dailySpendAverage)
        if isOver {
            return "At your current burn rate of ₹\(dailyAvg)/day, you're on track to spend ₹\(formatCurrency(projected)) (exceeding budget by ₹\(formatCurrency(abs(delta))))."
        } else {
            return "At your current burn rate of ₹\(dailyAvg)/day, you're projected to finish at ₹\(formatCurrency(projected)) with a safe buffer of ₹\(formatCurrency(delta))."
        }
    }

    private func legendItem(title: String, color: Color, isDashed: Bool = false, isDotted: Bool = false) -> some View {
        HStack(spacing: 4) {
            if isDotted {
                Circle().fill(color).frame(width: 4, height: 4)
                Circle().fill(color).frame(width: 4, height: 4)
            } else if isDashed {
                RoundedRectangle(cornerRadius: 1).fill(color).frame(width: 8, height: 2.5)
            } else {
                Circle().fill(color).frame(width: 6.5, height: 6.5)
            }

            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    // ── Trajectory Explanation Sheet ──────────────────────────────────────

    private var trajectoryInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        trajectoryBullet(
                            style: .solid(store.accentColor),
                            title: "Solid Line (Actual Spend)",
                            description: "Tracks your cumulative money spent from Day 1 up to today."
                        )

                        trajectoryBullet(
                            style: .dashed(.orange),
                            title: "Dashed Line (Projected Run-Rate)",
                            description: "Predicts where you will finish the cycle at your current daily burn rate."
                        )

                        trajectoryBullet(
                            style: .dotted(.secondary.opacity(0.8)),
                            title: "Dotted Line (Target Pace)",
                            description: "The ideal steady burn rate that evenly distributes your budget across all days."
                        )

                        trajectoryBullet(
                            style: .dashed(Color.red.opacity(0.8)),
                            title: "Red Dashed Line (Budget Cap)",
                            description: "Your maximum planned spending limit for this cycle."
                        )

                        trajectoryBullet(
                            style: .icon("hand.point.up.left.fill", .blue),
                            title: "Touch & Scrub Inspection",
                            description: "Touch and slide across the graph to inspect exact amounts and pacing on any day."
                        )
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(Color.appGroupedBackground.ignoresSafeArea())
            .navigationTitle("Spending Trajectory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showTrajectoryInfo = false
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(store.accentColor)
                }
            }
        }
    }

    private enum TrajectoryIndicatorStyle {
        case solid(Color)
        case dashed(Color)
        case dotted(Color)
        case icon(String, Color)
    }

    private func trajectoryBullet(style: TrajectoryIndicatorStyle, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(indicatorBgColor(for: style))
                    .frame(width: 34, height: 34)

                switch style {
                case .solid(let color):
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(color)
                        .frame(width: 16, height: 3.5)

                case .dashed(let color):
                    HStack(spacing: 2.5) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color)
                            .frame(width: 6, height: 3)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color)
                            .frame(width: 6, height: 3)
                    }

                case .dotted(let color):
                    HStack(spacing: 2.5) {
                        Circle().fill(color).frame(width: 3.5, height: 3.5)
                        Circle().fill(color).frame(width: 3.5, height: 3.5)
                        Circle().fill(color).frame(width: 3.5, height: 3.5)
                    }

                case .icon(let name, let color):
                    Image(systemName: name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(color)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)

                Text(description)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func indicatorBgColor(for style: TrajectoryIndicatorStyle) -> Color {
        switch style {
        case .solid(let c), .dashed(let c), .dotted(let c), .icon(_, let c):
            return c.opacity(0.14)
        }
    }

    // ── Remaining Envelope Explanation Sheet ─────────────────────────────

    private var envelopeInfoSheet: some View {
        let budget = store.monthlyBudget
        let spent = store.currentPeriodTotal
        let usage = budget > 0 ? (spent / budget) * 100 : 0.0
        let remaining = max(0, budget - spent)
        let daysLeft = store.daysRemainingInCycle
        let safeDaily = store.dailyBudget

        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        infoFormulaCard(
                            title: "TOTAL BUDGET",
                            formula: "Your planned spending ceiling for this cycle",
                            liveCalculation: "₹\(formatCurrency(budget))",
                            color: .blue,
                            icon: "envelope.fill"
                        )

                        infoFormulaCard(
                            title: "TOTAL SPENT",
                            formula: "Sum of all transactions logged in this cycle",
                            liveCalculation: "₹\(formatCurrency(spent)) (\(String(format: "%.1f", usage))% used)",
                            color: store.accentColor,
                            icon: "cart.fill"
                        )

                        infoFormulaCard(
                            title: "REMAINING ENVELOPE",
                            formula: "Total Budget - Total Spend",
                            liveCalculation: "₹\(formatCurrency(budget)) - ₹\(formatCurrency(spent)) = ₹\(formatCurrency(remaining)) left",
                            color: remaining > 0 ? .green : .red,
                            icon: "checkmark.seal.fill"
                        )

                        infoFormulaCard(
                            title: "DAILY RUNWAY",
                            formula: "Remaining Envelope ÷ Days Left",
                            liveCalculation: "₹\(formatCurrency(remaining)) ÷ \(daysLeft) days left = ₹\(formatCurrency(safeDaily))/day",
                            color: .purple,
                            icon: "calendar.badge.clock"
                        )
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(Color.appGroupedBackground.ignoresSafeArea())
            .navigationTitle("Remaining Envelope")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showEnvelopeInfo = false
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(store.accentColor)
                }
            }
        }
    }

    // ── Single Metric Explanation Sheet (Daily Burn / Projected / Runway) ────

    @ViewBuilder
    private func singleMetricInfoSheet(for metric: PulseMetric) -> some View {
        let cycleDays = max(1, store.daysElapsedInCycle)
        let totalSpend = store.currentPeriodTotal
        let dailyBurn = store.dailySpendAverage
        let daysRemaining = store.daysRemainingInCycle
        let projected = store.projectedMonthEnd
        let budget = store.monthlyBudget
        let remainingBudget = max(0, budget - totalSpend)
        let safeDailyAllowance = store.dailyBudget

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    switch metric {
                    case .dailyBurn:
                        Text("Average spending velocity per day in your current cycle.")
                            .font(.system(size: 13.5))
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)

                        infoFormulaCard(
                            title: "HOW IT'S CALCULATED",
                            formula: "Total Period Spend ÷ Days Elapsed",
                            liveCalculation: "₹\(formatCurrency(totalSpend)) spend ÷ \(cycleDays) days elapsed = ₹\(Int(dailyBurn)) / day",
                            color: .orange,
                            icon: "flame.fill"
                        )

                    case .projected:
                        Text("Forecasted total month-end spend if you maintain your current daily burn rate.")
                            .font(.system(size: 13.5))
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)

                        infoFormulaCard(
                            title: "HOW IT'S CALCULATED",
                            formula: "Current Spend + (Daily Burn × Days Remaining)",
                            liveCalculation: "₹\(formatCurrency(totalSpend)) + (₹\(Int(dailyBurn))/d × \(daysRemaining)d) = ₹\(formatCurrency(projected))\n\nTarget Budget: ₹\(formatCurrency(budget)) (\(projected <= budget ? "₹\(formatCurrency(budget - projected)) under cap" : "₹\(formatCurrency(projected - budget)) over cap"))",
                            color: projected <= budget ? .blue : .red,
                            icon: "safari.fill"
                        )

                    case .runway:
                        Text("The maximum amount you can spend per day starting today to stay under budget.")
                            .font(.system(size: 13.5))
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)

                        infoFormulaCard(
                            title: "HOW IT'S CALCULATED",
                            formula: "Remaining Budget ÷ Days Remaining",
                            liveCalculation: "(₹\(formatCurrency(budget)) - ₹\(formatCurrency(totalSpend)) = ₹\(formatCurrency(remainingBudget)) left) ÷ \(daysRemaining) days = ₹\(Int(safeDailyAllowance)) / day",
                            color: .green,
                            icon: "calendar.badge.clock"
                        )
                    }

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(Color.appGroupedBackground.ignoresSafeArea())
            .navigationTitle(metric.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        selectedPulseMetric = nil
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(store.accentColor)
                }
            }
        }
    }

    private func infoFormulaCard(title: String, formula: String, liveCalculation: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Formula:")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(formula)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Color.primary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Live Calculation:")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(liveCalculation)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.08))
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryCard(cornerRadius: 16, glowColor: color, glowIntensity: 0.05)
    }

    // ── Horizontal Filter Chips Bar ───────────────────────────────────────

    private var filterChipsBar: some View {
        let expensesToCount = store.todayExpenses

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All Category Pill
                Button {
                    PlatformFeedback.selection()
                    withAnimation(.appleSpring) {
                        store.selectedCategoryFilter = nil
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text("All")
                        Text("\(expensesToCount.count)")
                            .font(.system(size: 10.5, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(store.selectedCategoryFilter == nil ? store.accentColor : Color.secondary.opacity(0.2))
                            .foregroundStyle(store.selectedCategoryFilter == nil ? Color.white : Color.primary)
                            .clipShape(Capsule())
                    }
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        ZStack {
                            if store.selectedCategoryFilter == nil {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(store.accentColor.opacity(0.18))
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(store.accentColor.opacity(0.5), lineWidth: 1)
                            } else {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.13) : Color.white)
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 0.8)
                            }
                        }
                    )
                    .foregroundStyle(store.selectedCategoryFilter == nil ? store.accentColor : Color.primary)
                }
                .buttonStyle(.plain)

                // Category Specific Pills
                ForEach(store.allCategories, id: \.self) { cat in
                    let count = expensesToCount.filter { $0.category.id == cat.id }.count
                    if count > 0 {
                        Button {
                            PlatformFeedback.selection()
                            withAnimation(.appleSpring) {
                                if store.selectedCategoryFilter?.id == cat.id {
                                    store.selectedCategoryFilter = nil
                                } else {
                                    store.selectedCategoryFilter = cat
                                }
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: cat.sfSymbol)
                                    .font(.system(size: 11))
                                Text(cat.displayName)
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(store.selectedCategoryFilter == cat ? cat.color : Color.secondary.opacity(0.2))
                                    .foregroundStyle(store.selectedCategoryFilter == cat ? Color.white : Color.primary)
                                    .clipShape(Capsule())
                            }
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(
                                ZStack {
                                    if store.selectedCategoryFilter == cat {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(cat.color.opacity(0.18))
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(cat.color.opacity(0.5), lineWidth: 1)
                                    } else {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.13) : Color.white)
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 0.8)
                                    }
                                }
                            )
                            .foregroundStyle(store.selectedCategoryFilter == cat ? cat.color : Color.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // ── Transaction Feed List (Strictly Current Day / Today) ─────────────

    private var transactionFeedList: some View {
        let todayList = todayFilteredExpenses

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("TODAY'S TRANSACTIONS")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                Spacer()
                Text("\(todayList.count) \(todayList.count == 1 ? "entry" : "entries")")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 2)

            if todayList.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary.opacity(0.5))

                    Text("No transactions logged today")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary)

                    Text("Tap the '+' button in the tab bar to add an expense.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .luxuryCard(cornerRadius: 18)
            } else {
                VStack(spacing: 1) {
                    ForEach(todayList) { expense in
                        transactionRow(expense)
                    }
                }
                .luxuryCard(cornerRadius: 18)
            }

            // Search Past History Button
            Button {
                PlatformFeedback.impact(.light)
                isSearchActive = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Search Past Transactions")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(store.accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .luxuryCard(cornerRadius: 14, glowIntensity: 0.04)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    private var todayFilteredExpenses: [Expense] {
        var list = store.todayExpenses
        if let cat = store.selectedCategoryFilter {
            list = list.filter { $0.category == cat }
        }
        return list.sorted { $0.date > $1.date }
    }

    private func transactionRow(_ expense: Expense) -> some View {
        HStack(spacing: 12) {
            // Category Icon Badge
            ZStack {
                Circle()
                    .fill(expense.category.color.opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: expense.category.sfSymbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(expense.category.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(expense.category.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    if !expense.notes.isEmpty {
                        Text("• \(expense.notes)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(expense.isExpense ? "-" : "+")₹\(formatCurrency(expense.amount))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(expense.isExpense ? Color.primary : Color.green)

                Text(formatTime(expense.date))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
        .onTapGesture {
            PlatformFeedback.selection()
            editingExpense = expense
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                PlatformFeedback.warning()
                store.deleteExpense(id: expense.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // ── Trajectory Points Calculation ─────────────────────────────────────

    private var trajectoryPoints: [TrajectoryPoint] {
        calculateMonthwiseDailyTrajectory()
    }

    private func calculateMonthwiseDailyTrajectory() -> [TrajectoryPoint] {
        let budget = store.monthlyBudget
        let totalDays = max(28, store.totalDaysInCycle)
        let currentDay = max(1, min(totalDays, store.daysElapsedInCycle))
        let calendar = Calendar.current
        let cycleStart = store.cycleStartDate
        let periodExpenses = store.currentPeriodExpenses.sorted { $0.date < $1.date }

        var points: [TrajectoryPoint] = []
        points.reserveCapacity(totalDays + 1)
        let currentTotal = store.currentPeriodTotal
        let dailyAverage = currentTotal / Double(currentDay)

        // Origin at Day 0 (0 spend)
        points.append(TrajectoryPoint(
            index: 0,
            label: "D0",
            ideal: 0.0,
            actual: 0.0,
            projected: nil
        ))

        var expenseIndex = 0
        var runningSpend = 0.0

        for d in 1...totalDays {
            let ideal = (budget / Double(totalDays)) * Double(d)
            var actual: Double? = nil
            var projected: Double? = nil

            if d <= currentDay {
                if let targetDate = calendar.date(byAdding: .day, value: d, to: cycleStart) {
                    while expenseIndex < periodExpenses.count && periodExpenses[expenseIndex].date < targetDate {
                        runningSpend += periodExpenses[expenseIndex].amount
                        expenseIndex += 1
                    }
                    actual = runningSpend
                } else {
                    actual = dailyAverage * Double(d)
                }
            }

            if d >= currentDay {
                projected = currentTotal + (dailyAverage * Double(d - currentDay))
            }

            points.append(TrajectoryPoint(
                index: d,
                label: "D\(d)",
                ideal: ideal,
                actual: actual,
                projected: projected
            ))
        }
        return points
    }

    // ── Data & Formatters ─────────────────────────────────────────────────

    private var filteredExpenses: [Expense] {
        var list = store.todayExpenses
        if let cat = store.selectedCategoryFilter {
            list = list.filter { $0.category == cat }
        }
        if !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchQuery.lowercased()
            list = list.filter {
                $0.title.lowercased().contains(query) ||
                $0.notes.lowercased().contains(query) ||
                $0.tags.contains(where: { $0.lowercased().contains(query) })
            }
        }
        return list
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private func formatCompactCurrency(_ value: Double) -> String {
        if value >= 100000 {
            let inLakhs = value / 100000
            if inLakhs.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0fL", inLakhs)
            }
            return String(format: "%.1fL", inLakhs)
        } else if value >= 1000 {
            let inThousands = value / 1000
            if inThousands.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0fk", inThousands)
            }
            return String(format: "%.1fk", inThousands)
        }
        return "\(Int(value))"
    }

    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "TODAY" }
        if calendar.isDateInYesterday(date) { return "YESTERDAY" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date).uppercased()
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    // ── macOS Desktop Body ────────────────────────────────────────────────

    #if os(macOS)
    private var macOSDesktopBody: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroSpendRingCard
                financialPulseDeck
                trajectorySparklineCard
                filterChipsBar
                transactionFeedList
            }
            .padding(24)
        }
    }
    #endif
}

// ── Apple Spotlight Transaction Search Sheet ─────────────────────────────────

public struct SpotlightSearchView: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var searchText: String = ""
    @State private var selectedCategory: ExpenseCategory? = nil
    @State private var selectedAmountFilter: AmountFilter = .all
    @State private var editingExpense: Expense? = nil
    @FocusState private var isSearchFocused: Bool

    public enum AmountFilter: String, CaseIterable {
        case all = "All Amounts"
        case under500 = "< ₹500"
        case under2000 = "₹500 - ₹2k"
        case above2000 = "> ₹2,000"

        func matches(_ amount: Double) -> Bool {
            switch self {
            case .all: return true
            case .under500: return amount < 500
            case .under2000: return amount >= 500 && amount <= 2000
            case .above2000: return amount > 2000
            }
        }
    }

    public init() {}

    private var matchingExpenses: [Expense] {
        var list = store.expenses

        if let cat = selectedCategory {
            list = list.filter { $0.category == cat }
        }

        list = list.filter { selectedAmountFilter.matches($0.amount) }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            list = list.filter {
                $0.title.lowercased().contains(query) ||
                $0.notes.lowercased().contains(query) ||
                $0.category.displayName.lowercased().contains(query) ||
                $0.tags.contains(where: { $0.lowercased().contains(query) }) ||
                String(format: "%.0f", $0.amount).contains(query)
            }
        }

        return list.sorted { $0.date > $1.date }
    }

    private var totalMatchingSpend: Double {
        matchingExpenses.filter(\.isExpense).reduce(0.0) { $0 + $1.amount }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Field Bar
                searchHeaderBar
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 10)

                // Quick Filters
                filterRail
                    .padding(.bottom, 12)

                Divider().opacity(0.2)

                // Results Stream
                resultsStream
            }
            .background(Color.appGroupedBackground.ignoresSafeArea())
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(store.accentColor)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFocused = true
                }
            }
            .sheet(item: $editingExpense) { expense in
                QuickAddView(expenseToEdit: expense)
                    .environmentObject(store)
            }
        }
    }

    private var searchHeaderBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(store.accentColor)

                TextField("Search title, category, notes, amount...", text: $searchText)
                    .font(.system(size: 15, weight: .medium))
                    .focused($isSearchFocused)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(colorScheme == .dark ? Color(white: 0.14) : Color(white: 0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.40), lineWidth: 0.8)
            )
        }
    }

    private var filterRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Button("All Categories") {
                        PlatformFeedback.selection()
                        selectedCategory = nil
                    }
                    Divider()
                    ForEach(store.allCategories, id: \.self) { cat in
                        Button {
                            PlatformFeedback.selection()
                            selectedCategory = cat
                        } label: {
                            Label(cat.displayName, systemImage: cat.sfSymbol)
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: selectedCategory?.sfSymbol ?? "line.3.horizontal.decrease.circle")
                            .font(.system(size: 12))
                        Text(selectedCategory?.displayName ?? "Categories")
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selectedCategory != nil ? store.accentColor.opacity(0.18) : (colorScheme == .dark ? Color(white: 0.14) : Color.white))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(selectedCategory != nil ? store.accentColor.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: 0.8)
                    )
                    .foregroundStyle(selectedCategory != nil ? store.accentColor : Color.primary)
                }

                ForEach(AmountFilter.allCases, id: \.self) { filter in
                    let isSelected = (selectedAmountFilter == filter)
                    Button {
                        PlatformFeedback.selection()
                        selectedAmountFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(isSelected ? store.accentColor.opacity(0.18) : (colorScheme == .dark ? Color(white: 0.14) : Color.white))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(isSelected ? store.accentColor.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: 0.8)
                            )
                            .foregroundStyle(isSelected ? store.accentColor : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var resultsStream: some View {
        let results = matchingExpenses
        let grouped = Dictionary(grouping: results) { formatSectionDate($0.date) }
        let sortedDateKeys = grouped.keys.sorted { d1, d2 in
            let date1 = grouped[d1]?.first?.date ?? Date.distantPast
            let date2 = grouped[d2]?.first?.date ?? Date.distantPast
            return date1 > date2
        }

        return ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("\(results.count) \(results.count == 1 ? "RESULT" : "RESULTS")")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .tracking(0.6)

                    Spacer()

                    if totalMatchingSpend > 0 {
                        Text("Total: ₹\(formatCurrency(totalMatchingSpend))")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(store.accentColor)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)

                if results.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary.opacity(0.4))

                        Text("No Transactions Found")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.primary)

                        Text("Try searching by title, notes, #tags, or changing your filter criteria.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                    .luxuryCard(cornerRadius: 18)
                    .padding(.horizontal, 16)
                } else {
                    ForEach(sortedDateKeys, id: \.self) { dateKey in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(dateKey)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.top, 4)

                            VStack(spacing: 1) {
                                ForEach(grouped[dateKey] ?? []) { expense in
                                    resultRow(expense)
                                }
                            }
                            .luxuryCard(cornerRadius: 18)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func resultRow(_ expense: Expense) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(expense.category.color.opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: expense.category.sfSymbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(expense.category.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(expense.category.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    if !expense.notes.isEmpty {
                        Text("• \(expense.notes)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(expense.isExpense ? "-" : "+")₹\(formatCurrency(expense.amount))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(expense.isExpense ? Color.primary : Color.green)

                Text(formatTime(expense.date))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
        .onTapGesture {
            PlatformFeedback.selection()
            editingExpense = expense
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                PlatformFeedback.warning()
                store.deleteExpense(id: expense.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "TODAY" }
        if calendar.isDateInYesterday(date) { return "YESTERDAY" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date).uppercased()
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

