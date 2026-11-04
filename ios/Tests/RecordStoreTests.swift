#if !SWIFT_PACKAGE
import XCTest
import UIKit
@testable import TurfOrnamentalPro

@MainActor final class RecordStoreTests: XCTestCase {
    func testReviewedNoteDraftPersistsAndSavesWithProperty() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("records.json")
        let store = RecordStore(file: file)
        let property = PropertyRecord(name: "Synthetic note test", country: "New Zealand", locality: "Wellington", timeZone: "Pacific/Auckland", host: "Unknown")
        try store.save(property: property)
        let draft = NoteDraft(text: "User-reviewed observation, no prescribed rate.", propertyID: property.id)
        try store.saveNoteDraft(draft)
        let reopened = RecordStore(file: file)
        XCTAssertEqual(reopened.records.noteDraft, draft)
        try reopened.saveNote(draft)
        let saved = RecordStore(file: file)
        XCTAssertNil(saved.records.noteDraft)
        XCTAssertEqual(saved.records.notes?.first?.property.id, property.id)
        XCTAssertEqual(saved.records.notes?.first?.text, draft.text)
        XCTAssertThrowsError(try saved.saveNote(NoteDraft(text: "Unknown property", propertyID: UUID())))
        XCTAssertThrowsError(try saved.saveNoteDraft(NoteDraft(text: String(repeating: "x", count: 10001))))
        try saved.deleteNote(id: XCTUnwrap(saved.records.notes?.first?.id))
        XCTAssertTrue(RecordStore(file: file).records.notes?.isEmpty == true)
        XCTAssertEqual(RecordStore(file: file).records.properties.count, 1)
    }
    func testPhotoPersistsAndDeletionDoesNotDeleteProperty() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("records.json")
        let store = RecordStore(file: file)
        let property = PropertyRecord(name: "Synthetic test", country: "New Zealand", locality: "Wellington", timeZone: "Pacific/Auckland", host: "Unknown")
        try store.save(property: property)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 16, height: 16)).image { context in
            UIColor.green.setFill(); context.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
        }
        let data = try XCTUnwrap(image.pngData())
        let photo = FieldPhoto(property: property, source: "Synthetic test pixels", imageData: data)
        try store.savePhoto(photo)
        let reopened = RecordStore(file: file)
        XCTAssertEqual(reopened.records.photos?.first?.imageData, data)
        XCTAssertEqual(reopened.records.photos?.first?.property.id, property.id)
        try reopened.deletePhoto(id: photo.id)
        let afterDelete = RecordStore(file: file)
        XCTAssertTrue(afterDelete.records.photos?.isEmpty == true)
        XCTAssertEqual(afterDelete.records.properties.count, 1)
        XCTAssertThrowsError(try afterDelete.savePhoto(FieldPhoto(property: property, source: "Invalid bytes", imageData: Data([0,1,2]))))
    }
    func testUnfinishedFormsSurviveRestart() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("records.json")
        let store = RecordStore(file: file)
        let draft = AreaInput(area: "1.", areaUnit: .squareMeters, rate: "", productUnit: .grams, basis: "1000", basisUnit: .squareFeet)
        try store.saveCalculatorDraft(draft, propertyID: nil)
        try store.savePropertyDraft(["name":"Unfinished property","country":"New Zealand"])
        let reopened = RecordStore(file: file)
        XCTAssertTrue(reopened.canWrite)
        XCTAssertEqual(reopened.records.calculatorDraft, draft)
        XCTAssertEqual(reopened.records.propertyDraft?["country"], "New Zealand")
        XCTAssertTrue(reopened.records.properties.isEmpty)
    }

    func testOlderRecordsWithoutDraftFieldsRemainReadable() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("records.json")
        try Data(#"{"schemaVersion":1,"properties":[],"calculations":[]}"#.utf8).write(to: file)
        let store = RecordStore(file: file)
        XCTAssertTrue(store.canWrite)
        XCTAssertNil(store.records.propertyDraft)
        XCTAssertNil(store.records.calculatorDraft)
    }

    func testSavingPropertyClearsOnlyItsDraft() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("records.json")
        let store = RecordStore(file: file)
        try store.savePropertyDraft(["name":"Draft"])
        let draft = AreaInput(area: "20", areaUnit: .squareMeters, rate: "1", productUnit: .grams, basis: "1000", basisUnit: .squareFeet)
        try store.saveCalculatorDraft(draft, propertyID: nil)
        try store.save(property: PropertyRecord(name: "Example", country: "New Zealand", locality: "Wellington", timeZone: "Pacific/Auckland", host: "Unknown"))
        let reopened = RecordStore(file: file)
        XCTAssertNil(reopened.records.propertyDraft)
        XCTAssertEqual(reopened.records.calculatorDraft, draft)
        XCTAssertEqual(reopened.records.properties.count, 1)
    }
}
#endif
