import Charts
import SwiftUI

public struct InsightsView: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.colorScheme) var colorScheme

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // ── Screen Header Title ───────────────────────────────
                    HStack {
                        Text("Insights")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)

                    // ── Burn Rate & Velocity ──────────────────────────────
                    velocityCard
                        .padding(.horizontal)

                    // ── Spend Distribution Chart (Apple Charts Framework) ─
                    categoryDistributionSection
                        .padding(.horizontal)

                    // ── Recurring Subscriptions & Bills ───────────────────
                    recurringBillsSection
                        .padding(.horizontal)

                    Spacer(minLength: 120)
                }
                .padding(.top, 4)
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(colorScheme == .dark ? Color(red: 0.04, green: 0.05, blue: 0.08) : Color(uiColor: .systemGroupedBackground))
        }
    }

    private var velocityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Projected Trajectory")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Color.green)
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Average")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("₹")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("\(Int(store.dailySpendAverage))")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Projected Month-End")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("₹")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(store.projectedMonthEnd > store.monthlyBudget ? Color.red.opacity(0.8) : Color.secondary)
                        Text("\(Int(store.projectedMonthEnd))")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(store.projectedMonthEnd > store.monthlyBudget ? Color.red : Color.primary)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(colorScheme == .dark ? Color(red: 0.08, green: 0.10, blue: 0.16).opacity(0.85) : Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.06), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.06), radius: 16, x: 0, y: 6)
        )
    }

    private var recurringBillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Fixed Commitments")
                .font(.system(size: 16, weight: .bold))

            VStack(spacing: 8) {
                ForEach(store.recurringBills) { bill in
                    HStack {
                        ZStack {
                            Circle()
                                .fill(bill.category.color.opacity(0.18))
                                .frame(width: 36, height: 36)
                            Image(systemName: bill.category.sfSymbol)
                                .font(.system(size: 15))
                                .foregroundStyle(bill.category.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(bill.title)
                                .font(.system(size: 14, weight: .semibold))
                            Text("Due on Day \(bill.dueDay)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("₹\(Int(bill.amount))")
                            .font(.system(size: 14, weight: .bold, design: .rounded))

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            store.toggleRecurringBillPaid(id: bill.id)
                        }) {
                            Image(systemName: bill.isPaid ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(bill.isPaid ? Color.green : Color.secondary)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(colorScheme == .dark ? Color(red: 0.08, green: 0.10, blue: 0.16).opacity(0.5) : Color.white.opacity(0.8))
                    )
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(colorScheme == .dark ? Color(red: 0.08, green: 0.10, blue: 0.16).opacity(0.85) : Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.06), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.06), radius: 16, x: 0, y: 6)
        )
    }

    private var categoryDistributionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Spend Breakdown")
                .font(.system(size: 16, weight: .bold))

            let total = store.currentPeriodTotal

            if total > 0 {
                // Apple Native Swift Charts (Sector Donut Chart)
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
            }

            ForEach(ExpenseCategory.allCases) { cat in
                let amt = store.categoryBreakdown[cat] ?? 0.0
                let pct = total > 0 ? (amt / total) : 0.0

                if amt > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(cat.displayName)
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Text("₹\(String(format: "%.2f", amt)) (\(Int(pct * 100))%)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.secondary)
                        }

                        // Apple Native ProgressView
                        ProgressView(value: min(1.0, max(0.0, pct)))
                            .tint(cat.color)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(colorScheme == .dark ? Color(red: 0.08, green: 0.10, blue: 0.16).opacity(0.85) : Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.06), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.06), radius: 16, x: 0, y: 6)
        )
    }
}
