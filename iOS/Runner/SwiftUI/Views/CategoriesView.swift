import Charts
import SwiftUI

public struct CategoriesView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var selectedTab: Int = 0 // 0: Categories, 1: Goals
    @State private var selectedCategoryForDetail: ExpenseCategory? = nil
    @State private var showAddCategorySheet: Bool = false
    @State private var showAllocationBreakdownSheet: Bool = false
    @State private var selectedFilter: CategoryFilterType = .all

    // Goals state
    @State private var showNewGoalSheet: Bool = false
    @State private var editingGoal: Goal? = nil
    @State private var showDepositAlert: Bool = false
    @State private var targetGoalForDeposit: Goal? = nil
    @State private var depositAmountString: String = ""

    @Binding var showQuickAdd: Bool
    @Environment(\.colorScheme) var colorScheme

    public enum CategoryFilterType: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case over = "Over Budget"
        case noLimit = "No Limit"

        public var id: String { rawValue }
    }

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

    // ── iOS Clean Apple Health & Fitness Budgets Canvas ───────────────────

    #if os(iOS)
    private var iOSBody: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    // Segmented Switcher Pill
                    modeSwitcherPill
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                    if selectedTab == 0 {
                        // ── Mode A: Category Envelopes ────────────────────
                        heroAllocationDeck
                            .padding(.horizontal, 16)

                        filterChipsBar
                            .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("MONTHLY CATEGORY ENVELOPES")
                                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .tracking(0.6)

                                Spacer()

                                Text("\(filteredCategories.count) Envelopes")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)

                            VStack(spacing: 14) {
                                ForEach(filteredCategories) { category in
                                    categoryEnvelopeCard(for: category)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    } else {
                        // ── Mode B: Savings Goals ─────────────────────────
                        goalsSummaryBanner
                            .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("ACTIVE SAVINGS GOALS")
                                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .tracking(0.6)

                                Spacer()

                                if !store.goals.isEmpty {
                                    Text("\(store.goals.count) goals")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)

                            if store.goals.isEmpty {
                                VStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.green.opacity(0.15))
                                            .frame(width: 64, height: 64)
                                        Image(systemName: "target")
                                            .font(.system(size: 28, weight: .semibold))
                                            .foregroundStyle(Color.green)
                                    }
                                    .padding(.top, 20)

                                    Text("No Savings Goals Yet")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))

                                    Text("Create a dedicated savings goal for a vacation, gadget, or emergency fund.")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 24)

                                    Button {
                                        PlatformFeedback.impact(.light)
                                        showNewGoalSheet = true
                                    } label: {
                                        Label("Create First Goal", systemImage: "plus")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    }
                                    .buttonStyle(.luxuryGlass)
                                    .padding(.vertical, 16)
                                }
                                .frame(maxWidth: .infinity)
                                .luxuryCard(cornerRadius: 22)
                                .padding(.horizontal, 16)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(store.goals) { goal in
                                        modernGoalCard(for: goal)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.bottom, 36)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.appGroupedBackground.ignoresSafeArea())
            .navigationTitle(selectedTab == 0 ? "Budgets" : "Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        PlatformFeedback.impact(.rigid)
                        if selectedTab == 0 {
                            showAddCategorySheet = true
                        } else {
                            showNewGoalSheet = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .accessibilityLabel(selectedTab == 0 ? "New Category" : "New Goal")
                }
            }
            .alert("Add Funds to Goal", isPresented: $showDepositAlert) {
                TextField("Deposit Amount (₹)", text: $depositAmountString)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                Button("Deposit") {
                    if let goal = targetGoalForDeposit, let amt = Double(depositAmountString), amt > 0 {
                        PlatformFeedback.success()
                        store.depositToGoal(id: goal.id, amount: amt)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(targetGoalForDeposit?.title ?? "")
            }
            .sheet(isPresented: $showAllocationBreakdownSheet) {
                TotalAllocationBreakdownSheet()
                    .environmentObject(store)
            }
            .sheet(item: $selectedCategoryForDetail) { category in
                CategoryDetailSheet(category: category)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showAddCategorySheet) {
                AddCategorySheet()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showNewGoalSheet) {
                GoalFormSheet(goalToEdit: nil)
                    .environmentObject(store)
            }
            .sheet(item: $editingGoal) { goal in
                GoalFormSheet(goalToEdit: goal)
                    .environmentObject(store)
            }
        }
    }
    #endif

    // ── Mode Switcher ─────────────────────────────────────────────────────

    private var modeSwitcherPill: some View {
        Picker("Mode", selection: $selectedTab) {
            Text("Category Budgets").tag(0)
            Text("Savings Goals").tag(1)
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedTab) { _, _ in
            PlatformFeedback.selection()
        }
    }

    // ── Category Filter Logic ─────────────────────────────────────────────

    private var filteredCategories: [ExpenseCategory] {
        store.allCategories.filter { cat in
            let budget = store.categoryBudgets[cat.rawValue] ?? 0.0
            let spent = store.spentForCategory(cat)
            switch selectedFilter {
            case .all:
                return true
            case .active:
                return spent > 0 || budget > 0
            case .over:
                return spent > budget && budget > 0
            case .noLimit:
                return budget == 0
            }
        }
    }

    // ── Filter Chips Bar ──────────────────────────────────────────────────

    private var filterChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CategoryFilterType.allCases) { filter in
                    let isSelected = selectedFilter == filter
                    let count: Int = {
                        store.allCategories.filter { cat in
                            let budget = store.categoryBudgets[cat.rawValue] ?? 0.0
                            let spent = store.spentForCategory(cat)
                            switch filter {
                            case .all: return true
                            case .active: return spent > 0 || budget > 0
                            case .over: return spent > budget && budget > 0
                            case .noLimit: return budget == 0
                            }
                        }.count
                    }()

                    Button {
                        PlatformFeedback.selection()
                        withAnimation(.appleSpring) {
                            selectedFilter = filter
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(filter.rawValue)
                            Text("\(count)")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(isSelected ? Color.white.opacity(0.25) : Color.secondary.opacity(0.18))
                                .clipShape(Capsule())
                        }
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            isSelected
                                ? store.accentColor
                                : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                        )
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // ── Luxury Hero Allocation Deck ───────────────────────────────────────

    private var heroAllocationDeck: some View {
        let totalAssigned = store.categoryBudgets.values.reduce(0.0, +)
        let overallBudget = store.monthlyBudget
        let unallocated = max(0, overallBudget - totalAssigned)
        let isOverAllocated = totalAssigned > overallBudget && overallBudget > 0
        let totalSpent = store.currentPeriodTotal
        let usagePercentage = overallBudget > 0 ? Int((totalAssigned / overallBudget) * 100) : 0

        return VStack(spacing: 16) {
            // Top: Header & Main Metric
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Text("TOTAL BUDGET ALLOCATION")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(0.6)

                        Image(systemName: "info.circle")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(store.accentColor.opacity(0.8))
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("₹")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundStyle(isOverAllocated ? Color.red : store.accentColor)

                        Text(formatCurrency(totalAssigned))
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(isOverAllocated ? Color.red : Color.primary)
                            .contentTransition(.numericText())

                        Text("assigned of ₹\(formatCurrency(overallBudget))")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 2)
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill((isOverAllocated ? Color.red : store.accentColor).opacity(0.16))
                        .frame(width: 42, height: 42)
                    Image(systemName: isOverAllocated ? "exclamationmark.triangle.fill" : "chart.pie.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isOverAllocated ? Color.red : store.accentColor)
                }
            }

            // Multi-Segment Category Allocation Ribbon
            GeometryReader { geo in
                let totalWidth = geo.size.width
                ZStack(alignment: .leading) {
                    // Background Track
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                        .frame(height: 10)

                    // Stacked Segments
                    HStack(spacing: 2) {
                        ForEach(store.allCategories) { cat in
                            let catBudget = store.categoryBudgets[cat.rawValue] ?? 0.0
                            if catBudget > 0 && overallBudget > 0 {
                                let ratio = min(1.0, catBudget / overallBudget)
                                let segmentWidth = max(4, totalWidth * CGFloat(ratio))
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(cat.color)
                                    .frame(width: segmentWidth, height: 10)
                            }
                        }
                    }
                    .clipShape(Capsule())
                }
            }
            .frame(height: 10)

            // Status Banner Pill
            HStack(spacing: 6) {
                Image(systemName: isOverAllocated ? "exclamationmark.circle.fill" : "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isOverAllocated ? Color.red : store.accentColor)

                Text(
                    isOverAllocated
                        ? "₹\(formatCurrency(totalAssigned - overallBudget)) over total planned budget"
                        : "₹\(formatCurrency(unallocated)) unallocated monthly cushion"
                )
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundStyle(isOverAllocated ? Color.red : .secondary)

                Spacer()

                Text("\(usagePercentage)% Assigned")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(isOverAllocated ? Color.red : store.accentColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background((isOverAllocated ? Color.red : store.accentColor).opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Divider().opacity(0.3)

            // 3-Metric Pulse Strip
            HStack {
                budgetMetricColumn(
                    title: "ENVELOPES",
                    value: "\(store.allCategories.count) Total",
                    sub: "\(store.allCategories.filter { (store.categoryBudgets[$0.rawValue] ?? 0) > 0 }.count) active"
                )
                Spacer()
                Divider().frame(height: 24).opacity(0.3)
                Spacer()
                budgetMetricColumn(
                    title: "TOTAL SPENT",
                    value: "₹\(formatCurrency(totalSpent))",
                    sub: "across all"
                )
                Spacer()
                Divider().frame(height: 24).opacity(0.3)
                Spacer()
                budgetMetricColumn(
                    title: "BUFFER",
                    value: isOverAllocated ? "-₹\(formatCurrency(totalAssigned - overallBudget))" : "₹\(formatCurrency(unallocated))",
                    sub: isOverAllocated ? "deficit" : "free cushion",
                    color: isOverAllocated ? Color.red : store.accentColor
                )
            }
        }
        .padding(18)
        .luxuryCard(glowColor: isOverAllocated ? Color.red : store.accentColor, glowIntensity: isOverAllocated ? 0.16 : 0.10)
        .contentShape(Rectangle())
        .onTapGesture {
            PlatformFeedback.impact(.light)
            showAllocationBreakdownSheet = true
        }
    }

    private func budgetMetricColumn(title: String, value: String, sub: String, color: Color = .primary) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(sub)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    // ── Remodeled Category Envelope Card ───────────────────────────────────

    private func categoryEnvelopeCard(for category: ExpenseCategory) -> some View {
        let budget = store.categoryBudgets[category.rawValue] ?? 0.0
        let spent = store.spentForCategory(category)
        let usage = budget > 0 ? min(1.5, spent / budget) : 0.0
        let remaining = max(0, budget - spent)
        let isOver = spent > budget && budget > 0
        let percentInt = Int(usage * 100)
        let count = store.currentPeriodExpenses.filter { $0.category == category && $0.isExpense }.count
        let days = max(1, store.daysElapsedInCycle)
        let dailyAvg = spent / Double(days)

        return VStack(spacing: 12) {
            // Main Top Row
            HStack(spacing: 14) {
                // Category Glass Pod
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: category.sfSymbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(category.color)
                }

                // Category Title & Amount
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(category.displayName)
                            .font(.system(size: 15.5, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)

                        if category.isCustom {
                            Text("CUSTOM")
                                .font(.system(size: 8, weight: .heavy, design: .rounded))
                                .foregroundStyle(category.color)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(category.color.opacity(0.14))
                                .clipShape(Capsule())
                        }
                    }

                    if budget > 0 {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("₹\(formatCurrency(spent))")
                                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                                .foregroundStyle(isOver ? Color.red : Color.primary)
                            Text("spent of ₹\(formatCurrency(budget))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("₹\(formatCurrency(spent)) spent • No limit set")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Status Badge Pill
                if budget > 0 {
                    Text(isOver ? "OVER" : "\(percentInt)%")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(isOver ? Color.red : category.color)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background((isOver ? Color.red : category.color).opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Text("Set Limit")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(store.accentColor)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(store.accentColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            // Progress Bar Gauge
            if budget > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                            .frame(height: 7)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: isOver ? [Color.orange, Color.red] : [category.color, category.color.opacity(0.75)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(6, geo.size.width * CGFloat(min(1.0, usage))), height: 7)
                            .shadow(color: (isOver ? Color.red : category.color).opacity(0.35), radius: 3, x: 0, y: 1)
                    }
                }
                .frame(height: 7)
            }

            // Bottom Micro-Metrics Strip
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 10))
                    Text("\(count) \(count == 1 ? "entry" : "entries")")
                    if spent > 0 {
                        Text("• ₹\(Int(dailyAvg))/day pace")
                    }
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

                Spacer()

                if budget > 0 {
                    Text(isOver ? "₹\(formatCurrency(spent - budget)) over" : "₹\(formatCurrency(remaining)) left")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundStyle(isOver ? Color.red : Color.primary)
                } else {
                    Text("Tap to configure")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .luxuryCard(glowColor: category.color, glowIntensity: isOver ? 0.14 : 0.08)
        .contentShape(Rectangle())
        .onTapGesture {
            PlatformFeedback.selection()
            selectedCategoryForDetail = category
        }
    }

    // ── Goals Summary Banner ──────────────────────────────────────────────

    private var goalsSummaryBanner: some View {
        let totalTarget = store.goals.reduce(0.0) { $0 + $1.targetAmount }
        let totalSaved = store.goals.reduce(0.0) { $0 + $1.currentAmount }
        let overallPercent = totalTarget > 0 ? min(1.0, totalSaved / totalTarget) : 0.0

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("TOTAL SAVED TOWARD GOALS")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("₹\(formatCurrency(totalSaved))")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.green)
                            .contentTransition(.numericText())

                        Text("of ₹\(formatCurrency(totalTarget))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.18))
                        .frame(width: 42, height: 42)
                    Image(systemName: "target")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.green)
                }
            }

            ProgressView(value: overallPercent)
                .tint(Color.green)

            HStack {
                Text("₹\(formatCurrency(max(0, totalTarget - totalSaved))) remaining to complete all goals")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(overallPercent * 100))% achieved")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(Color.green)
            }
        }
        .padding(16)
        .luxuryCard(glowColor: Color.green, glowIntensity: 0.10)
    }

    // ── Modern Savings Goal Card (Apple Vault Style) ──────────────────────

    private func modernGoalCard(for goal: Goal) -> some View {
        let percent = goal.targetAmount > 0 ? min(1.0, goal.currentAmount / goal.targetAmount) : 0.0
        let remaining = max(0, goal.targetAmount - goal.currentAmount)
        let isAchieved = goal.currentAmount >= goal.targetAmount && goal.targetAmount > 0

        return VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Goal Icon Ring
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 4)
                        .frame(width: 46, height: 46)

                    Circle()
                        .trim(from: 0, to: CGFloat(percent))
                        .stroke(
                            isAchieved ? Color.green : store.accentColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 46, height: 46)

                    Image(systemName: goal.sfSymbol)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isAchieved ? Color.green : store.accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(goal.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)

                        if isAchieved {
                            Text("GOAL MET 🎉")
                                .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.green)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    Text("₹\(formatCurrency(goal.currentAmount)) of ₹\(formatCurrency(goal.targetAmount)) (\(Int(percent * 100))%)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    PlatformFeedback.impact(.light)
                    targetGoalForDeposit = goal
                    depositAmountString = ""
                    showDepositAlert = true
                } label: {
                    Text("+ Deposit")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            ProgressView(value: percent)
                .tint(isAchieved ? Color.green : store.accentColor)

            HStack {
                Text(isAchieved ? "Fully funded" : "₹\(formatCurrency(remaining)) left to reach milestone")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                if let date = goal.deadline {
                    Text("Deadline: \(formatShortDate(date))")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .luxuryCard(glowColor: isAchieved ? Color.green : store.accentColor, glowIntensity: 0.08)
        .contentShape(Rectangle())
        .onTapGesture {
            PlatformFeedback.selection()
            editingGoal = goal
        }
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
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
                modeSwitcherPill
                if selectedTab == 0 {
                    heroAllocationDeck
                    ForEach(store.allCategories) { category in
                        categoryEnvelopeCard(for: category)
                    }
                } else {
                    goalsSummaryBanner
                    ForEach(store.goals) { goal in
                        modernGoalCard(for: goal)
                    }
                }
            }
            .padding(24)
        }
    }
    #endif
}

