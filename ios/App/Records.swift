import Foundation
import Combine

struct PropertyRecord: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var country: String
    var locality: String
    var timeZone: String
    var host: String
    var createdAt = Date()
    var locationSource = "user-reported manual area"
    var locationVersion = 1
    var locationFix: LocationFix?
}

struct CalculationRecord: Codable, Identifiable {
    var id = UUID()
    var createdAt = Date()
    var property: PropertyRecord
    var input: AreaInput
    var amount: String
    var engineVersion = AreaCalculator.version
    var status = "Arithmetic only — product use not verified"
}

struct LocalRecords: Codable {
    var schemaVersion = 1
    var properties: [PropertyRecord] = []
    var calculations: [CalculationRecord] = []
    var propertyDraft: [String: String]?
    var calculatorDraft: AreaInput?
    var calculatorPropertyID: UUID?
    var photos: [FieldPhoto]?
    var noteDraft: NoteDraft?
    var notes: [FieldNote]?
}

@MainActor final class RecordStore: ObservableObject {
    @Published private(set) var records = LocalRecords()
    @Published var error: String?
    private(set) var canWrite = true
    private let file: URL

    init(file: URL? = nil) {
        self.file = file ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TurfOrnamentalPro/records.json")
        do {
            if FileManager.default.fileExists(atPath: self.file.path) {
                records = try JSONDecoder().decode(LocalRecords.self, from: Data(contentsOf: self.file))
                guard records.schemaVersion == 1 else { throw CocoaError(.fileReadCorruptFile) }
            }
        } catch {
            canWrite = false
            self.error = "Saved records could not be read. Existing data was preserved. Close and reopen after unlocking the phone; recovery is required if this continues."
        }
    }
    func save(property: PropertyRecord) throws {
        var next = records
        next.properties.append(property)
        next.propertyDraft = nil
        try commit(next)
    }
    func savePropertyDraft(_ draft: [String: String]) throws {
        var next = records; next.propertyDraft = draft; try commit(next)
    }
    func saveNoteDraft(_ draft: NoteDraft) throws {
        guard draft.text.count <= 10000 else { throw CocoaError(.fileWriteInvalidFileName) }
        var next = records; next.noteDraft = draft; try commit(next)
    }
    func saveNote(_ draft: NoteDraft) throws {
        guard !draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, draft.text.count <= 10000,
              let property = records.properties.first(where: { $0.id == draft.propertyID }) else { throw CocoaError(.fileNoSuchFile) }
        var next = records
        next.notes = (next.notes ?? []) + [FieldNote(property: property, text: draft.text)]
        next.noteDraft = nil
        try commit(next)
    }
    func deleteNote(id: UUID) throws {
        var next = records; next.notes = next.notes?.filter { $0.id != id }; try commit(next)
    }
    func savePhoto(_ photo: FieldPhoto) throws {
        guard (records.photos ?? []).count < 4 else { throw PhotoFailure.full }
        guard PhotoPreview.thumbnail(photo.imageData) != nil else { throw PhotoFailure.unsupported }
        guard records.properties.contains(where: { $0.id == photo.property.id }) else { throw CocoaError(.fileNoSuchFile) }
        var next = records
        next.photos = (next.photos ?? []) + [photo]
        try commit(next)
    }
    func deletePhoto(id: UUID) throws {
        var next = records
        next.photos = next.photos?.filter { $0.id != id }
        try commit(next)
    }
    func saveCalculatorDraft(_ input: AreaInput, propertyID: UUID?) throws {
        var next = records; next.calculatorDraft = input; next.calculatorPropertyID = propertyID; try commit(next)
    }
    func save(input: AreaInput, property: PropertyRecord) throws {
        let amount = try AreaCalculator.amount(input)
        var next = records
        next.calculations.append(CalculationRecord(property: property, input: input, amount: AreaCalculator.text(amount)))
        try commit(next)
    }
    private func commit(_ next: LocalRecords) throws {
        guard canWrite else { throw CocoaError(.fileWriteNoPermission) }
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(next)
        try data.write(to: file, options: [.atomic, .completeFileProtection])
        records = next
    }
}
