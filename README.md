# Well Spent 🍏

**Well Spent** is an offline-first, private personal finance and expense tracking application crafted with **100% Pure Native Apple SwiftUI** for both **macOS (Sonoma / Sequoia)** and **iOS (iOS 17+)**.

Designed from the ground up to adhere to Apple's Human Interface Guidelines (HIG), Well Spent delivers tactile responsiveness, fluid physics, authentic `.ultraThinMaterial` **Liquid Glass** aesthetics across all components, and offline local data privacy.

---

## ✨ Features & Highlights

### 💻 macOS Desktop Experience (Apple Music Style Sidebar)
- **Vibrant Translucent Left Sidebar**: Inspired by the native macOS Apple Music and TV apps, featuring continuous material blur, grouped sections (Library & System), item count badges, and an integrated mini-envelope budget gauge.
- **Widescreen Desktop Responsive Grids**: Multi-column responsive Liquid Glass cards for Overview metrics, Category envelopes, and side-by-side Swift Charts.
- **Symmetric 2-Column Settings Grid**: Balanced $50\% / 50\%$ layout with consistent card heights, border alignments, and uniform spacing.
- **Full Window Dragging & Transparent Titlebar**: Unified titlebar with native window traffic lights and integrated toolbar actions with keyboard shortcuts (`⌘N` for Quick Add).

### 📱 iOS Experience (Apple Dual-Island Floating Dock)
- **Continuous Segmented Sliding Track**: Mimics `UISegmentedControl` thumb kinematics with spring interpolation across tabs.
- **Interactive Liquid Glass Glow Aura**: A dynamic `RadialGradient` light aura illuminates underneath the active tab button.
- **Dual-Sheen Refractive Glass Rims**: Specular meniscus highlights along the leading edges of the `.ultraThinMaterial` capsule with authentic live optical refraction of content scrolling underneath.
- **Long-Press Water Bubble Physics**: Holding a tab button expands the liquid water-droplet lens (`scaleEffect(1.12, 1.08)`) with internal caustic highlights and a rigid Taptic Engine pulse (`UIImpactFeedbackGenerator`).
- **Dedicated Floating Action Pod**: An independent solid accent island with glowing corona shadow for instant transaction entry.

### 🧩 iOS & macOS WidgetKit Widgets (Today's Pulse)
- **Multi-Family Widget Support**:
  - **Small Square (`.systemSmall`)**: Compact home screen & macOS desktop widget featuring a large spend amount, daily burn percentage, glowing progress bar, remaining daily allowance, and ambient accent glow.
  - **Medium Wide (`.systemMedium`)**: Split-view widget with today's financial pulse meter on the left, and a live stream of today's latest transactions with category icons on the right.
  - **Lock Screen & StandBy Accessories (iOS 16+)**: `.accessoryRectangular` (spend & progress meter), `.accessoryCircular` (circular wallet gauge), and `.accessoryInline` for glancing at expenses directly from the lock screen.
- **Shared App Group Storage**: Real-time synchronization via `WidgetDataManager` and `UserDefaults(suiteName: "group.com.example.wellSpent")`, triggering immediate widget timeline reloads whenever expenses are added or updated.

### 🧪 Comprehensive Liquid Glass Design System
- **All-Component Liquid Glass Aesthetics**: Cards, buttons, toggles, search bars, category chips, and stat boxes feature `.ultraThinMaterial` backdrop blur, specular meniscus borders with gradient rim highlights, interactive hover glow auras, and spring scale micro-animations.
- **Liquid Glass Buttons & Toggles**: Custom `LiquidGlassButtonStyle` and `LiquidGlassToggleStyle` with glowing active states and taptic/haptic feedback.

### 🎨 Pitch Black OLED & App-Wide Color System
- **True Pitch Black (`#000000`) Dark Mode**: Pixels turn completely off on OLED Super Retina XDR displays and Pro Display XDR.
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
  - Dynamically transforms active glyphs, action pods, progress meters, category filter chips, and interactive buttons app-wide.

### 📊 Insights & Visual Analytics
- **Today's Pulse & Monthly Envelope**: Instant day-wise burn rate vs. total budget with percentage badges and dynamic progress meters.
- **Apple Swift Charts Spend Distribution**: Native `SectorMark` donut chart breaking down expenses across categories.
- **Projected Velocity Forecasting**: Real-time month-end spend estimation and daily average burn metrics.
- **Fixed Commitments & Recurring Bills**: Track recurring subscriptions, maintenance, and bills with one-tap payment toggle checkboxes.
- **Envelope Budgeting**: Custom monthly budget targets for individual categories (Food & Dining, Transport, Utilities, Entertainment, Health, Shopping, Housing, Other) with alert thresholds.