// ── Total Budget Allocation & Category Cost Breakdown Sheet ─────────────────

public struct TotalAllocationBreakdownSheet: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    private struct CategoryCostItem: Identifiable {
        var id: String { category.id }
        let category: ExpenseCategory
        let budget: Double
        let spent: Double
        let sharePercentage: Double
        let burnPercentage: Double
    }

    private var categoryCostItems: [CategoryCostItem] {
        let totalBudget = max(1.0, store.monthlyBudget)
        return store.allCategories.map { cat in
            let b = store.categoryBudgets[cat.rawValue] ?? 0.0
            let s = store.spentForCategory(cat)
            let share = (b / totalBudget) * 100.0
            let burn = b > 0 ? (s / b) * 100.0 : 0.0
            return CategoryCostItem(
                category: cat,
                budget: b,
                spent: s,
                sharePercentage: share,
                burnPercentage: burn
            )
        }.sorted { $0.budget > $1.budget }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Summary Formula Header Card
                    summaryFormulaCard

                    // Category Cost Distribution Chart Card (Donut)
                    costDonutCard

                    // Category-Wise Cost Breakdown List Card
                    categoryCostListCard

                    Spacer(minLength: 20)
                }
                .padding(16)
            }
            .background(Color.appGroupedBackground.ignoresSafeArea())
            .navigationTitle("Allocation Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(store.accentColor)
                }
            }
        }
    }

    // ── Summary Formula Card ──────────────────────────────────────────────

    private var summaryFormulaCard: some View {
        let totalAssigned = store.categoryBudgets.values.reduce(0.0, +)
        let overallBudget = store.monthlyBudget
        let unallocated = max(0, overallBudget - totalAssigned)
        let isOverAllocated = totalAssigned > overallBudget && overallBudget > 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(store.accentColor)

                Text("MONTHLY ALLOCATION FORMULA")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(store.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Formula:")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Total Assigned = Sum of All Category Envelopes\nBuffer Cushion = Monthly Budget - Total Assigned")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Live Allocation Calculation:")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.secondary)

                HStack {
                    Text("₹\(formatCurrency(totalAssigned)) assigned of ₹\(formatCurrency(overallBudget))")
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .foregroundStyle(isOverAllocated ? Color.red : Color.primary)
                    Spacer()
                    Text(isOverAllocated ? "⚠️ Over-allocated" : "✨ ₹\(formatCurrency(unallocated)) cushion")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundStyle(isOverAllocated ? Color.red : Color.green)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
            )
        }
        .padding(16)
        .luxuryCard(glowColor: store.accentColor, glowIntensity: 0.06)
    }

    // ── Cost Donut Card ───────────────────────────────────────────────────

    private var costDonutCard: some View {
        let activeItems = categoryCostItems.filter { $0.budget > 0 }
        let totalAssigned = activeItems.reduce(0.0) { $0 + $1.budget }

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("BUDGET SHARE DISTRIBUTION")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                Spacer()
                Text("\(activeItems.count) Envelopes (₹\(formatCurrency(totalAssigned)))")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            if activeItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("No envelope budgets configured yet.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                HStack(spacing: 16) {
                    // Donut Chart
                    Chart(activeItems) { item in
                        SectorMark(
                            angle: .value("Budget", item.budget),
                            innerRadius: .ratio(0.62),
                            angularInset: 1.5
                        )
                        .foregroundStyle(item.category.color)
                        .cornerRadius(3)
                    }
                    .frame(width: 110, height: 110)

                    // Top 4 Allocation Share Rows
                    VStack(spacing: 6) {
                        ForEach(activeItems.prefix(4)) { item in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(item.category.color)
                                    .frame(width: 8, height: 8)

                                Text(item.category.displayName)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)

                                Spacer()

                                Text("\(Int(item.sharePercentage))%")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(.secondary)

                                Text("₹\(formatCurrency(item.budget))")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.primary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .luxuryCard()
    }

    // ── Concise Category-Wise Cost Breakdown List ─────────────────────────

    private var categoryCostListCard: some View {
        let items = categoryCostItems.filter { $0.budget > 0 || $0.spent > 0 }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CATEGORY ALLOCATIONS & SPEND")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)

                Spacer()

                Text("\(items.count) active")
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                ForEach(items) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(item.category.color)
                            .frame(width: 8, height: 8)

                        Text(item.category.displayName)
                            .font(.system(size: 12.5, weight: .semibold))
                            .lineLimit(1)

                        Spacer()

                        if item.budget > 0 {
                            Text("\(Int(item.sharePercentage))% share")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)

                            Text("₹\(formatCurrency(item.spent))/₹\(formatCurrency(item.budget))")
                                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                .foregroundStyle(item.spent > item.budget ? Color.red : Color.primary)
                        } else {
                            Text("₹\(formatCurrency(item.spent)) spent")
                                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.025))
                    )
                }
            }
        }
        .padding(14)
        .luxuryCard()
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}

