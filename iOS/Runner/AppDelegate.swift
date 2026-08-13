import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var urlHandler: URLSchemeHandler?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LiquidGlassBar")!
    registrar.register(LiquidGlassBarFactory(messenger: registrar.messenger()), withId: "well_spent/liquid-glass-bar")
    SiriHandler.register(with: engineBridge.pluginRegistry.registrar(forPlugin: "SiriHandler")!)
    MessageFetchHandler.register(with: engineBridge.pluginRegistry.registrar(forPlugin: "MessageFetchHandler")!)
    let urlChannel = FlutterMethodChannel(name: URLSchemeHandler.channelName, binaryMessenger: registrar.messenger())
    urlHandler = URLSchemeHandler(channel: urlChannel)
    urlChannel.setMethodCallHandler(urlHandler!.handle)
  }

  func openURL(_ url: URL) { urlHandler?.receive(url) }
}
