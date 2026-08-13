import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
  private let group = "group.com.wellspent.app"
  override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); process() }

  private func process() {
    guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
          let provider = item.attachments?.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) else { finish(); return }
    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] value, _ in
      let text = (value as? String) ?? ""
      let transactions = Self.parse(text)
      let defaults = UserDefaults(suiteName: self?.group ?? "group.com.wellspent.app")
      var pending = defaults?.array(forKey: "pending_transactions") as? [[String: Any]] ?? []
      pending.append(contentsOf: transactions)
      defaults?.set(pending, forKey: "pending_transactions")
      DispatchQueue.main.async { self?.finish() }
    }
  }

  static func parse(_ text: String) -> [[String: Any]] {
    let patterns = ["(?i)(?:inr|rs\\.?|₹|\\$)\\s*([0-9]+(?:[,.][0-9]{1,2})?)", "(?i)(?:amount|paid|spent)\\s*[:=-]?\\s*([0-9]+(?:[,.][0-9]{1,2})?)"]
    for pattern in patterns {
      if let match = try? NSRegularExpression(pattern: pattern).firstMatch(in: text, range: NSRange(text.startIndex..., in: text)), let range = Range(match.range(at: 1), in: text), let amount = Double(text[range].replacingOccurrences(of: ",", with: "")) {
        let title = text.split(separator: "\n").first.map(String.init) ?? "Shared transaction"
        return [["title": String(title.prefix(80)), "amount": amount, "date": ISO8601DateFormatter().string(from: Date()), "source": "Share"]]
      }
    }
    return []
  }
  private func finish() { extensionContext?.completeRequest(returningItems: nil) }
}
