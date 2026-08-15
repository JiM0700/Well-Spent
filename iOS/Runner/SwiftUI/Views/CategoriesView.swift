import SwiftUI

public struct CategoriesView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var selectedCategoryForEdit: ExpenseCategory? = nil
    @State private var newBudgetString: String = ""
    @State private var showEditDialog: Bool = false
    @Environment(\.colorScheme) var colorScheme

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // ── Screen Header Title ───────────────────────────────
                    HStack {
                        Text("Categories")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Spacer()
                    }
                    .padding(.top, 4)

                    ForEach(ExpenseCategory.allCases) { category in
                        envelopeCard(for: category)
                    }
                    Spacer(minLength: 120)
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(colorScheme == .dark ? Color.black : Color(uiColor: .systemGroupedBackground))
            .alert("Edit Category Budget", isPresented: $showEditDialog) {
                TextField("Budget Amount", text: $newBudgetString)
                    .keyboardType(.decimalPad)
                Button("Save") {
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
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(barColor.opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: category.sfSymbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(barColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    Text(hasBudget ? "₹\(Int(budget)) Monthly Target" : "No Target Set")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("₹")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f", amount))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    Text(hasBudget ? (isOver ? "Over by ₹\(Int(abs(remaining)))" : "₹\(Int(remaining)) left") : "\(Int(progress * 100))% of total")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isOver ? Color.red : (isWarning ? Color.orange : Color.green))
                }
            }

            // Apple Native ProgressView
            ProgressView(value: min(1.0, max(0.0, progress)))
                .tint(barColor)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 0.6)
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.04), radius: 8, x: 0, y: 3)
        )
        .onTapGesture {
            UISelectionFeedbackGenerator().selectionChanged()
            selectedCategoryForEdit = category
            newBudgetString = String(format: "%.0f", budget)
            showEditDialog = true
        }
    }
}