// ── Luxury Category Detail & Envelope Editor Sheet ───────────────────────────

public struct CategoryDetailSheet: View {
    let category: ExpenseCategory
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var budgetAmountString: String = ""
    @State private var showDeleteConfirm: Bool = false

    private var currentBudget: Double {
        store.categoryBudgets[category.rawValue] ?? 0.0
    }

    private var categoryExpenses: [Expense] {
        store.currentPeriodExpenses
            .filter { $0.category == category && $0.isExpense }
            .sorted { $0.date > $1.date }
    }

    private var totalSpent: Double {
        categoryExpenses.reduce(0.0) { $0 + $1.amount }
    }

    private var daysElapsed: Int {
        max(1, store.daysElapsedInCycle)
    }

    private var dailyBurn: Double {
        totalSpent / Double(daysElapsed)
    }

    private var remainingDays: Int {
        max(1, store.daysRemainingInCycle)
    }

    private var safeDailyAllowance: Double {
        guard currentBudget > totalSpent else { return 0.0 }
        return (currentBudget - totalSpent) / Double(remainingDays)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Header Aura Card
                    headerAuraCard

                    // Budget Setting & Quick Increment Box
                    budgetAdjustmentCard

                    // Category Analytics Deck
                    categoryAnalyticsDeck

                    // Recent Category Transactions Feed
                    transactionsSection
                }
                .padding(16)
            }
            .background(Color.appGroupedBackground.ignoresSafeArea())
            .navigationTitle(category.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(store.accentColor)
                }

                if category.isCustom {
                    ToolbarItem(placement: .destructiveAction) {
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.red)
                        }
                    }
                }
            }
            .confirmationDialog("Delete Custom Category?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete \"\(category.displayName)\"", role: .destructive) {
                    PlatformFeedback.warning()
                    store.deleteCustomCategory(id: category.id)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Expenses under this category will be re-assigned to Other.")
            }
            .onAppear {
                if currentBudget > 0 {
                    budgetAmountString = "\(Int(currentBudget))"
                }
            }
        }
    }

    // ── Header Aura Card ──────────────────────────────────────────────────

    private var headerAuraCard: some View {
        let isOver = totalSpent > currentBudget && currentBudget > 0
        let usage = currentBudget > 0 ? min(1.5, totalSpent / currentBudget) : 0.0

        return VStack(spacing: 14) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.20))
                        .frame(width: 58, height: 58)
                    Image(systemName: category.sfSymbol)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(category.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(category.displayName)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)

                        if category.isCustom {
                            Text("CUSTOM")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundStyle(category.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(category.color.opacity(0.14))
                                .clipShape(Capsule())
                        }
                    }

                    if currentBudget > 0 {
                        Text(isOver ? "₹\(formatCurrency(totalSpent - currentBudget)) over monthly limit" : "₹\(formatCurrency(max(0, currentBudget - totalSpent))) left of ₹\(formatCurrency(currentBudget))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isOver ? Color.red : .secondary)
                    } else {
                        Text("₹\(formatCurrency(totalSpent)) spent this cycle • No envelope set")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            if currentBudget > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                            .frame(height: 8)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: isOver ? [Color.orange, Color.red] : [category.color, category.color.opacity(0.75)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * CGFloat(min(1.0, usage))), height: 8)
                            .shadow(color: (isOver ? Color.red : category.color).opacity(0.4), radius: 4, x: 0, y: 1)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(18)
        .luxuryCard(glowColor: category.color, glowIntensity: 0.12)
    }

    // ── Budget Adjustment Card ────────────────────────────────────────────

    private var budgetAdjustmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SET MONTHLY ENVELOPE TARGET")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .tracking(0.6)

            HStack(spacing: 8) {
                Text("₹")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(category.color)

                TextField("0", text: $budgetAmountString)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif

                if !budgetAmountString.isEmpty {
                    Button {
                        budgetAmountString = ""
                        PlatformFeedback.selection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
            )

            // Quick increment pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    quickIncrementButton(amount: 500)
                    quickIncrementButton(amount: 1000)
                    quickIncrementButton(amount: 2000)
                    quickIncrementButton(amount: 5000)

                    Button("Clear") {
                        PlatformFeedback.warning()
                        budgetAmountString = "0"
                        store.setCategoryBudget(category: category, amount: 0)
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.red.opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            // Save Target Button
            Button {
                let amount = Double(budgetAmountString) ?? 0.0
                PlatformFeedback.success()
                store.setCategoryBudget(category: category, amount: amount)
            } label: {
                Text("Save Envelope Target")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(category.color)
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(18)
        .luxuryCard()
    }

    private func quickIncrementButton(amount: Int) -> some View {
        Button("+₹\(amount)") {
            PlatformFeedback.selection()
            let current = Double(budgetAmountString) ?? 0.0
            budgetAmountString = "\(Int(current + Double(amount)))"
            store.setCategoryBudget(category: category, amount: current + Double(amount))
        }
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06))
        .clipShape(Capsule())
    }

    // ── Category Analytics Deck ───────────────────────────────────────────

    private var categoryAnalyticsDeck: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SPENDING VELOCITY & METRICS")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .tracking(0.6)

            HStack(spacing: 12) {
                detailMetricPill(
                    title: "DAILY BURN",
                    value: "₹\(Int(dailyBurn))",
                    sub: "per day pace"
                )

                detailMetricPill(
                    title: "SAFE ALLOWANCE",
                    value: currentBudget > totalSpent ? "₹\(Int(safeDailyAllowance))/day" : "₹0/day",
                    sub: "\(remainingDays) days remaining",
                    color: currentBudget > totalSpent ? Color.green : Color.red
                )

                let totalOverall = store.currentPeriodTotal
                let share = totalOverall > 0 ? Int((totalSpent / totalOverall) * 100) : 0
                detailMetricPill(
                    title: "BUDGET SHARE",
                    value: "\(share)%",
                    sub: "of total spend"
                )
            }
        }
        .padding(18)
        .luxuryCard()
    }

    private func detailMetricPill(title: String, value: String, sub: String, color: Color = .primary) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(sub)
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

    // ── Category Transactions Feed ────────────────────────────────────────

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT TRANSACTIONS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)

                Spacer()

                Text("\(categoryExpenses.count) this cycle")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            if categoryExpenses.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .padding(.top, 12)
                    Text("No transactions in this envelope yet this cycle.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(categoryExpenses) { exp in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exp.title)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.primary)

                                HStack(spacing: 4) {
                                    Text(formatDate(exp.date))
                                    if !exp.notes.isEmpty {
                                        Text("• \(exp.notes)")
                                    }
                                }
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            }

                            Spacer()

                            Text("₹\(formatCurrency(exp.amount))")
                                .font(.system(size: 14.5, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.primary)
                        }
                        .padding(.vertical, 6)

                        if exp.id != categoryExpenses.last?.id {
                            Divider().opacity(0.2)
                        }
                    }
                }
            }
        }
        .padding(18)
        .luxuryCard()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}