### 🔒 Privacy-First Local Storage & Portability
- **100% Offline**: No accounts, tracking, or cloud servers required. All transactions are serialized to local JSON storage atomically.
- **Universal Header-Aware CSV Engine**: 100% two-way interoperability with PWA, Web, and mobile CSV formats (`date,type,title,category,amount,notes`).
- **macOS App Sandbox File Support**: Native `NSOpenPanel` and `.fileImporter` with user-selected read-write permissions.
- **Data Management**: Safe **"Delete All Data"** destructive action protected by Apple centered confirmation modal dialogs and warning haptics.

---

## 📅 Delivery Phases & Implementation Roadmap

```
Phase 1: Pure SwiftUI Core Engine   ───▶ [100% COMPLETE]
Phase 2: Liquid Glass Design System  ───▶ [100% COMPLETE]
Phase 3: iOS Floating Capsule Dock   ───▶ [100% COMPLETE]
Phase 4: macOS Apple Music Sidebar   ───▶ [100% COMPLETE]
Phase 5: Universal CSV & Portability ───▶ [100% COMPLETE]
Phase 6: Multi-Family WidgetKit      ───▶ [100% COMPLETE]
Phase 7: Future Advanced Roadmap     ───▶ [PLANNED]
```

### ✅ Phase 1: Pure Native SwiftUI Core Architecture (Complete)
- [x] Converted entire application layer to 100% Pure Native Apple SwiftUI.
- [x] Built central `ExpenseStore` (`ObservableObject`) with thread-safe atomic JSON file persistence.
- [x] Designed `Expense` and `ExpenseCategory` data models with SF Symbol identifiers and palette tokens.
- [x] Implemented recurring bills manager and dynamic monthly budget burn calculations.
- [x] Configured native SwiftUI window scene hosting (`AppDelegate.swift`, `SceneDelegate.swift`, `MainFlutterWindow.swift`).

### ✅ Phase 2: Liquid Glass Design System & Tactile Physics (Complete)
- [x] Engineered authentic `.ultraThinMaterial` optical backdrop blur and specular refraction.
- [x] Added dual-layer caustic edge strokes with top-edge meniscus highlight crests.
- [x] Created `LiquidGlassCard`, `LiquidGlassButtonStyle`, and `LiquidGlassToggleStyle` view modifiers.
- [x] Integrated cross-platform haptics (`UIImpactFeedbackGenerator` on iOS, `NSHapticFeedbackManager` on macOS).
- [x] Implemented spring-damped micro-interactions and interactive press physics.

### ✅ Phase 3: iOS Experience & Floating Dock (Complete)
- [x] Built 5-slot Liquid Glass floating dock (`DualIslandTabBar.swift`) with optical corner refraction.
- [x] Continuous sliding thumb track with spring kinematic interpolation.
- [x] Interactive `RadialGradient` active tab glow aura.
- [x] Long-press liquid water droplet lens expansion with specular caustics.
- [x] Dedicated floating `＋` action pod for instant expense entry.
- [x] True Pitch Black (`#000000`) OLED dark mode and Apple grouped light mode.
- [x] 7-color system accent palette with live theme switching.
- [x] Non-wrapping Apple 26/27 period switcher capsule (`Monthwise` / `Daywise`).

### ✅ Phase 4: macOS Desktop Transformation (Complete)
- [x] Translucent vibrant left sidebar navigation inspired by macOS Apple Music and Apple TV apps.
- [x] Grouped sections (`Library`: Home, Budgets, Trends; `System`: Settings) with item count badges.
- [x] Integrated sidebar footer mini-envelope budget gauge.
- [x] Multi-column responsive desktop grids for Home, Budgets, and Swift Charts.
- [x] Redesigned macOS Settings page with symmetrical $50\% / 50\%$ two-column grid.
- [x] Full window dragging, transparent titlebar, and keyboard shortcuts (`⌘N`).

### ✅ Phase 5: Universal CSV Engine & Data Portability (Complete)
- [x] Built header-aware dynamic CSV tokenizer supporting arbitrary column orders.
- [x] Solved PWA CSV mismatch (`date,type,title,category,amount`).
- [x] Multi-format date parser (ISO8601, timestamps, `yyyy-MM-dd`, `dd/MM/yyyy`, locale formats).
- [x] Category alias normalizer (`ExpenseCategory.from(string:)`).
- [x] Added `com.apple.security.files.user-selected.read-write` to macOS sandbox entitlements.
- [x] Cross-platform native `.fileImporter` with security-scoped resource access.

