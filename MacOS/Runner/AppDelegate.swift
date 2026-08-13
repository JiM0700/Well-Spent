import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var messageHandler: MessageFetchHandler?
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    // Flutter's generated registrar is available once the implicit engine is created;
    // registration is also safe to repeat from the plugin registrar.
  }
}
