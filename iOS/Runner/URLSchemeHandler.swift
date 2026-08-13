import Foundation
import Flutter

final class URLSchemeHandler: NSObject {
  static let channelName = "well_spent/url_scheme"
  private weak var channel: FlutterMethodChannel?
  private var initialURL: URL?

  init(channel: FlutterMethodChannel) { self.channel = channel; super.init() }
  func receive(_ url: URL) { initialURL = url; send(url) }
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "getInitialURL", let url = initialURL { send(url); initialURL = nil }
    result(nil)
  }
  private func send(_ url: URL) {
    guard url.scheme?.lowercased() == "wellspent", url.host?.lowercased() == "add" else { return }
    var values = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.reduce(into: [String: String]()) { $0[$1.name] = $1.value } ?? [:]
    values["amount"] = values["amount"]?.replacingOccurrences(of: ",", with: "")
    channel?.invokeMethod("transaction", arguments: values)
  }
}
