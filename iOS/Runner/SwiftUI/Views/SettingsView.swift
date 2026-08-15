import SwiftUI
import UniformTypeIdentifiers

public struct SettingsView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var showExportShareSheet: Bool = false
    @State private var exportCsvString: String = ""
    @State private var showImportConfirmation: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var showPasteAlert: Bool = false
    @State private var importInputString: String = ""
    @State private var importMessage: String = ""
    @State private var showImportResult: Bool = false
    @State private var showDeleteAllConfirmation: Bool = false
    @Environment(\.colorScheme) var colorScheme

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 20) {
                    // ── Header Section ─────────────────────────────────────
                    headerSection
                        .padding(.horizontal, 24)
                        .padding(.top, 14)

                    #if os(macOS)
                    // ── Widescreen Balanced 2-Column Desktop Grid ─────────
                    HStack(alignment: .top, spacing: 20) {
                        // Left Column (50% Width)
                        VStack(spacing: 18) {
                            appearanceSection
                            dataManagementSection
                        }
                        .frame(maxWidth: .infinity, alignment: .top)

                        // Right Column (50% Width)
                        VStack(spacing: 18) {
                            budgetingSection
                            summariesSection
                            aboutSection
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .padding(.horizontal, 24)
                    #else
                    // ── Mobile Single Column Stack ────────────────────────
                    VStack(spacing: 16) {
                        appearanceSection
                        budgetingSection
                        summariesSection
                        dataManagementSection
                        aboutSection
                    }
                    .padding(.horizontal, 16)
                    #endif

                    #if os(iOS)
                    Spacer(minLength: 100)
                    #else
                    Spacer(minLength: 40)
                    #endif
                }
                .padding(.vertical, 8)
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showExportShareSheet) {
                ShareSheet(activityItems: [exportCsvString])
            }
            .confirmationDialog("Import CSV", isPresented: $showImportConfirmation, titleVisibility: .visible) {
                Button("Choose File from Files") {
                    showFileImporter = true
                }
                Button("Paste CSV Text") {
                    showPasteAlert = true
                }
                Button("Cancel", role: .cancel) {}
            }
            #endif
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.commaSeparatedText, .plainText, UTType(filenameExtension: "csv") ?? .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            .background(colorScheme == .dark ? Color.black : Color.appGroupedBackground)
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
            .alert("Delete All Data?", isPresented: $showDeleteAllConfirmation) {
                Button("Delete All Data", role: .destructive) {
                    PlatformFeedback.warning()
                    store.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove all transactions and custom category targets. This action cannot be undone.")
            }
        }
    }

    // ── Header Section ────────────────────────────────────────────────────

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                Text("Preferences, Budgets & Data Management")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // ── Appearance & Color Theme ──────────────────────────────────────────

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("APPEARANCE & ACCENT")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            // Theme Mode Selector
            Picker("Appearance", selection: $store.appThemeMode) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
            .onChange(of: store.appThemeMode) { _, _ in
                PlatformFeedback.selection()
                store.saveData()
            }

            // Accent Color Palette
            VStack(alignment: .leading, spacing: 8) {
                Text("Accent Color")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                let colorOptions: [(name: String, color: Color, title: String)] = [
                    ("green", Color.green, "Green"),
                    ("blue", Color.blue, "Blue"),
                    ("indigo", Color.indigo, "Indigo"),
                    ("purple", Color.purple, "Purple"),
                    ("orange", Color.orange, "Orange"),
                    ("teal", Color.teal, "Teal"),
                    ("pink", Color.pink, "Pink")
                ]

                HStack(spacing: 12) {
                    ForEach(colorOptions, id: \.name) { opt in
                        let isSelected = store.appAccentColorName == opt.name

                        Button(action: {
                            PlatformFeedback.selection()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                store.appAccentColorName = opt.name
                                store.saveData()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(opt.color)
                                    .frame(width: 32, height: 32)

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
                                    .frame(width: 38, height: 38)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .liquidGlassCard(cornerRadius: 16)
    }

    // ── Budgeting & Cycles ────────────────────────────────────────────────

    private var budgetingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BUDGET & INCOME CYCLES")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            HStack {
                Text("Monthly Budget")
                    .font(.system(size: 13.5))
                Spacer()
                TextField("Budget", value: $store.monthlyBudget, format: .currency(code: "INR"))
                    .multilineTextAlignment(.trailing)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .frame(width: 140)
                    .textFieldStyle(.roundedBorder)
            }

            Divider()
                .opacity(0.3)

            Picker("Cycle Starts On", selection: $store.cycleStartDay) {
                ForEach(1...28, id: \.self) { day in
                    Text("Day \(day)").tag(day)
                }
            }

            Divider()
                .opacity(0.3)

            HStack {
                Text("Monthly Income")
                    .font(.system(size: 13.5))
                Spacer()
                TextField("Income", value: $store.baseMonthlyIncome, format: .currency(code: "INR"))
                    .multilineTextAlignment(.trailing)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .frame(width: 140)
                    .textFieldStyle(.roundedBorder)
            }

            Divider()
                .opacity(0.3)

            Picker("Payday", selection: $store.payDay) {
                ForEach(1...28, id: \.self) { day in
                    Text("Day \(day)").tag(day)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .liquidGlassCard(cornerRadius: 16)
    }

    // ── Summaries & Notifications ─────────────────────────────────────────

    private var summariesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("NOTIFICATIONS & SUMMARIES")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            Toggle("Spending Summaries", isOn: $store.summaryEnabled)
                .toggleStyle(LiquidGlassToggleStyle())

            if store.summaryEnabled {
                Divider()
                    .opacity(0.3)

                Picker("Summary Frequency", selection: $store.summaryPeriod) {
                    Text("Daily").tag("daily")
                    Text("Weekly").tag("weekly")
                    Text("Monthly").tag("monthly")
                }
                .pickerStyle(.segmented)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .liquidGlassCard(cornerRadius: 16)
    }

    // ── Data Management ───────────────────────────────────────────────────

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DATA MANAGEMENT & BACKUP")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button(action: exportCsv) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.doc.fill")
                        Text("Export CSV")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 10))

                Button(action: initiateCsvImport) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Import CSV")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 10))
            }

            Divider()
                .opacity(0.3)

            Button(role: .destructive, action: {
                showDeleteAllConfirmation = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash.fill")
                    Text("Delete All Data")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(LiquidGlassButtonStyle(tintColor: Color.red, cornerRadius: 10))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .liquidGlassCard(cornerRadius: 16)
    }

    // ── About & Privacy ───────────────────────────────────────────────────

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ABOUT")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            HStack {
                Text("Well Spent")
                    .font(.system(size: 13.5, weight: .semibold))
                Spacer()
                Text("v1.0.0 Native SwiftUI")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Data Privacy")
                    .font(.system(size: 13.5))
                Spacer()
                Text("100% Offline & Local")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .liquidGlassCard(cornerRadius: 16)
    }

    // ── CSV Export & Import Handlers ──────────────────────────────────────

    private func exportCsv() {
        PlatformFeedback.selection()
        exportCsvString = store.exportCsv()
        #if os(iOS)
        showExportShareSheet = true
        #elseif os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText, .plainText]
        savePanel.nameFieldStringValue = "well_spent_expenses.csv"
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? exportCsvString.write(to: url, atomically: true, encoding: .utf8)
            }
        }
        #endif
    }

    private func initiateCsvImport() {
        PlatformFeedback.selection()
        #if os(macOS)
        showFileImporter = true
        #elseif os(iOS)
        showImportConfirmation = true
        #endif
    }

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
                let count = store.importCsv(content: content)
                importMessage = "Successfully imported \(count) transactions from file."
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
}

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
