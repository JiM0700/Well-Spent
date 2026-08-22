import Cocoa
import SwiftUI

@objc(MainFlutterWindow)
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let hostingController = NSHostingController(rootView: WellSpentRootView())
    let windowFrame = NSRect(x: 0, y: 0, width: 1050, height: 720)
    self.contentViewController = hostingController
    self.setFrame(windowFrame, display: true)
    self.minSize = NSSize(width: 860, height: 580)
    self.center()

    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert([.fullSizeContentView, .titled, .closable, .miniaturizable, .resizable])
    self.isMovableByWindowBackground = true

    super.awakeFromNib()
    self.makeKeyAndOrderFront(nil)
  }
}
