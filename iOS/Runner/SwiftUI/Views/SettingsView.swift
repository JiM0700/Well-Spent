import SwiftUI
import UniformTypeIdentifiers

public struct SettingsView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var showFileImporter: Bool = false
    @State private var importMode: ImportMode = .csv
    @State private var showPasteAlert: Bool = false
    @State private var importInputString: String = ""
    @State private var importMessage: String = ""
    @State private var showImportResult: Bool = false
    @State private var showDeleteAllConfirmation: Bool = false
    @Environment(\.colorScheme) var colorScheme

    private enum ImportMode {
        case csv, json
    }

    public init() {}

    public var body: some View {
        #if os(macOS)
        macOSDesktopBody
        #else
        iOSBody
        #endif
    }

    // ── iOS Body ──────────────────────────────────────────────────────────

    #if os(iOS)
    private var iOSBody: some View {
        NavigationStack {
            settingsForm
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
        }
    }
    #endif

    // ── macOS Desktop Body ────────────────────────────────────────────────

    #if os(macOS)
    private var macOSDesktopBody: some View {
        settingsForm
            .padding()
    }
    #endif

    // ── Shared Settings Form ──────────────────────────────────────────────

    private var settingsForm: some View {
        Form {
            budgetSection
            netWorthSection
            appearanceSection
            soundAndHapticsSection
            notificationsSection
            dataSection
            aboutSection
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText, .json, UTType(filenameExtension: "csv") ?? .plainText, UTType(filenameExtension: "json") ?? .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
        .alert("Paste CSV Data", isPresented: $showPasteAlert) {
            TextField("Paste CSV text here", text: $importInputString)
            Button("Import") {
                let count = store.importCsv(content: importInputString)
                importMessage = "Successfully imported \(count) entries."
                showImportResult = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Import Status", isPresented: $showImportResult) {
            Button("OK") {}
        } message: {
            Text(importMessage)
        }
        .confirmationDialog("Delete All Data?", isPresented: $showDeleteAllConfirmation, titleVisibility: .visible) {
            Button("Delete All Data", role: .destructive) {
                PlatformFeedback.warning()
                store.deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove all transactions, goals, and recurring bills. This action cannot be undone.")
        }
        #if os(iOS)
        .scrollContentBackground(.hidden)
        .background(Color.appGroupedBackground.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .keyboardDismissToolbar()
        #endif
        .onChange(of: store.monthlyBudget) { _, _ in store.saveData() }
        .onChange(of: store.cycleStartDay) { _, _ in store.saveData() }
        .onChange(of: store.baseMonthlyIncome) { _, _ in store.saveData() }
        .onChange(of: store.payDay) { _, _ in store.saveData() }
        .onChange(of: store.netWorth.assets) { _, _ in store.saveData() }
        .onChange(of: store.netWorth.liabilities) { _, _ in store.saveData() }
        .onChange(of: store.appThemeMode) { _, _ in store.saveData() }
        .onChange(of: store.hapticsEnabled) { _, _ in store.saveData() }
        .onChange(of: store.soundsEnabled) { _, _ in store.saveData() }
        .onChange(of: store.summaryEnabled) { _, _ in store.saveData() }
        .onChange(of: store.summaryPeriod) { _, _ in store.saveData() }
    }

    // ── Modular Settings Sections with Unified Apple Icon Badges ──────────

    private var budgetSection: some View {
        Section {
            HStack(spacing: 12) {
                SettingsIconBadge(icon: "banknote.fill", background: Color.green)
                Text("Monthly Budget")
                Spacer()
                TextField("Budget", value: $store.monthlyBudget, format: .number)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
            }

            HStack(spacing: 12) {
                SettingsIconBadge(icon: "calendar", background: Color.blue)
                Text("Cycle Start Day")
                Spacer()
                Picker("", selection: $store.cycleStartDay) {
                    ForEach(1...28, id: \.self) { day in
                        Text("\(day)\(daySuffix(day)) of month").tag(day)
                    }
                }
                .labelsHidden()
            }

            HStack(spacing: 12) {
                SettingsIconBadge(icon: "calendar.badge.clock", background: Color.indigo)
                Text("Pay Day")
                Spacer()
                Picker("", selection: $store.payDay) {
                    ForEach(1...28, id: \.self) { day in
                        Text("\(day)\(daySuffix(day)) of month").tag(day)
                    }
                }
                .labelsHidden()
            }

            HStack(spacing: 12) {
                SettingsIconBadge(icon: "arrow.down.left.circle.fill", background: Color.teal)
                Text("Monthly Base Income")
                Spacer()
                TextField("Income", value: $store.baseMonthlyIncome, format: .number)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
            }
        } header: {
            Text("Monthly Budget & Cycle")
        }
    }

    private var netWorthSection: some View {
        Section {
            HStack(spacing: 12) {
                SettingsIconBadge(icon: "chart.line.uptrend.xyaxis", background: Color.green)
                Text("Total Assets")
                Spacer()
                TextField("Assets", value: $store.netWorth.assets, format: .number)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
            }

            HStack(spacing: 12) {
                SettingsIconBadge(icon: "chart.line.downtrend.xyaxis", background: Color.red)
                Text("Total Liabilities")
                Spacer()
                TextField("Liabilities", value: $store.netWorth.liabilities, format: .number)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
            }

            HStack(spacing: 12) {
                SettingsIconBadge(icon: "building.columns.fill", background: Color.purple)
                Text("Calculated Net Worth")
                    .font(.system(size: 13.5, weight: .medium))
                Spacer()
                Text("₹\(formatCurrency(store.netWorth.total))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(store.netWorth.total >= 0 ? Color.green : Color.red)
            }
        } header: {
            Text("Net Worth Balance Sheet")
        }
    }

    private var appearanceSection: some View {
        Section {
            HStack(spacing: 12) {
                SettingsIconBadge(icon: "circle.lefthalf.filled", background: Color.indigo)
                Text("Theme Mode")
                Spacer()
                Picker("Theme Mode", selection: $store.appThemeMode) {
                    Text("System").tag("system")
                    Text("Dark").tag("dark")
                    Text("Light").tag("light")
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
            }
        } header: {
            Text("Appearance")
        }
    }

    private var soundAndHapticsSection: some View {
        Section {
            Toggle(isOn: $store.hapticsEnabled) {
                HStack(spacing: 12) {
                    SettingsIconBadge(icon: "iphone.radiowaves.left.and.right", background: Color.pink)
                    Text("Haptic Feedback")
                }
            }

            Toggle(isOn: $store.soundsEnabled) {
                HStack(spacing: 12) {
                    SettingsIconBadge(icon: "speaker.wave.2.fill", background: Color.orange)
                    Text("Sound Effects")
                }
            }
        } header: {
            Text("Sound & Haptics")
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $store.summaryEnabled) {
                HStack(spacing: 12) {
                    SettingsIconBadge(icon: "bell.badge.fill", background: Color.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Spending Digest")
                        Text("Evening summary notification")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if store.summaryEnabled {
                HStack(spacing: 12) {
                    SettingsIconBadge(icon: "clock.fill", background: Color.blue)
                    Text("Frequency")
                    Spacer()
                    Picker("Notification Frequency", selection: $store.summaryPeriod) {
                        Text("Daily").tag("daily")
                        Text("Weekly").tag("weekly")
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 180)
                }
            }
        } header: {
            Text("Daily Spending Digest")
        } footer: {
            Text("Sends a quiet notification summarizing your spending for the day and your remaining daily allowance runway.")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
        }
    }

    private var csvExportUrl: URL {
        let content = store.exportCsv()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("well_spent_expenses.csv")
        try? content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private var jsonExportUrl: URL {
        let content = store.exportJsonVault()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("well_spent_vault.json")
        try? content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private var dataSection: some View {
        Section {
            // CSV Export
            ShareLink(
                item: csvExportUrl,
                preview: SharePreview("well_spent_expenses.csv")
            ) {
                HStack(spacing: 12) {
                    SettingsIconBadge(icon: "arrow.up.doc.fill", background: Color.blue)
                    Text("Export CSV Spreadsheet")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            // CSV Import
            Menu {
                Button {
                    PlatformFeedback.selection()
                    importMode = .csv
                    showFileImporter = true
                } label: {
                    Label("Choose CSV from Files...", systemImage: "doc.badge.plus")
                }
                Button {
                    PlatformFeedback.selection()
                    importMode = .csv
                    showPasteAlert = true
                } label: {
                    Label("Paste CSV Text...", systemImage: "doc.on.clipboard")
                }
            } label: {
                HStack(spacing: 12) {
                    SettingsIconBadge(icon: "arrow.down.doc.fill", background: Color.cyan)
                    Text("Import CSV Transactions")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            // JSON Backup Vault
            ShareLink(
                item: jsonExportUrl,
                preview: SharePreview("well_spent_vault.json")
            ) {
                HStack(spacing: 12) {
                    SettingsIconBadge(icon: "archivebox.fill", background: Color.purple)
                    Text("Backup JSON Vault")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            // JSON Restore Vault
            Button {
                PlatformFeedback.selection()
                importMode = .json
                showFileImporter = true
            } label: {
                HStack(spacing: 12) {
                    SettingsIconBadge(icon: "arrow.counterclockwise.circle.fill", background: Color.indigo)
                    Text("Restore JSON Vault")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary.opacity(0.6))
                }
            }

            // Destructive Delete All
            Button(role: .destructive) {
                PlatformFeedback.warning()
                showDeleteAllConfirmation = true
            } label: {
                HStack(spacing: 12) {
                    SettingsIconBadge(icon: "trash.fill", background: Color.red)
                    Text("Delete All Data")
                        .foregroundStyle(Color.red)
                }
            }
        } header: {
            Text("Data Management & Portability")
        } footer: {
            Text("Your financial data is stored 100% locally on your device. Export regular backups to prevent data loss.")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
        }
    }

    private var aboutSection: some View {
        Section {
            HStack(spacing: 12) {
                SettingsIconBadge(icon: "info.circle.fill", background: Color.gray)
                Text("Version")
                Spacer()
                Text("0.1.0")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                SettingsIconBadge(icon: "lock.shield.fill", background: Color.green)
                Text("Privacy & Storage")
                Spacer()
                Text("100% On-Device & Private")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.green)
            }
        } header: {
            Text("About")
        }
    }

    // ── Handlers ──────────────────────────────────────────────────────────

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                if importMode == .json || url.pathExtension.lowercased() == "json" {
                    let success = store.importJsonVault(content: content)
                    if success {
                        PlatformFeedback.success()
                        importMessage = "Successfully restored JSON vault backup."
                    } else {
                        importMessage = "Failed to parse JSON backup file."
                    }
                } else {
                    let count = store.importCsv(content: content)
                    PlatformFeedback.success()
                    importMessage = "Successfully imported \(count) transactions from CSV."
                }
                showImportResult = true
            } catch {
                importMessage = "Could not read file: \(error.localizedDescription)"
                showImportResult = true
            }
        case .failure(let error):
            importMessage = "Import failed: \(error.localizedDescription)"
            showImportResult = true
        }
    }

    private func daySuffix(_ day: Int) -> String {
        switch day {
        case 1, 21: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}

// ── Reusable Apple-Style Settings Icon Badge ─────────────────────────────────

private struct SettingsIconBadge: View {
    let icon: String
    let background: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(background)
                .frame(width: 28, height: 28)
            Image(systemName: icon)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(Color.white)
        }
    }
}
