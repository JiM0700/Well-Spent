import Cocoa
import SwiftUI

@objc(AppDelegate)
@main
class AppDelegate: NSObject, NSApplicationDelegate {
  @IBOutlet weak var mainFlutterWindow: NSWindow?
  @IBOutlet weak var applicationMenu: NSMenu?

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    self.mainFlutterWindow?.makeKeyAndOrderFront(nil)
    NSApp.activate()
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      self.mainFlutterWindow?.makeKeyAndOrderFront(nil)
    }
    return true
  }
}
