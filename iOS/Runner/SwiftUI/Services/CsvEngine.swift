import Foundation

/// Universal CSV engine supporting arbitrary column ordering, quotes, multi-format dates, and currency tokens
public final class CsvEngine {

    public static func exportCsv(from expenses: [Expense]) -> String {
        var csv = "date,type,title,category,amount,notes\n"
        let formatter = ISO8601DateFormatter()
        for exp in expenses {
            let dateStr = formatter.string(from: exp.date)
            let typeStr = exp.isExpense ? "expense" : "income"
            let safeTitle = exp.title.replacingOccurrences(of: "\"", with: "\"\"")
            let safeNotes = exp.notes.replacingOccurrences(of: "\"", with: "\"\"")
            let catStr = exp.category.rawValue
            let amtStr = String(format: "%.2f", exp.amount)
            csv += "\"\(dateStr)\",\"\(typeStr)\",\"\(safeTitle)\",\"\(catStr)\",\(amtStr),\"\(safeNotes)\"\n"
        }
        return csv
    }

    public static func importCsv(content: String) -> [Expense] {
        let rows = parseCsvRows(content: content)
        guard !rows.isEmpty else { return [] }

        let headerRow = rows[0].map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

        var dateIdx = -1
        var typeIdx = -1
        var titleIdx = -1
        var categoryIdx = -1
        var amountIdx = -1
        var notesIdx = -1
        var isHeaderDetected = false

        for (idx, header) in headerRow.enumerated() {
            if header.contains("date") || header.contains("time") {
                dateIdx = idx
                isHeaderDetected = true
            } else if header == "type" || header.contains("kind") {
                typeIdx = idx
                isHeaderDetected = true
            } else if header.contains("title") || header.contains("desc") || header.contains("name") || header.contains("item") {
                titleIdx = idx
                isHeaderDetected = true
            } else if header.contains("cat") {
                categoryIdx = idx
                isHeaderDetected = true
            } else if header.contains("amount") || header.contains("cost") || header.contains("price") || header.contains("total") || header.contains("val") {
                amountIdx = idx
                isHeaderDetected = true
            } else if header.contains("note") || header.contains("memo") || header.contains("comment") {
                notesIdx = idx
                isHeaderDetected = true
            }
        }

        _ = typeIdx // Silence unused warning

        let dataRows = isHeaderDetected ? Array(rows.dropFirst()) : rows
        var parsedExpenses: [Expense] = []

        for row in dataRows where !row.isEmpty {
            // Extract Amount
            var amount: Double = 0.0
            if amountIdx >= 0 && amountIdx < row.count {
                amount = parseAmount(row[amountIdx])
            } else {
                for cell in row {
                    let a = parseAmount(cell)
                    if a > 0 {
                        amount = a
                        break
                    }
                }
            }
            guard amount > 0 else { continue }

            // Extract Title
            var title = "Imported Transaction"
            if titleIdx >= 0 && titleIdx < row.count && !row[titleIdx].trimmingCharacters(in: .whitespaces).isEmpty {
                title = row[titleIdx]
            } else {
                for cell in row {
                    let c = cell.trimmingCharacters(in: .whitespaces)
                    if parseAmount(c) == 0 && parseDate(c) == nil && c.lowercased() != "expense" && c.lowercased() != "income" && !c.isEmpty {
                        title = c
                        break
                    }
                }
            }

            // Extract Category
            var category: ExpenseCategory = .other
            if categoryIdx >= 0 && categoryIdx < row.count {
                category = ExpenseCategory.from(string: row[categoryIdx])
            } else {
                for cell in row {
                    let cat = ExpenseCategory.from(string: cell)
                    if cat != .other {
                        category = cat
                        break
                    }
                }
            }

            // Extract Date
            var date = Date()
            if dateIdx >= 0 && dateIdx < row.count {
                if let d = parseDate(row[dateIdx]) {
                    date = d
                }
            } else {
                for cell in row {
                    if let d = parseDate(cell) {
                        date = d
                        break
                    }
                }
            }

            // Extract Notes
            var notes = ""
            if notesIdx >= 0 && notesIdx < row.count {
                notes = row[notesIdx]
            }

            let expense = Expense(
                title: title,
                amount: amount,
                category: category,
                date: date,
                notes: notes,
                isExpense: true
            )
            parsedExpenses.append(expense)
        }

        return parsedExpenses
    }

    private static func parseCsvRows(content: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false

        let chars = Array(content)
        var i = 0

        while i < chars.count {
            let char = chars[i]
            if char == "\"" {
                if inQuotes && i + 1 < chars.count && chars[i + 1] == "\"" {
                    currentField.append("\"")
                    i += 1
                } else {
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else if (char == "\r" || char == "\n") && !inQuotes {
                if char == "\r" && i + 1 < chars.count && chars[i + 1] == "\n" {
                    i += 1
                }
                currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
                if !currentRow.allSatisfy({ $0.isEmpty }) {
                    rows.append(currentRow)
                }
                currentRow = []
            } else {
                currentField.append(char)
            }
            i += 1
        }

        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
            if !currentRow.allSatisfy({ $0.isEmpty }) {
                rows.append(currentRow)
            }
        }
        return rows
    }

    private static func parseAmount(_ string: String) -> Double {
        let clean = string.replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(clean) ?? 0.0
    }

    private static func parseDate(_ string: String) -> Date? {
        let clean = string.replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }

        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: clean) { return d }

        let isoFull = ISO8601DateFormatter()
        isoFull.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = isoFull.date(from: clean) { return d }

        let formats = [
            "yyyy-MM-dd",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss",
            "dd/MM/yyyy",
            "MM/dd/yyyy",
            "dd-MM-yyyy",
            "yyyy/MM/dd",
            "dd MMM yyyy",
            "MMM dd, yyyy"
        ]
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for fmt in formats {
            df.dateFormat = fmt
            if let d = df.date(from: clean) {
                return d
            }
        }
        return nil
    }
}
