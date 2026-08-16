import FlutterMacOS

final class MessageFetchHandler: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "well_spent/messages", binaryMessenger: registrar.messenger)
    let instance = MessageFetchHandler(); channel.setMethodCallHandler(instance.handle)
  }
  private let reader = MessagesDatabaseReader()
  private var pending: [[String: Any]] = []
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method { case "fetchPending": pending = reader.pendingTransactions(); result(pending); case "removePending": if !pending.isEmpty { pending.removeFirst() }; result(nil); default: result(FlutterMethodNotImplemented) }
  }
}