### ✅ Phase 6: Multi-Family WidgetKit Extensions (Complete)
- [x] Created `WidgetDataManager` for App Group container synchronization (`group.com.example.wellSpent`).
- [x] Built `TodayExpenseWidget.swift` with dynamic timeline provider and refresh scheduling.
- [x] **Small Widget (`.systemSmall`)**: Hero spend metric, daily allowance progress bar, and ambient glow.
- [x] **Medium Widget (`.systemMedium`)**: Split-view with today's burn gauge and live recent transaction feed.
- [x] **Lock Screen & StandBy Accessories**: `.accessoryRectangular`, `.accessoryCircular`, and `.accessoryInline`.
- [x] Auto-trigger `WidgetCenter.shared.reloadAllTimelines()` on any data modification.

### 🔮 Phase 7: Future Roadmap & Advanced Enhancements (Upcoming)
- [ ] **Interactive Widget Buttons (iOS 17+)**: One-tap quick expense logging directly from the Home Screen.
- [ ] **watchOS Companion App**: Standalone Apple Watch app with complication gauges for today's burn rate.
- [ ] **Siri Shortcuts & App Intents**: "Hey Siri, log 350 rupees for lunch".
- [ ] **Multi-Currency & Travel Mode**: Automatic currency conversion with offline cached exchange rates.
- [ ] **Predictive AI Cashflow Modeling**: Local on-device ML spend forecasting and anomaly alerts.

---

## 🏗️ Project Architecture

```
Well-Spent/
├── ios/
│   ├── Runner/
│   │   ├── SwiftUI/
│   │   │   ├── Models/
│   │   │   │   └── Expense.swift              # Expense & Category models, SF Symbols & normalizer
│   │   │   ├── Services/
│   │   │   │   ├── ExpenseStore.swift         # ObservableObject store, JSON persistence, metrics
│   │   │   │   ├── CsvEngine.swift            # Universal dynamic CSV parser, date engine & exporter
│   │   │   │   ├── PlatformHelpers.swift      # Cross-platform haptics & dynamic semantic colors
│   │   │   │   └── WidgetDataManager.swift    # Shared App Group widget data manager
│   │   │   └── Views/
│   │   │       ├── WellSpentRootView.swift    # Adaptive platform routing (macOS vs iOS)
│   │   │       ├── MacDesktopRootView.swift   # macOS Apple Music style sidebar & desktop canvas
│   │   │       ├── OverviewView.swift         # Dashboard pulse, search bar, filter chips, activity feed
│   │   │       ├── CategoriesView.swift       # Category envelope targets & budget progress cards
│   │   │       ├── InsightsView.swift         # Swift Charts donut, velocity forecast & recurring bills
│   │   │       ├── SettingsView.swift         # Appearance picker, accent palette, CSV import/export, reset
│   │   │       ├── QuickAddView.swift         # Modal with centered amount and category selector
│   │   │       └── Components/
│   │   │           ├── DualIslandTabBar.swift # iOS 5-slot dock with liquid glow & water bubble physics
│   │   │           ├── LiquidGlassStyles.swift# Reusable Liquid Glass card, button & toggle modifiers
│   │   │           └── TodayExpenseWidget.swift # WidgetKit views (Small, Medium, Lock Screen)
│   │   ├── AppDelegate.swift                  # Pure SwiftUI window scene hosting
│   │   └── SceneDelegate.swift                # Window lifecycle management
│   └── Runner.xcodeproj/                      # Configured with IPHONEOS_DEPLOYMENT_TARGET = 17.0
├── macos/
│   ├── Runner/
│   │   ├── MainFlutterWindow.swift            # NSHostingController widescreen desktop window host
│   │   ├── AppDelegate.swift                  # macOS application delegate
│   │   ├── DebugProfile.entitlements          # App Sandbox entitlements (user-selected file read/write)
│   │   ├── Release.entitlements               # App Sandbox entitlements
│   │   └── SwiftUI -> ../../ios/Runner/SwiftUI# Symlinked shared SwiftUI codebase
│   └── Runner.xcodeproj/                      # Configured with MACOSX_DEPLOYMENT_TARGET = 14.0
└── README.md
```

---

## 🚀 Building & Running Locally

### Requirements
- **macOS** with **Xcode 15+** installed.
- **iOS 17.0+ Simulator** (e.g., iPhone 15 / 16 / 17 or iPhone 14 Pro).

### Build & Run via Xcode / Command Line

1. **macOS Desktop App**:
   ```bash
   xcodebuild -workspace macos/Runner.xcworkspace \
              -scheme Runner \
              -configuration Debug \
              build
   open ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug/well_spent.app
   ```

2. **iOS App & Simulator**:
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
