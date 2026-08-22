import Cocoa
import SwiftUI

@objc(AppDelegate)
@main
class AppDelegate: NSObject, NSApplicationDelegate {
  @IBOutlet weak var mainFlutterWindow: NSWindow?

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    self.mainFlutterWindow?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
}
