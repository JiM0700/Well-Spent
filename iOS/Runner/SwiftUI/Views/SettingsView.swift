import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var showExportShareSheet: Bool = false
    @State private var exportCsvString: String = ""
    @State private var showImportAlert: Bool = false
    @State private var importInputString: String = ""
    @State private var importMessage: String = ""
    @State private var showImportResult: Bool = false
    @State private var showDeleteAllConfirmation: Bool = false

    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("APPEARANCE & THEME")) {
                    // Theme Mode Selector
                    Picker("Appearance", selection: $store.appThemeMode) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: store.appThemeMode) { _, _ in
                        UISelectionFeedbackGenerator().selectionChanged()
                        store.saveData()
                    }

                    // Accent Color Palette
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Accent Color")
                            .font(.subheadline)
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
                                    UISelectionFeedbackGenerator().selectionChanged()
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
                        .padding(.vertical, 4)
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("BUDGETING")) {
                    Button(action: exportCsv) {
                        Label("Export Data to CSV", systemImage: "arrow.up.doc")
                    }

                    Button(action: { showImportAlert = true }) {
                        Label("Import CSV Data", systemImage: "arrow.down.doc")
                    }

                    HStack {
                        Text("Monthly Budget")
                        Spacer()
                        TextField("Budget", value: $store.monthlyBudget, format: .currency(code: "INR"))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 140)
                    }

                    Picker("Cycle Starts On", selection: $store.cycleStartDay) {
                        ForEach(1...28, id: \.self) { day in
                            Text("Day \(day)").tag(day)
                        }
                    }

                    HStack {
                        Text("Monthly Income")
                        Spacer()
                        TextField("Income", value: $store.baseMonthlyIncome, format: .currency(code: "INR"))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 140)
                    }

                    Picker("Payday", selection: $store.payDay) {
                        ForEach(1...28, id: \.self) { day in
                            Text("Day \(day)").tag(day)
                        }
                    }
                }

                Section(header: Text("SUMMARIES")) {
                    Toggle("Spending Summaries", isOn: $store.summaryEnabled)
                        .tint(.green)

                    Picker("Summary Frequency", selection: $store.summaryPeriod) {
                        Text("Daily").tag("daily")
                        Text("Weekly").tag("weekly")
                        Text("Monthly").tag("monthly")
                    }
                }

                Section(header: Text("DATA MANAGEMENT")) {
                    Button(role: .destructive, action: {
                        showDeleteAllConfirmation = true
                    }) {
                        Label("Delete All Data", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }

                Section(header: Text("ABOUT")) {
                    HStack {
                        Text("Well Spent")
                        Spacer()
                        Text("v1.0.0 Native SwiftUI")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Data Privacy")
                        Spacer()
                        Text("100% Offline & Local")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 90)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showExportShareSheet) {
                ShareSheet(activityItems: [exportCsvString])
            }
            .alert("Import CSV Data", isPresented: $showImportAlert) {
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
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    store.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove all transactions and custom category targets. This action cannot be undone.")
            }
        }
    }

    private func exportCsv() {
        UISelectionFeedbackGenerator().selectionChanged()
        exportCsvString = store.exportCsv()
        showExportShareSheet = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
