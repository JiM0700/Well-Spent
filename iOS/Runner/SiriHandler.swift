import Foundation
import Flutter
import SQLite3

/// Small native bridge used by App Intents and Flutter. It intentionally uses
/// the same schema as DatabaseService so Siri does not need to launch Flutter.
final class SiriHandler: NSObject, FlutterPlugin {
  static let channelName = "well_spent/siri"
  private var db: OpaquePointer?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SiriHandler()
    FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger()).setMethodCallHandler(instance.handle)
  }

  private func database() -> OpaquePointer? {
    if db != nil { return db }
    let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
    guard let library = paths.first else { return nil }
    let path = (library as NSString).appendingPathComponent("LocalDatabase/well_spent.db")
    if sqlite3_open(path, &db) != SQLITE_OK { db = nil }
    return db
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "addTransaction":
      guard let args = call.arguments as? [String: Any], let amount = args["amount"] as? Double,
            amount > 0, let title = args["title"] as? String, !title.trimmingCharacters(in: .whitespaces).isEmpty,
            let database = database() else { result(FlutterError(code: "DATABASE", message: "Unable to open Well Spent database", details: nil)); return }
      let sql = "INSERT INTO expenses (title, amount, category, date, note, type, expenseKind) VALUES (?, ?, ?, ?, '', 'expense', 'variable')"
      var statement: OpaquePointer?
      guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else { result(FlutterError(code: "SQL", message: "Unable to prepare insert", details: nil)); return }
      defer { sqlite3_finalize(statement) }
      sqlite3_bind_text(statement, 1, (title as NSString).utf8String, -1, nil)
      sqlite3_bind_double(statement, 2, amount)
      let category = ((args["category"] as? String) ?? "other") as NSString
      sqlite3_bind_text(statement, 3, category.utf8String, -1, nil)
      sqlite3_bind_text(statement, 4, ISO8601DateFormatter().string(from: Date()), -1, nil)
      guard sqlite3_step(statement) == SQLITE_DONE else { result(FlutterError(code: "SQL", message: "Unable to add transaction", details: nil)); return }
      result(["id": sqlite3_last_insert_rowid(database), "amount": amount, "title": title])
    case "getBudget":
      result(setting("monthly_budget") ?? 1000.0)
    case "getSpending":
      result(spending(since: (call.arguments as? [String: Any])?["since"] as? String))
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func setting(_ key: String) -> Double? {
    guard let database = database() else { return nil }; var statement: OpaquePointer?
    sqlite3_prepare_v2(database, "SELECT value FROM settings WHERE key = ?", -1, &statement, nil); defer { sqlite3_finalize(statement) }
    sqlite3_bind_text(statement, 1, (key as NSString).utf8String, -1, nil)
    guard sqlite3_step(statement) == SQLITE_ROW, let text = sqlite3_column_text(statement, 0) else { return nil }
    return Double(String(cString: text))
  }

  private func spending(since: String?) -> [String: Any] {
    guard let database = database() else { return ["total": 0.0, "count": 0] }
    var statement: OpaquePointer?; let sql = "SELECT COALESCE(SUM(amount), 0), COUNT(*) FROM expenses WHERE type = 'expense' AND (? IS NULL OR date >= ?)"
    sqlite3_prepare_v2(database, sql, -1, &statement, nil); defer { sqlite3_finalize(statement) }
    if let since { sqlite3_bind_text(statement, 1, (since as NSString).utf8String, -1, nil); sqlite3_bind_text(statement, 2, (since as NSString).utf8String, -1, nil) } else { sqlite3_bind_null(statement, 1); sqlite3_bind_null(statement, 2) }
    guard sqlite3_step(statement) == SQLITE_ROW else { return ["total": 0.0, "count": 0] }
    return ["total": sqlite3_column_double(statement, 0), "count": sqlite3_column_int(statement, 1)]
  }
}
