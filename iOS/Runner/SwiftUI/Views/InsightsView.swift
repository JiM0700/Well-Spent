import Charts
import SwiftUI

public struct InsightsView: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.colorScheme) var colorScheme

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    // ── Clean Page Header (No empty space above page name) ─
                    HStack(alignment: .center) {
                        Text("Trends")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    // ── Spending Velocity & Projections ───────────────────
                    velocityCard
                        .padding(.horizontal, 20)

                    // ── Charts & Breakdown Section ────────────────────────
                    #if os(macOS)
                    HStack(alignment: .top, spacing: 14) {
                        categoryDistributionSection
                        recurringBillsSection
                    }
                    .padding(.horizontal, 20)
                    #else
                    categoryDistributionSection
                        .padding(.horizontal, 20)

                    recurringBillsSection
                        .padding(.horizontal, 20)
                    #endif
                }
                .padding(.vertical, 8)
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .background(Color.appGroupedBackground)
        }
    }

    // ── Velocity & Run Rate Card ──────────────────────────────────────────

    private var velocityCard: some View {
        let budget = store.monthlyBudget
        let isOver = store.projectedMonthEnd > budget && budget > 0

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Spending Velocity & Trajectory")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(store.accentColor)
            }

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Daily Average")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("₹")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("\(Int(store.dailySpendAverage))")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .opacity(0.3)
                    .padding(.horizontal, 8)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Projected Month-End")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("₹")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(isOver ? Color.red.opacity(0.8) : Color.secondary)
                        Text("\(Int(store.projectedMonthEnd))")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(isOver ? Color.red : Color.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .opacity(0.3)
                    .padding(.horizontal, 8)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Pace Status")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(isOver ? "Over Pace" : "Controlled")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(isOver ? Color.red : Color.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(isOver ? Color.red.opacity(0.12) : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)))
                        .clipShape(Capsule())
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .liquidGlassCard(cornerRadius: 20)
    }

    // ── Category Distribution (Swift Charts) ──────────────────────────────

    private var categoryDistributionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Category Breakdown")
                .font(.system(size: 16, weight: .bold))

            let total = store.currentPeriodTotal

            if total > 0 {
                Chart {
                    ForEach(ExpenseCategory.allCases) { cat in
                        let amt = store.categoryBreakdown[cat] ?? 0.0
                        if amt > 0 {
                            SectorMark(
                                angle: .value("Spend", amt),
                                innerRadius: .ratio(0.62),
                                angularInset: 1.5
                            )
                            .cornerRadius(4)
                            .foregroundStyle(cat.color)
                        }
                    }
                }
                .frame(height: 180)
                .padding(.vertical, 4)

                VStack(spacing: 10) {
                    ForEach(ExpenseCategory.allCases) { cat in
                        let amt = store.categoryBreakdown[cat] ?? 0.0
                        let pct = total > 0 ? (amt / total) : 0.0

                        if amt > 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(cat.color)
                                            .frame(width: 8, height: 8)
                                        Text(cat.displayName)
                                            .font(.system(size: 12.5, weight: .semibold))
                                    }
                                    Spacer()
                                    Text("₹\(String(format: "%.2f", amt)) (\(Int(pct * 100))%)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }

                                // Glowing Progress track
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                                            .frame(height: 5)
                                        Capsule()
                                            .fill(cat.color)
                                            .frame(width: max(4, geo.size.width * CGFloat(pct)), height: 5)
                                    }
                                }
                                .frame(height: 5)
                            }
                        }
                    }
                }
            } else {
                Text("No transactions in current cycle to chart.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 14)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .liquidGlassCard(cornerRadius: 16)
    }

    // ── Recurring Subscriptions Section ───────────────────────────────────

    private var recurringBillsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Fixed Commitments")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Text("\(store.recurringBills.count) active")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(store.recurringBills) { bill in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(bill.category.color.opacity(0.18))
                                .frame(width: 34, height: 34)
                            Image(systemName: bill.category.sfSymbol)
                                .font(.system(size: 14))
                                .foregroundStyle(bill.category.color)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(bill.title)
                                .font(.system(size: 13.5, weight: .semibold))
                            Text("Due Day \(bill.dueDay)")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("₹\(Int(bill.amount))")
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))

                        Button(action: {
                            PlatformFeedback.impact()
                            store.toggleRecurringBillPaid(id: bill.id)
                        }) {
                            Image(systemName: bill.isPaid ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18))
                                .foregroundStyle(bill.isPaid ? store.accentColor : Color.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03))
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .liquidGlassCard(cornerRadius: 16)
    }
}
