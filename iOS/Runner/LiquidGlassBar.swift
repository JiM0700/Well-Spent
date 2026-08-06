import Flutter
import UIKit

final class LiquidGlassBarFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    LiquidGlassBar(frame: frame, messenger: messenger)
  }
}

final class LiquidGlassBar: NSObject, FlutterPlatformView {
  private let root: UIView
  private let channel: FlutterMethodChannel
  private let selectedColor = UIColor.systemBlue
  private var selectedIndex = 0

  init(frame: CGRect, messenger: FlutterBinaryMessenger) {
    root = UIView(frame: frame)
    channel = FlutterMethodChannel(name: "well_spent/liquid-glass-bar", binaryMessenger: messenger)
    super.init()
    build()
  }

  func view() -> UIView { root }

  private func build() {
    root.backgroundColor = .clear
    let glass = glassView()
    root.addSubview(glass)
    glass.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      glass.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      glass.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -74),
      glass.topAnchor.constraint(equalTo: root.topAnchor),
      glass.bottomAnchor.constraint(equalTo: root.bottomAnchor),
    ])

    let stack = UIStackView()
    stack.axis = .horizontal
    stack.alignment = .fill
    stack.distribution = .fillEqually
    stack.spacing = 4
    glass.contentView.addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: glass.contentView.leadingAnchor, constant: 10),
      stack.trailingAnchor.constraint(equalTo: glass.contentView.trailingAnchor, constant: -10),
      stack.topAnchor.constraint(equalTo: glass.contentView.topAnchor, constant: 8),
      stack.bottomAnchor.constraint(equalTo: glass.contentView.bottomAnchor, constant: -8),
    ])

    let titles = ["Overview", "Categories", "Insights", "Settings"]
    let symbols = ["chart.bar", "square.grid.2x2", "waveform.path.ecg", "gearshape"]
    for index in 0..<titles.count {
      let button = UIButton(type: .system)
      button.tag = index
      button.accessibilityLabel = titles[index]
      button.setImage(UIImage(systemName: symbols[index]), for: .normal)
      button.setTitle("\n\(titles[index])", for: .normal)
      button.titleLabel?.font = .systemFont(ofSize: 10, weight: .medium)
      button.tintColor = index == 0 ? selectedColor : .secondaryLabel
      button.addTarget(self, action: #selector(tabPressed(_:)), for: .touchUpInside)
      stack.addArrangedSubview(button)
    }

    let add = UIButton(type: .system)
    add.accessibilityLabel = "Add Expense"
    add.setImage(UIImage(systemName: "plus"), for: .normal)
    add.tintColor = .white
    add.backgroundColor = selectedColor
    add.layer.cornerRadius = 31
    add.layer.borderColor = UIColor.white.withAlphaComponent(0.75).cgColor
    add.layer.borderWidth = 1
    add.addTarget(self, action: #selector(addPressed), for: .touchUpInside)
    root.addSubview(add)
    add.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      add.widthAnchor.constraint(equalToConstant: 62), add.heightAnchor.constraint(equalToConstant: 62),
      add.trailingAnchor.constraint(equalTo: root.trailingAnchor), add.centerYAnchor.constraint(equalTo: root.centerYAnchor),
    ])
  }

  private func glassView() -> UIVisualEffectView {
    if #available(iOS 26.0, *) {
      let view = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
      view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.18)
      if let effect = view.effect as? UIGlassEffect {
        effect.isInteractive = true
        effect.tintColor = UIColor.systemBlue.withAlphaComponent(0.08)
      }
      view.layer.cornerRadius = 32
      view.layer.cornerCurve = .continuous
      view.clipsToBounds = true
      return view
    }
    return UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
  }

  @objc private func tabPressed(_ sender: UIButton) {
    selectedIndex = sender.tag
    channel.invokeMethod("selectTab", arguments: selectedIndex)
    if let stack = sender.superview as? UIStackView {
      for case let button as UIButton in stack.arrangedSubviews {
        button.tintColor = button.tag == selectedIndex ? selectedColor : .secondaryLabel
      }
    }
  }

  @objc private func addPressed() {
    channel.invokeMethod("addExpense", arguments: nil)
  }
}
