import SwiftUI

@main struct TurfOrnamentalApp: App {
    @StateObject private var store = RecordStore()
    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    ContentUnavailableView("Your field workspace", systemImage: "bubble.left.and.bubble.right",
                        description: Text("Use Field Tools to calculate and save quantities. Conversations and AI are not available in this build."))
                        .navigationTitle("Chat")
                }.tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
                NavigationStack { CalculatorView() }.tabItem { Label("Field Tools", systemImage: "function") }
                NavigationStack { PropertiesView() }.tabItem { Label("Properties", systemImage: "leaf") }
                NavigationStack { SavedResultsView() }.tabItem { Label("Library", systemImage: "books.vertical") }
            }
            .tint(Color(red: 0.18, green: 0.49, blue: 0.27))
            .environmentObject(store)
            .alert("Storage needs attention", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("OK") { store.error = nil }
            } message: { Text(store.error ?? "") }
        }
    }
}

struct CalculatorView: View {
    @EnvironmentObject var store: RecordStore
    @State private var area = ""
    @State private var rate = ""
    @State private var basis = "1000"
    @State private var areaUnit = AreaUnit.squareFeet
    @State private var basisUnit = AreaUnit.squareFeet
    @State private var productUnit = ProductUnit.grams
    @State private var propertyID: UUID?
    @State private var result: String?
    @State private var message: String?
    @State private var restored = false
    private var input: AreaInput { AreaInput(area: area, areaUnit: areaUnit, rate: rate, productUnit: productUnit, basis: basis, basisUnit: basisUnit) }

    var body: some View {
        Form {
            Section {
                NavigationLink("Field photos", destination: FieldPhotosView())
                NavigationLink("Field notes and dictation", destination: DictationView())
            }
            Section("Area-rate calculator") {
                Text("Ordinary arithmetic using your entered rate. Product identity, allowable use and measurement accuracy are not verified.")
                    .font(.footnote).foregroundStyle(.secondary)
                TextField("Actual treated area", text: $area).keyboardType(.decimalPad).accessibilityIdentifier("treatedArea")
                Picker("Area unit", selection: $areaUnit) { ForEach(AreaUnit.allCases) { Text($0.rawValue).tag($0) } }
                TextField("Product rate", text: $rate).keyboardType(.decimalPad).accessibilityIdentifier("productRate")
                Picker("Product unit", selection: $productUnit) { ForEach(ProductUnit.allCases) { Text($0.rawValue).tag($0) } }
                TextField("Rate applies per", text: $basis).keyboardType(.decimalPad)
                Picker("Rate-basis unit", selection: $basisUnit) { ForEach(AreaUnit.allCases) { Text($0.rawValue).tag($0) } }
                Text("Use a decimal point without commas or grouping separators.").font(.caption)
                Button("Calculate") {
                    do { result = AreaCalculator.text(try AreaCalculator.amount(input)); message = nil }
                    catch { result = nil; message = error.localizedDescription }
                }.accessibilityIdentifier("calculate")
            }
            if let result {
                Section("Calculated quantity") {
                    Text("\(result) \(productUnit.rawValue)").font(.title2).textSelection(.enabled)
                    Text("Conditional on your inputs. This is an unrounded arithmetic result, not a measuring instruction.").font(.footnote)
                    Picker("Save to property", selection: $propertyID) {
                        Text("Choose a property").tag(Optional<UUID>.none)
                        ForEach(store.records.properties) { Text($0.name).tag(Optional($0.id)) }
                    }
                    Button("Save result") {
                        guard let property = store.records.properties.first(where: { $0.id == propertyID }) else { return }
                        do { try store.save(input: input, property: property); message = "Saved in Library." }
                        catch { message = "Could not save: \(error.localizedDescription)" }
                    }.disabled(propertyID == nil || !store.canWrite)
                    if store.records.properties.isEmpty { Text("Add a property in Properties to save this result.") }
                }
            }
            if let message { Section { Text(message).accessibilityIdentifier("calculatorMessage") } }
        }
        .navigationTitle("Field Tools")
        .onAppear {
            guard !restored else { return }
            if let draft = store.records.calculatorDraft {
                area = draft.area; areaUnit = draft.areaUnit; rate = draft.rate
                basis = draft.basis; basisUnit = draft.basisUnit; productUnit = draft.productUnit
                propertyID = store.records.calculatorPropertyID
            }
            restored = true
        }
        .onChange(of: input) { _, _ in result = nil; message = nil; saveDraft() }
        .onChange(of: propertyID) { _, _ in saveDraft() }
    }
    private func saveDraft() {
        guard restored else { return }
        do { try store.saveCalculatorDraft(input, propertyID: propertyID) }
        catch { message = "Draft could not be saved. Keep this form open and retry after unlocking the phone." }
    }
}