// ── Add Custom Category Sheet ────────────────────────────────────────────────

public struct AddCategorySheet: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var name: String = ""
    @State private var initialBudget: String = ""
    @State private var selectedSymbol: String = "tag.fill"
    @State private var selectedColorHex: String = "#007AFF"

    private let availableSymbols = [
        "tag.fill", "gift.fill", "pawprint.fill", "book.fill",
        "gamecontroller.fill", "airplane", "cup.and.saucer.fill", "briefcase.fill",
        "fuelpump.fill", "cart.fill", "film.fill", "music.note",
        "graduationcap.fill", "tshirt.fill", "tram.fill", "bicycle",
        "sparkles", "figure.walk", "dumbbell.fill", "camera.fill",
        "wrench.and.screwdriver.fill", "cross.case.fill", "leaf.fill", "creditcard.fill"
    ]

    private let availableColors: [(hex: String, name: String)] = [
        ("#007AFF", "Blue"),
        ("#34C759", "Green"),
        ("#FF9500", "Orange"),
        ("#FF2D55", "Pink"),
        ("#AF52DE", "Purple"),
        ("#FFCC00", "Yellow"),
        ("#5AC8FA", "Teal"),
        ("#FF3B30", "Red"),
        ("#5856D6", "Indigo"),
        ("#00C7BE", "Mint"),
        ("#FF6482", "Coral"),
        ("#8E8E93", "Slate")
    ]

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Live Preview Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("PREVIEW")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)

                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: selectedColorHex).opacity(0.18))
                                    .frame(width: 44, height: 44)
                                Image(systemName: selectedSymbol)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Color(hex: selectedColorHex))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(name.trimmingCharacters(in: .whitespaces).isEmpty ? "Category Name" : name)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.primary)

                                if let b = Double(initialBudget), b > 0 {
                                    Text("₹\(Int(b)) limit set")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("No spending limit set")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Text("Custom")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: selectedColorHex))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: selectedColorHex).opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .padding(14)
                        .luxuryCard(glowColor: Color(hex: selectedColorHex), glowIntensity: 0.10)
                    }

                    // Input Form Cards
                    VStack(spacing: 14) {
                        // Name & Budget Input Card
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("CATEGORY NAME")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .tracking(0.5)

                                TextField("e.g. Subscriptions, Pet Care, Gifts", text: $name)
                                    .font(.system(size: 15, weight: .medium))
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                                    )
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("MONTHLY BUDGET LIMIT (OPTIONAL)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .tracking(0.5)

                                HStack {
                                    Text("₹")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(.secondary)

                                    TextField("0", text: $initialBudget)
                                        .font(.system(size: 15, weight: .medium))
                                        #if os(iOS)
                                        .keyboardType(.decimalPad)
                                        #endif
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                                )
                            }
                        }
                        .padding(16)
                        .luxuryCard()

                        // Icon Picker Grid
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CHOOSE ICON")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .tracking(0.5)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                                ForEach(availableSymbols, id: \.self) { sym in
                                    let isSel = selectedSymbol == sym
                                    Button {
                                        PlatformFeedback.selection()
                                        selectedSymbol = sym
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(isSel ? Color(hex: selectedColorHex).opacity(0.20) : (colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)))
                                                .frame(width: 44, height: 44)

                                            if isSel {
                                                Circle()
                                                    .strokeBorder(Color(hex: selectedColorHex), lineWidth: 2)
                                                    .frame(width: 44, height: 44)
                                            }

                                            Image(systemName: sym)
                                                .font(.system(size: 17, weight: .medium))
                                                .foregroundStyle(isSel ? Color(hex: selectedColorHex) : Color.primary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(16)
                        .luxuryCard()

                        // Color Picker Grid
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CHOOSE COLOR")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .tracking(0.5)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                                ForEach(availableColors, id: \.hex) { col in
                                    let isSel = selectedColorHex == col.hex
                                    Button {
                                        PlatformFeedback.selection()
                                        selectedColorHex = col.hex
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: col.hex))
                                                .frame(width: 36, height: 36)

                                            if isSel {
                                                Circle()
                                                    .strokeBorder(Color.white, lineWidth: 2.5)
                                                    .frame(width: 36, height: 36)
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(16)
                        .luxuryCard()
                    }

                    // Save Action Button
                    Button {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        PlatformFeedback.success()
                        let budget = Double(initialBudget) ?? 0.0
                        _ = store.addCustomCategory(
                            displayName: trimmed,
                            sfSymbol: selectedSymbol,
                            colorHex: selectedColorHex,
                            budget: budget
                        )
                        dismiss()
                    } label: {
                        Text("Create Category")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary.opacity(0.3) : Color(hex: selectedColorHex))
                            )
                            .foregroundStyle(.white)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(16)
            }
            .background(Color.appGroupedBackground.ignoresSafeArea())
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// ── Goal Form Sheet (Edit / Create) ──────────────────────────────────────────

