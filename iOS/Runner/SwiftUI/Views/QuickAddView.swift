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

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // ── Hero Amount Input ─────────────────────────────────
                    VStack(spacing: 6) {
                        Text("Amount")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("₹")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(store.accentColor)

                            TextField("0.00", text: $amountString)
                                .font(.system(size: 44, weight: .heavy, design: .rounded))
                                .keyboardType(.decimalPad)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.04), lineWidth: 0.8)
                            )
                    )
                    .padding(.horizontal)

                    // ── Category Selector Grid ────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Category")
                            .font(.subheadline)
                            .fontWeight(.semibold)
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
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            )

                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            )

                        TextField("Optional Notes", text: $notes)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            )
                    }
                    .padding(.horizontal)

                    // ── Apple Native Action Button ────────────────────────
                    Button(action: saveTransaction) {
                        Text("Add Entry")
                            .font(.system(size: 17, weight: .bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(store.accentColor)
                    .controlSize(.large)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.top, 10)
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .background(colorScheme == .dark ? Color.black : Color(uiColor: .systemGroupedBackground))
        }
    }

    private func categoryChip(for category: ExpenseCategory) -> some View {
        let isSelected = selectedCategory == category

        return Button(action: {
            UISelectionFeedbackGenerator().selectionChanged()
            selectedCategory = category
        }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color.opacity(0.25) : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)))
                        .frame(width: 44, height: 44)

                    Image(systemName: category.sfSymbol)
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? category.color : .secondary)
                }

                Text(category.displayName.components(separatedBy: " ").first ?? "")
                    .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.primary : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 1.5)
            )
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

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        store.addExpense(expense)
        dismiss()
    }
}
