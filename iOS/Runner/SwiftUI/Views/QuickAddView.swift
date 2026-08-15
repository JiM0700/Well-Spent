import SwiftUI

public struct QuickAddView: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) var dismiss

    @State private var amountString: String = ""
    @State private var title: String = ""
    @State private var selectedCategory: ExpenseCategory = .food
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var isExpense: Bool = true
    @Environment(\.colorScheme) var colorScheme

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // ── Hero Amount Input ─────────────────────────────────
                    VStack(spacing: 6) {
                        Text("TRANSACTION AMOUNT")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundStyle(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("₹")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(store.accentColor)

                            TextField("0.00", text: $amountString)
                                .font(.system(size: 44, weight: .heavy, design: .rounded))
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity)
                    .liquidGlassCard(cornerRadius: 20)
                    .padding(.horizontal)

                    // ── Category Selector Grid ────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SELECT CATEGORY")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            ForEach(ExpenseCategory.allCases) { cat in
                                categoryChip(for: cat)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // ── Title & Details Fields ────────────────────────────
                    VStack(spacing: 12) {
                        TextField("Description (e.g. Blue Tokai Coffee)", text: $title)
                            .padding(14)
                            .liquidGlassCard(cornerRadius: 14, interactiveHover: false)

                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .padding(14)
                            .liquidGlassCard(cornerRadius: 14, interactiveHover: false)

                        TextField("Optional Notes", text: $notes)
                            .padding(14)
                            .liquidGlassCard(cornerRadius: 14, interactiveHover: false)
                    }
                    .padding(.horizontal)

                    // ── Action Button ─────────────────────────────────────
                    Button(action: saveTransaction) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("Record Transaction")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(LiquidGlassButtonStyle(tintColor: store.accentColor, cornerRadius: 14))
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .navigationTitle("New Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .background(colorScheme == .dark ? Color.black : Color.appGroupedBackground)
        }
    }

    private func categoryChip(for category: ExpenseCategory) -> some View {
        let isSelected = selectedCategory == category

        return Button(action: {
            PlatformFeedback.selection()
            selectedCategory = category
        }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color.opacity(0.28) : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? category.color : Color.clear, lineWidth: 1.5)
                                .shadow(color: isSelected ? category.color.opacity(0.5) : Color.clear, radius: 4)
                        )

                    Image(systemName: category.sfSymbol)
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? category.color : .secondary)
                }

                Text(category.displayName.components(separatedBy: " ").first ?? "")
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.primary : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .liquidGlassCard(cornerRadius: 14, interactiveHover: !isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func saveTransaction() {
        guard let amount = Double(amountString), amount > 0 else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces).isEmpty ? selectedCategory.displayName : title

        let expense = Expense(
            title: trimmedTitle,
            amount: amount,
            category: selectedCategory,
            date: date,
            notes: notes,
            isExpense: isExpense
        )

        PlatformFeedback.impact()
        store.addExpense(expense)
        dismiss()
    }
}
