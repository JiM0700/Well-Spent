import SwiftUI

public struct SwipeableTransactionRow: View {
    public let expense: Expense
    public let formattedDate: (Date) -> String
    public let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isSwipedOpen: Bool = false
    @Environment(\.colorScheme) var colorScheme

    private let buttonWidth: CGFloat = 76
    private let fullSwipeThreshold: CGFloat = -150

    public init(
        expense: Expense,
        formattedDate: @escaping (Date) -> String,
        onDelete: @escaping () -> Void
    ) {
        self.expense = expense
        self.formattedDate = formattedDate
        self.onDelete = onDelete
    }

    public var body: some View {
        ZStack(alignment: .trailing) {
            // ── Slide to Delete Action Button ─────────────────────────────
            HStack(spacing: 0) {
                Spacer()

                Button(role: .destructive, action: {
                    performDelete()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.red)

                        VStack(spacing: 4) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Delete")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(.white)
                    }
                    .frame(width: max(buttonWidth, -offset))
                }
                .buttonStyle(PlainButtonStyle())
            }

            // ── Main Transaction Card Content ─────────────────────────────
            transactionCardContent
                .offset(x: offset)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 15, coordinateSpace: .local)
                        .onChanged { value in
                            if value.translation.width < 0 {
                                // Dragging left to reveal or delete
                                let dragDistance = value.translation.width
                                if isSwipedOpen {
                                    offset = -buttonWidth + dragDistance
                                } else if dragDistance < -buttonWidth {
                                    let extra = dragDistance + buttonWidth
                                    offset = -buttonWidth + (extra * 0.75)
                                } else {
                                    offset = dragDistance
                                }
                            } else if isSwipedOpen && value.translation.width > 0 {
                                // Dragging right to close
                                offset = min(0, -buttonWidth + value.translation.width)
                            }
                        }
                        .onEnded { value in
                            if value.translation.width < fullSwipeThreshold || value.predictedEndTranslation.width < fullSwipeThreshold {
                                // Full swipe delete
                                performDelete()
                            } else if value.translation.width < -buttonWidth / 2 {
                                // Snap open to reveal delete button
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                    offset = -buttonWidth
                                    isSwipedOpen = true
                                }
                            } else {
                                // Snap closed
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                    offset = 0
                                    isSwipedOpen = false
                                }
                            }
                        }
                )
                .onTapGesture {
                    if isSwipedOpen {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            offset = 0
                            isSwipedOpen = false
                        }
                    }
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func performDelete() {
        PlatformFeedback.warning()
        withAnimation(.easeOut(duration: 0.22)) {
            offset = -500
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            onDelete()
        }
    }

    private var transactionCardContent: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appSecondaryGroupedBackground)
                    .frame(width: 42, height: 42)

                Image(systemName: expense.category.sfSymbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(expense.category.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(expense.category.displayName)
                    Text("•")
                    Text(formattedDate(expense.date))
                    if !expense.notes.isEmpty {
                        Text("•")
                        Text(expense.notes)
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            Text("₹\(String(format: "%.2f", expense.amount))")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.appSecondaryGroupedBackground)
        )
    }
}
