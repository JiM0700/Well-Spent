import Foundation
import SQLite3

final class MessagesDatabaseReader {
  func pendingTransactions() -> [[String: Any]] {
    let path = NSString(string: "~/Library/Messages/chat.db").expandingTildeInPath
    var db: OpaquePointer?; guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { return [] }; defer { sqlite3_close(db) }
    let sql = "SELECT text, date FROM message WHERE text IS NOT NULL AND is_from_me = 0 ORDER BY date DESC LIMIT 200"
    var stmt: OpaquePointer?; guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }; defer { sqlite3_finalize(stmt) }
    var output: [[String: Any]] = []
    while sqlite3_step(stmt) == SQLITE_ROW, let raw = sqlite3_column_text(stmt, 0) {
      let text = String(cString: raw); guard let amount = Self.amount(in: text) else { continue }
      output.append(["title": String(text.prefix(80)), "amount": amount, "date": ISO8601DateFormatter().string(from: Date()), "source": "Messages"])
    }
    return output
  }
  private static func amount(in text: String) -> Double? {
    let pattern = "(?i)(?:inr|rs\\.?|₹|\\$)\\s*([0-9]+(?:[,.][0-9]{1,2})?)"
    guard let match = try? NSRegularExpression(pattern: pattern).firstMatch(in: text, range: NSRange(text.startIndex..., in: text)), let range = Range(match.range(at: 1), in: text) else { return nil }
    return Double(text[range].replacingOccurrences(of: ",", with: ""))
  }
}