struct PropertiesView: View {
    @EnvironmentObject var store: RecordStore
    @State private var showAdd = false
    var body: some View {
        List {
            if store.records.properties.isEmpty {
                Text("Add a property with its country and locality. Your phone’s location is never assumed to be the property.")
            }
            ForEach(store.records.properties) { property in
                VStack(alignment: .leading, spacing: 6) {
                    Text(property.name).font(.headline)
                    Text("\(property.locality), \(property.country)")
                    Text("\(property.host) · \(property.timeZone)").font(.caption)
                    Text("User-confirmed area; regional guidance and chemical coverage unavailable.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Properties")
        .toolbar { Button("Add property", systemImage: "plus") { showAdd = true }.disabled(!store.canWrite) }
        .sheet(isPresented: $showAdd) { NavigationStack { AddPropertyView() } }
    }
}

struct AddPropertyView: View {
    @EnvironmentObject var store: RecordStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var location = PropertyLocation()
    @State private var useFix = false
    @State private var restored = false
    @State private var name = ""
    @State private var country = ""
    @State private var locality = ""
    @State private var zone = ""
    @State private var host = "Unknown"
    @State private var confirmed = false
    @State private var error: String?
    private let hosts = ["Unknown", "Warm-season turf", "Cool-season turf", "Mixed / transition turf", "Ornamentals", "Turf and ornamentals"]
    private var draft: [String: String] { ["name":name,"country":country,"locality":locality,"zone":zone,"host":host] }
    var body: some View {
        Form {
            Section("Property location") {
                Button("Use my location") { useFix = false; confirmed = false; location.request() }
                    .disabled(location.requesting)
                if location.requesting { Button("Cancel location request") { location.cancel() } }
                Text(location.status).font(.footnote)
                if let fix = location.fix {
                    Text("\(fix.approximate ? "Approximate" : "Device") fix: ±\(Int(fix.accuracyMeters)) m. Captured \(fix.capturedAt.formatted()).").font(.caption)
                    Toggle("I am at this property; attach this device fix", isOn: $useFix)
                }
                Text("Enter property location manually below. Country, locality and time zone are required for either route; no geocoding service is connected.").font(.footnote)
                TextField("Property nickname", text: $name)
                TextField("Country", text: $country)
                TextField("City / locality and region", text: $locality)
                TextField("Time zone, e.g. America/New_York", text: $zone).textInputAutocapitalization(.never).autocorrectionDisabled()
                Picker("Plant context", selection: $host) { ForEach(hosts, id: \.self) { Text($0) } }
                Toggle("I confirm this is the property’s location", isOn: $confirmed)
                Text("Saved locally as a user-confirmed area, not a verified boundary. Location is not uploaded. Unfinished fields are saved; location confirmation must be repeated when reopening.").font(.footnote)
            }
            if let error { Text(error).foregroundStyle(.red) }
            Button("Save property") {
                let fields = [name, country, locality, zone].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                guard fields.allSatisfy({ !$0.isEmpty && $0.count <= 200 }), confirmed, TimeZone(identifier: fields[3]) != nil else {
                    error = "Enter a nickname, country, locality and valid time-zone identifier, then confirm the location."; return
                }
                do {
                    var property = PropertyRecord(name: fields[0], country: fields[1], locality: fields[2], timeZone: fields[3], host: host)
                    if useFix {
                        guard let fix = location.fix, abs(fix.capturedAt.timeIntervalSinceNow) <= 300 else {
                            error = "The device fix is missing or too old. Request a new fix or use manual entry."; return
                        }
                        property.locationFix = fix
                        property.locationSource = "user-confirmed device fix and manual region"
                    }
                    try store.save(property: property)
                    dismiss()
                } catch { self.error = "Could not save: \(error.localizedDescription)" }
            }.disabled(!confirmed)
        }.navigationTitle("New property")
            .toolbar { Button("Close — keep draft") { dismiss() } }
            .onAppear {
                guard !restored else { return }
                if let saved = store.records.propertyDraft {
                    name = saved["name"] ?? ""; country = saved["country"] ?? ""
                    locality = saved["locality"] ?? ""; zone = saved["zone"] ?? ""
                    host = saved["host"] ?? "Unknown"
                }
                restored = true
            }
            .onChange(of: draft) { _, _ in
                confirmed = false
                guard restored else { return }
                do { try store.savePropertyDraft(draft) }
                catch { self.error = "Draft could not be saved. Keep this form open and retry after unlocking the phone." }
            }
            .onChange(of: useFix) { _, _ in confirmed = false }
            .onChange(of: scenePhase) { _, phase in if phase == .background { location.cancel() } }
            .onDisappear { location.cancel() }
    }
}

struct SavedResultsView: View {
    @EnvironmentObject var store: RecordStore
    var body: some View {
        List {
            if store.records.calculations.isEmpty { Text("Saved calculations will appear here with their original property and input snapshots.") }
            ForEach(store.records.calculations.reversed()) { result in
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.property.name).font(.headline)
                    Text("\(result.amount) \(result.input.productUnit.rawValue)").textSelection(.enabled)
                    Text("\(result.input.area) \(result.input.areaUnit.rawValue) at \(result.input.rate) \(result.input.productUnit.rawValue) per \(result.input.basis) \(result.input.basisUnit.rawValue)").font(.caption)
                    Text(result.createdAt, style: .date).font(.caption)
                    Text(result.status).font(.caption).foregroundStyle(.secondary)
                }
            }
        }.navigationTitle("Library")
    }
}