public struct GoalFormSheet: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) var dismiss
    var goalToEdit: Goal?

    @State private var title: String = ""
    @State private var targetAmount: String = ""
    @State private var currentAmount: String = ""
    @State private var sfSymbol: String = "shield.fill"
    @State private var deadline: Date = Date().addingTimeInterval(86400 * 90)
    @State private var hasDeadline: Bool = false

    public init(goalToEdit: Goal? = nil) {
        self.goalToEdit = goalToEdit
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    TextField("Goal Title (e.g. Vacation, Mac)", text: $title)
                    TextField("Target Amount (₹)", text: $targetAmount)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("Starting Amount (₹)", text: $currentAmount)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }

                Section("Icon & Schedule") {
                    HStack {
                        Text("Symbol")
                        Spacer()
                        Picker("", selection: $sfSymbol) {
                            Text("Shield").tag("shield.fill")
                            Text("Airplane").tag("airplane")
                            Text("Laptop").tag("laptopcomputer")
                            Text("Car").tag("car.fill")
                            Text("House").tag("house.fill")
                            Text("Heart").tag("heart.fill")
                        }
                    }

                    Toggle("Set Deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Target Date", selection: $deadline, displayedComponents: .date)
                    }
                }

                if goalToEdit != nil {
                    Section {
                        Button("Delete Goal", role: .destructive) {
                            if let id = goalToEdit?.id {
                                PlatformFeedback.warning()
                                store.deleteGoal(id: id)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle(goalToEdit == nil ? "New Goal" : "Edit Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || (Double(targetAmount) ?? 0) <= 0)
                }
            }
            .onAppear {
                if let g = goalToEdit {
                    title = g.title
                    targetAmount = "\(Int(g.targetAmount))"
                    currentAmount = "\(Int(g.currentAmount))"
                    sfSymbol = g.sfSymbol
                    if let d = g.deadline {
                        deadline = d
                        hasDeadline = true
                    }
                }
            }
        }
    }

    private func saveGoal() {
        guard let target = Double(targetAmount), target > 0 else { return }
        let current = Double(currentAmount) ?? 0.0

        if let existing = goalToEdit {
            var updated = existing
            updated.title = title
            updated.targetAmount = target
            updated.currentAmount = current
            updated.sfSymbol = sfSymbol
            updated.deadline = hasDeadline ? deadline : nil
            store.updateGoal(updated)
        } else {
            let newGoal = Goal(
                title: title,
                targetAmount: target,
                currentAmount: current,
                deadline: hasDeadline ? deadline : nil,
                sfSymbol: sfSymbol,
                colorName: "green"
            )
            store.addGoal(newGoal)
        }
        PlatformFeedback.success()
        dismiss()
    }
}
