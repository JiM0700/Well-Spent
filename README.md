# Well Spent 🍏

**Well Spent** is an offline-first, private personal finance and expense tracking application crafted with **100% Pure Native Apple SwiftUI** (iOS 17+).

Designed from the ground up to adhere to Apple's Human Interface Guidelines (HIG), Well Spent delivers tactile responsiveness, fluid physics, authentic `.ultraThinMaterial` Liquid Glass aesthetics, and offline local data privacy.

---

## ✨ Features & Highlights

### 📱 100% Pure Native SwiftUI Architecture
- **Zero Third-Party UI Dependencies**: Built entirely using first-party Apple frameworks: `SwiftUI`, `import Charts`, `Combine`, `UIKit` (Taptic Engine haptics), and `Foundation`.
- **High-Performance Rendering**: Fluid $120\text{Hz}$ ProMotion support with continuous spring animations (`.spring(response:dampingFraction:)`).
- **iOS 17+ Modern APIs**: Utilizes `ContentUnavailableView`, `SectorMark` donut visualizers, `.safeAreaInset()`, and `.buttonStyle(.borderedProminent)`.

### 🏝️ Apple Dual-Island Floating Tab Bar
- **Continuous Segmented Sliding Track**: Mimics `UISegmentedControl` thumb kinematics with spring interpolation across tabs.
- **Interactive Liquid Glass Glow Aura**: A dynamic `RadialGradient` light aura illuminates underneath the active tab button.
- **Dual-Sheen Refractive Glass Rims**: Specular meniscus highlights along the leading edges of the `.ultraThinMaterial` capsule.
- **Long-Press Water Bubble Physics**: Holding a tab button expands the liquid water-droplet lens (`scaleEffect(1.12, 1.08)`) with internal caustic highlights and a rigid Taptic Engine pulse (`UIImpactFeedbackGenerator`).
- **Dedicated Floating Action Pod**: An independent solid accent island with glowing corona shadow for instant transaction entry.

### 🎨 Pitch Black OLED & App-Wide Color System
- **True Pitch Black (`#000000`) Dark Mode**: Pixels turn completely off on OLED Super Retina XDR displays.
- **Crisp Apple System Grouped Light Mode**: Balanced neutral hierarchy using Apple standard system backgrounds.
- **System / Dark / Light Appearance Toggle**: Instant runtime switching in **Settings $\rightarrow$ APPEARANCE & THEME**.
- **7 Curated Apple System Accent Colors**:
  - 🍏 Apple Green (Default)
  - 🔵 Apple Blue
  - 🟣 Apple Indigo
  - 🔮 Apple Purple
  - 🍊 Apple Orange
  - 🌊 Apple Teal
  - 🌸 Apple Pink
  - Dynamically transforms active tab glyphs, floating action pods, progress meters, category filter chips, and interactive buttons app-wide.

### 📊 Insights & Visual Analytics
- **Today's Pulse & Monthly Envelope**: Instant day-wise burn rate vs. total budget with percentage badges and dynamic progress meters.
- **Apple Swift Charts Spend Distribution**: Native `SectorMark` donut chart breaking down expenses across categories.
- **Projected Velocity Forecasting**: Real-time month-end spend estimation and daily average burn metrics.
- **Fixed Commitments & Recurring Bills**: Track recurring subscriptions, maintenance, and bills with one-tap payment toggle checkboxes.
- **Envelope Budgeting**: Custom monthly budget targets for individual categories (Food & Dining, Transport, Utilities, Entertainment, Health, Shopping, Housing, Other) with alert thresholds.

### 🔒 Privacy-First Local Storage & Portability
- **100% Offline**: No accounts, tracking, or cloud servers required. All transactions are serialized to local JSON storage atomically.
- **CSV Data Portability**: Export all transaction history to CSV or import existing CSV datasets.
- **Data Management**: Safe **"Delete All Data"** destructive action protected by Apple centered confirmation modal dialogs and warning haptics.

---

## 🏗️ Project Architecture

```
Well-Spent/
├── ios/
│   ├── Runner/
│   │   ├── SwiftUI/
│   │   │   ├── Models/
│   │   │   │   └── Expense.swift              # Expense & Category models, SF Symbols & colors
│   │   │   ├── Services/
│   │   │   │   └── ExpenseStore.swift         # ObservableObject store, JSON persistence, metrics
│   │   │   └── Views/
│   │   │       ├── WellSpentRootView.swift    # Root tab navigation container & theme provider
│   │   │       ├── OverviewView.swift         # Dashboard pulse, search bar, filter chips, activity feed
│   │   │       ├── CategoriesView.swift       # Category envelope targets & budget progress cards
│   │   │       ├── InsightsView.swift         # Swift Charts donut, velocity forecast & recurring bills
│   │   │       ├── SettingsView.swift         # Appearance picker, accent palette, CSV import/export, reset
│   │   │       ├── QuickAddView.swift         # Sheet modal with centered amount and category selector
│   │   │       └── Components/
│   │   │           └── DualIslandTabBar.swift # Dual-island dock with liquid glow & water bubble physics
│   │   ├── AppDelegate.swift                  # Pure SwiftUI window scene hosting
│   │   └── SceneDelegate.swift                # Window lifecycle management
│   └── Runner.xcodeproj/                      # Configured with IPHONEOS_DEPLOYMENT_TARGET = 17.0
└── README.md
```

---

## 🚀 Building & Running Locally

### Requirements
- **macOS** with **Xcode 15+** installed.
- **iOS 17.0+ Simulator** (e.g., iPhone 15 / 16 / 17 or iPhone 14 Pro).

### Build & Run via Xcode / Command Line

1. Open the workspace in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Or build and launch directly on the iOS Simulator from terminal:
   ```bash
   # Build for iOS Simulator
   xcodebuild -workspace ios/Runner.xcworkspace \
              -scheme Runner \
              -destination 'platform=iOS Simulator,name=iPhone 17' \
              build

   # Launch on booted simulator
   xcrun simctl launch booted com.example.wellSpent
   ```

---

## 📄 License
MIT License. Created with pure SwiftUI for private, local financial clarity.
