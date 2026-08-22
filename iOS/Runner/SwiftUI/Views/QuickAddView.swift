import SwiftUI

public struct QuickAddView: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) var dismiss

    public var expenseToEdit: Expense? = nil

    @State private var isExpense: Bool = true
    @State private var amountString: String = ""
    @State private var title: String = ""
    @State private var selectedCategory: ExpenseCategory = .food
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var selectedTags: [String] = []
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isTitleFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    public init(expenseToEdit: Expense? = nil) {
        self.expenseToEdit = expenseToEdit
    }

    private var isEditing: Bool {
        expenseToEdit != nil
    }

    private let quickTitles = ["Specialty Coffee ☕️", "Lunch 🥗", "Groceries 🛒", "Cab Ride 🚕", "Dinner 🍕", "Subscription 📱", "Medicines 💊"]

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // ── 1. Native Segmented Switcher (Expense / Income) ───
                    Picker("Transaction Type", selection: $isExpense) {
                        Text("Expense").tag(true)
                        Text("Income").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .onChange(of: isExpense) { _, _ in
                        PlatformFeedback.selection()
                    }

                    // ── 2. Hero Amount Readout with Native Decimal Pad ────
                    VStack(spacing: 6) {
                        Text(isExpense ? "AMOUNT SPENT" : "AMOUNT RECEIVED")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("₹")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(isExpense ? store.accentColor : Color.green)

                            TextField("0", text: $amountString)
                                .font(.system(size: 48, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.primary)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                                .focused($isAmountFocused)
                                .multilineTextAlignment(.leading)
                                .frame(minWidth: 80)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appSecondaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 20)

                    // ── 3. Category Horizontal Strip ───────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SELECT CATEGORY")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(store.allCategories) { cat in
                                    let isSelected = selectedCategory.id == cat.id
                                    Button {
                                        PlatformFeedback.selection()
                                        withAnimation(.appleSpring) {
                                            selectedCategory = cat
                                        }
                                    } label: {
                                        VStack(spacing: 6) {
                                            ZStack {
                                                Circle()
                                                    .fill(isSelected ? cat.color : cat.color.opacity(0.15))
                                                    .frame(width: 46, height: 46)

                                                Image(systemName: cat.sfSymbol)
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundStyle(isSelected ? Color.white : cat.color)
                                            }

                                            Text(cat.displayName)
                                                .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                                                .foregroundStyle(isSelected ? Color.primary : .secondary)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 74)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // ── 4. Quick Title Suggestion Chips & Description ─────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DESCRIPTION & NOTES")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                            .padding(.horizontal, 20)

                        HStack {
                            TextField("Description (e.g. Starbucks, Lunch)", text: $title)
                                .font(.system(size: 15, weight: .medium))
                                .focused($isTitleFocused)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.appSecondaryGroupedBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 0.5)
                                )
                        }
                        .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(quickTitles, id: \.self) { item in
                                    Button {
                                        PlatformFeedback.selection()
                                        title = item
                                    } label: {
                                        Text(item)
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.appSecondaryGroupedBackground)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // ── 5. Date & Time ─────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        DatePicker("Date", selection: $date, displayedComponents: [.date])
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.appSecondaryGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 0.5)
                            )
                            .padding(.horizontal, 20)
                    }

                    // ── 6. Prominent Log Button ───────────────────────────
                    Button(action: saveTransaction) {
                        HStack(spacing: 8) {
                            Image(systemName: isEditing ? "arrow.triangle.2.circlepath" : "plus.circle.fill")
                                .font(.system(size: 17, weight: .bold))
                            Text(isEditing ? "Update Transaction" : "Log \(isExpense ? "Expense" : "Income")")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(isExpense ? store.accentColor : Color.green)
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: (isExpense ? store.accentColor : Color.green).opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                    .disabled((Double(amountString) ?? 0) <= 0)
                    .opacity((Double(amountString) ?? 0) <= 0 ? 0.5 : 1.0)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 20)

                    // ── Delete Button if Editing ──────────────────────────
                    if isEditing {
                        Button(role: .destructive, action: deleteTransaction) {
                            Label("Delete Transaction", systemImage: "trash")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.red)
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .keyboardDismissToolbar()
            .background(Color.appGroupedBackground.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let exp = expenseToEdit {
                    amountString = String(format: "%.0f", exp.amount)
                    title = exp.title
                    selectedCategory = exp.category
                    date = exp.date
                    notes = exp.notes
                    isExpense = exp.isExpense
                    selectedTags = exp.tags
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isAmountFocused = true
                    }
                }
            }
        }
    }

    // ── Save & Delete Actions ─────────────────────────────────────────────

    private func saveTransaction() {
        guard let amount = Double(amountString), amount > 0 else { return }
        let transactionTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? selectedCategory.displayName
            : title.trimmingCharacters(in: .whitespacesAndNewlines)

        PlatformFeedback.success()

        if let existing = expenseToEdit {
            let updated = Expense(
                id: existing.id,
                title: transactionTitle,
                amount: amount,
                category: selectedCategory,
                date: date,
                notes: notes,
                isExpense: isExpense,
                tags: selectedTags
            )
            store.updateExpense(updated)
        } else {
            let newExpense = Expense(
                title: transactionTitle,
                amount: amount,
                category: selectedCategory,
                date: date,
                notes: notes,
                isExpense: isExpense,
                tags: selectedTags
            )
            store.addExpense(newExpense)
        }
        dismiss()
    }

    private func deleteTransaction() {
        guard let exp = expenseToEdit else { return }
        PlatformFeedback.warning()
        store.deleteExpense(id: exp.id)
        dismiss()
    }
}
