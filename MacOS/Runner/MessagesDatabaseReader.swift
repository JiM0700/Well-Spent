import Foundation
import SQLite3

final class MessagesDatabaseReader {
  func pendingTransactions() -> [[String: Any]] {
    let path = NSString(string: "~/Library/Messages/chat.db").expandingTildeInPath
    guard FileManager.default.fileExists(atPath: path) else { return [] }
    var db: OpaquePointer?
    guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil) == SQLITE_OK else { return [] }
    defer { sqlite3_close_v2(db) }

    let sql = "SELECT text, date FROM message WHERE text IS NOT NULL AND is_from_me = 0 ORDER BY date DESC LIMIT 100"
    var stmt: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
    defer { sqlite3_finalize(stmt) }

    var output: [[String: Any]] = []
    let iso = ISO8601DateFormatter()

    while sqlite3_step(stmt) == SQLITE_ROW {
      guard let raw = sqlite3_column_text(stmt, 0) else { continue }
      let text = String(cString: raw)
      guard let amount = Self.amount(in: text), amount > 0, amount < 100_000_000 else { continue }

      // Read actual message date (Apple epoch nanoseconds or seconds since 2001-01-01)
      let rawDate = sqlite3_column_int64(stmt, 1)
      let seconds = Double(rawDate) > 10_000_000_000 ? Double(rawDate) / 1_000_000_000.0 : Double(rawDate)
      let messageDate = Date(timeIntervalSinceReferenceDate: seconds)
      let dateStr = iso.string(from: messageDate)

      let safeTitle = String(text.prefix(80)).trimmingCharacters(in: .whitespacesAndNewlines)
      output.append(["title": safeTitle, "amount": amount, "date": dateStr, "source": "Messages"])
    }
    return output
  }

  private static func amount(in text: String) -> Double? {
    // Supports Indian formatted amounts: ₹1,250.00, Rs. 5,000, $12,345.67
    let pattern = "(?i)(?:inr|rs\\.?|₹|\\$)\\s*([0-9]{1,3}(?:,[0-9]{2,3})*(?:\\.[0-9]{1,2})?|[0-9]+(?:\\.[0-9]{1,2})?)"
    guard let match = try? NSRegularExpression(pattern: pattern).firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
          let range = Range(match.range(at: 1), in: text) else { return nil }
    return Double(text[range].replacingOccurrences(of: ",", with: ""))
  }
}
