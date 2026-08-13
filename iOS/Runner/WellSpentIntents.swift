import AppIntents
import Foundation
import SQLite3

@available(iOS 16.0, macOS 13.0, *)
struct AddExpenseIntent: AppIntent {
  static var title: LocalizedStringResource = "Add expense"
  static var description = IntentDescription("Add an expense to Well Spent.")
  @Parameter(title: "Amount") var amount: Double
  @Parameter(title: "Title") var title: String
  func perform() async throws -> some IntentResult & ReturnsValue<String> {
    let result = try await SiriIntentDatabase.add(amount: amount, title: title)
    return .result(value: result)
  }
}

@available(iOS 16.0, macOS 13.0, *)
struct WellSpentShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] { [AppShortcut(intent: AddExpenseIntent(), phrases: ["Add an expense in \(.applicationName)", "Record spending in \(.applicationName)"], shortTitle: "Add expense", systemImageName: "plus.circle")] }
}

enum SiriIntentDatabase {
  static func add(amount: Double, title: String) async throws -> String {
    guard amount > 0, !title.trimmingCharacters(in: .whitespaces).isEmpty else { throw NSError(domain: "WellSpent", code: 1, userInfo: [NSLocalizedDescriptionKey: "Enter a positive amount and a title."]) }
    // App Intents and Flutter use the same SQLite schema. This lightweight path
    // is replaced by the app-group path when that entitlement is configured.
    let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0] + "/LocalDatabase/well_spent.db"
    var db: OpaquePointer?; guard sqlite3_open(path, &db) == SQLITE_OK else { throw NSError(domain: "WellSpent", code: 2) }; defer { sqlite3_close(db) }
    var stmt: OpaquePointer?; sqlite3_prepare_v2(db, "INSERT INTO expenses (title,amount,category,date,note,type,expenseKind) VALUES (?,?,?,?,'','expense','variable')", -1, &stmt, nil); defer { sqlite3_finalize(stmt) }
    sqlite3_bind_text(stmt, 1, (title as NSString).utf8String, -1, nil); sqlite3_bind_double(stmt, 2, amount); sqlite3_bind_text(stmt, 3, ("other" as NSString).utf8String, -1, nil); sqlite3_bind_text(stmt, 4, (ISO8601DateFormatter().string(from: Date()) as NSString).utf8String, -1, nil)
    guard sqlite3_step(stmt) == SQLITE_DONE else { throw NSError(domain: "WellSpent", code: 3) }; return "Added \(title)"
  }
}
