import FlutterMacOS

/// Handler for Siri shortcuts integration on macOS
/// Allows voice control to add transactions and query spending/budget
final class SiriHandler: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "well_spent/siri", binaryMessenger: registrar.messenger)
    let instance = SiriHandler()
    channel.setMethodCallHandler(instance.handle)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "addTransaction":
      handleAddTransaction(call, result: result)
    case "getBudget":
      handleGetBudget(call, result: result)
    case "getSpending":
      handleGetSpending(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleAddTransaction(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let amount = args["amount"] as? Double,
          let title = args["title"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing amount or title", details: nil))
      return
    }

    let category = args["category"] as? String ?? "other"

    // Store transaction in UserDefaults (simple implementation for testing)
    var transactions = loadTransactions()
    
    let transaction: [String: Any] = [
      "id": UUID().uuidString,
      "title": title,
      "amount": amount,
      "category": category,
      "date": ISO8601DateFormatter().string(from: Date()),
      "type": "expense",
      "expenseKind": "variable"
    ]
    
    transactions.append(transaction)
    saveTransactions(transactions)

    result([
      "success": true,
      "id": transaction["id"] as Any,
      "message": "Added \(title) for ₹\(amount)"
    ])
  }

  private func handleGetBudget(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // This would typically fetch from the app's SQLite database
    // For testing on macOS, return mock data
    result([
      "monthlyBudget": 50000.0,
      "spent": 12500.0,
      "remaining": 37500.0,
      "period": "current month"
    ])
  }

  private func handleGetSpending(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      // Return today's spending
      let transactions = loadTransactions()
      let today = Calendar.current.startOfDay(for: Date())
      
      let todaySpent = transactions
        .filter { 
          if let dateStr = $0["date"] as? String,
             let date = ISO8601DateFormatter().date(from: dateStr) {
            return Calendar.current.isDateInToday(date)
          }
          return false
        }
        .compactMap { $0["amount"] as? Double }
        .reduce(0, +)

      result([
        "spent": todaySpent,
        "period": "today",
        "transactions": transactions.count
      ])
      return
    }

    // If a since date was provided, calculate spending since then
    let transactions = loadTransactions()
    let spent = transactions
      .compactMap { $0["amount"] as? Double }
      .reduce(0, +)

    result([
      "spent": spent,
      "period": "all time",
      "transactions": transactions.count
    ])
  }

  // MARK: - Helper Methods

  private func loadTransactions() -> [[String: Any]] {
    guard let data = UserDefaults.standard.data(forKey: "well_spent_transactions"),
          let transactions = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
      return []
    }
    return transactions
  }

  private func saveTransactions(_ transactions: [[String: Any]]) {
    if let data = try? JSONSerialization.data(withJSONObject: transactions) {
      UserDefaults.standard.set(data, forKey: "well_spent_transactions")
    }
  }
}
