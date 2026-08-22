import Cocoa
import SwiftUI

@objc(MainFlutterWindow)
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    super.awakeFromNib()

    let hostingController = NSHostingController(rootView: WellSpentRootView())
    self.contentViewController = hostingController
    self.minSize = NSSize(width: 860, height: 580)
    self.setFrameAutosaveName("WellSpentMainWindowAutosave")

    // Only set default frame if no saved position exists
    if self.frame.size.width < 860 || self.frame.size.height < 580 {
      let defaultFrame = NSRect(x: 0, y: 0, width: 1050, height: 720)
      self.setFrame(defaultFrame, display: true)
      self.center()
    }

    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert([.fullSizeContentView, .titled, .closable, .miniaturizable, .resizable])
    self.isMovableByWindowBackground = true
  }
}
