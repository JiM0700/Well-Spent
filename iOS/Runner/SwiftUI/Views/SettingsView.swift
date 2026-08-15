import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var showExportShareSheet: Bool = false
    @State private var exportCsvString: String = ""
    @State private var showImportAlert: Bool = false
    @State private var importInputString: String = ""
    @State private var importMessage: String = ""
    @State private var showImportResult: Bool = false

    public var body: some View {
        NavigationStack {
            List {
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
