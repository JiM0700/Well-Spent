import Flutter
import UIKit

final class MessageFetchHandler: NSObject, FlutterPlugin {
  private let defaults = UserDefaults(suiteName: "group.com.wellspent.app")
  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MessageFetchHandler()
    FlutterMethodChannel(name: "well_spent/messages", binaryMessenger: registrar.messenger()).setMethodCallHandler(instance.handle)
  }
  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "fetchPending": result(defaults?.array(forKey: "pending_transactions") ?? [])
    case "removePending":
      var values = defaults?.array(forKey: "pending_transactions") ?? []
      if !values.isEmpty { values.removeFirst(); defaults?.set(values, forKey: "pending_transactions") }
      result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }
}
