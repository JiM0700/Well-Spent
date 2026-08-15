import SwiftUI

public struct CategoriesView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var selectedCategoryForEdit: ExpenseCategory? = nil
    @State private var newBudgetString: String = ""
    @State private var showEditDialog: Bool = false
    @Environment(\.colorScheme) var colorScheme

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 18) {
                    // ── Header Section ─────────────────────────────────────
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    // ── Allocation Summary Bar ────────────────────────────
                    allocationSummaryCard
                        .padding(.horizontal, 20)

                    // ── Category Envelope Grid ────────────────────────────
                    #if os(macOS)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 14)], spacing: 14) {
                        ForEach(ExpenseCategory.allCases) { category in
                            envelopeCard(for: category)
                        }
                    }
                    .padding(.horizontal, 20)
                    #else
                    LazyVStack(spacing: 12) {
                        ForEach(ExpenseCategory.allCases) { category in
                            envelopeCard(for: category)
                        }
                    }
                    .padding(.horizontal, 16)
                    #endif

                    #if os(iOS)
                    Spacer(minLength: 120)
                    #else
                    Spacer(minLength: 40)
                    #endif
                }
                .padding(.vertical, 8)
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .background(colorScheme == .dark ? Color.black : Color.appGroupedBackground)
            .alert("Edit Category Budget Target", isPresented: $showEditDialog) {
                TextField("Target Amount", text: $newBudgetString)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                Button("Save Target") {
                    if let cat = selectedCategoryForEdit, let amt = Double(newBudgetString) {
                        store.updateCategoryBudget(category: cat, amount: amt)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(selectedCategoryForEdit?.displayName ?? "")
            }
        }
    }

    // ── Header Section ────────────────────────────────────────────────────

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Categories")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                Text("Envelope Budgeting & Target Allocations")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // ── Allocation Summary Card ───────────────────────────────────────────

    private var allocationSummaryCard: some View {
        let totalAllocated = ExpenseCategory.allCases.reduce(0.0) { $0 + store.getCategoryBudget(category: $1) }
        let budget = store.monthlyBudget
        let percentAllocated = budget > 0 ? (totalAllocated / budget) : 0.0

        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("TOTAL ALLOCATED TARGETS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("₹")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("\(Int(totalAllocated))")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                    Text("of ₹\(Int(budget))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("ENVELOPE COVERAGE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                Text("\(Int(percentAllocated * 100))% Allocated")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(percentAllocated > 1.0 ? Color.orange : store.accentColor)
            }
        }
        .padding(14)
        .liquidGlassCard(cornerRadius: 14)
    }

    // ── Envelope Card with Liquid Glass ───────────────────────────────────

    private func envelopeCard(for category: ExpenseCategory) -> some View {
        let amount = store.categoryBreakdown[category] ?? 0.0
        let budget = store.getCategoryBudget(category: category)
        let hasBudget = budget > 0
        let progress = hasBudget ? (amount / budget) : (store.currentPeriodTotal > 0 ? (amount / store.currentPeriodTotal) : 0.0)
        let isOver = hasBudget && amount > budget
        let isWarning = hasBudget && amount >= budget * 0.8 && !isOver
        let barColor: Color = isOver ? .red : (isWarning ? .orange : category.color)
        let remaining = budget - amount

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Category Icon with Glowing Ring
                ZStack {
                    Circle()
                        .fill(barColor.opacity(0.18))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(barColor.opacity(0.3), lineWidth: 0.8)
                        )

                    Image(systemName: category.sfSymbol)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(barColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.displayName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.primary)
                    Text(hasBudget ? "₹\(Int(budget)) Monthly Target" : "No Target Set")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("₹")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f", amount))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    Text(hasBudget ? (isOver ? "Over by ₹\(Int(abs(remaining)))" : "₹\(Int(remaining)) left") : "\(Int(progress * 100))% of spend")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(isOver ? Color.red : (isWarning ? Color.orange : Color.green))
                }
            }

            // Glowing Liquid Glass Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: isOver ? [Color.orange, Color.red] : [barColor, barColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, geo.size.width * CGFloat(min(1.0, progress))), height: 6)
                        .shadow(color: barColor.opacity(0.35), radius: 3, x: 0, y: 1)
                }
            }
            .frame(height: 6)

            // Quick Edit Button on Hover / Click
            HStack {
                Text("\(Int(progress * 100))% used")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: {
                    PlatformFeedback.selection()
                    selectedCategoryForEdit = category
                    newBudgetString = String(format: "%.0f", budget)
                    showEditDialog = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                        Text(hasBudget ? "Edit Target" : "Set Target")
                            .font(.system(size: 11, weight: .semibold))
                    }
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 8))
            }
        }
        .padding(14)
        .liquidGlassCard(cornerRadius: 16)
    }
}
