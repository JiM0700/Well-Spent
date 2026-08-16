import SwiftUI

public struct QuickAddView: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) var dismiss

    @State private var amountString: String = ""
    @State private var title: String = ""
    @State private var selectedCategory: ExpenseCategory = .food
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @FocusState private var isAmountFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // ── Hero Amount Input ─────────────────────────────────
                    VStack(spacing: 6) {
                        Text("Transaction Amount")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("₹")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(store.accentColor)

                            TextField("0.00", text: $amountString)
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .focused($isAmountFocused)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color.appSecondaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)

                    // ── Category Selector Grid ────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select Category")
                            .font(.caption.weight(.semibold))
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
                            .background(Color.appSecondaryGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .padding(14)
                            .background(Color.appSecondaryGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        TextField("Optional Notes", text: $notes)
                            .padding(14)
                            .background(Color.appSecondaryGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                    .buttonStyle(.borderedProminent)
                    .tint(store.accentColor)
                    .controlSize(.large)
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .fontWeight(.semibold)
                    .disabled(Double(amountString) == nil || (Double(amountString) ?? 0) <= 0)
                }
            }
            .background(Color.appGroupedBackground)
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAmountFocused = true
                }
            }
        }
    }

    private func categoryChip(for category: ExpenseCategory) -> some View {
        let isSelected = selectedCategory == category
        return Button(action: {
            PlatformFeedback.selection()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                selectedCategory = category
            }
        }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(isSelected ? 0.25 : 0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: category.sfSymbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(category.color)
                }

                Text(category.displayName)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? category.color.opacity(0.12) : Color.appSecondaryGroupedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func saveTransaction() {
        guard let amount = Double(amountString), amount > 0 else { return }
        let transactionTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? selectedCategory.displayName
            : title.trimmingCharacters(in: .whitespacesAndNewlines)

        PlatformFeedback.success()
        let newExpense = Expense(
            title: transactionTitle,
            amount: amount,
            category: selectedCategory,
            date: date,
            notes: notes
        )
        store.addExpense(newExpense)
        dismiss()
    }
}
