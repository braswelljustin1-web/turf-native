import SwiftUI
import UIKit
import AVFoundation
import PhotosUI
import CoreTransferable
import UniformTypeIdentifiers
import ImageIO

struct FieldPhoto: Codable, Identifiable {
    var id = UUID()
    var property: PropertyRecord
    var capturedAt = Date()
    var source: String
    var imageData: Data
}

enum PhotoFailure: String, Error, LocalizedError {
    case unsupported = "This image could not be read. Choose a JPEG, HEIC or PNG photo under 12 MB."
    case full = "This early build stores up to four field photos. Remove a saved photo before adding another."
    var errorDescription: String? { rawValue }
}

enum PhotoPreview {
    static let maximumBytes = 12 * 1024 * 1024
    static func thumbnail(_ data: Data) -> UIImage? {
        guard !data.isEmpty, data.count <= maximumBytes,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1200,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct ImportedPhoto: Transferable {
    let data: Data
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            // The security-scoped temporary URL is only used during the import callback.
            let handle = try FileHandle(forReadingFrom: received.file)
            defer { try? handle.close() }
            let data = try handle.read(upToCount: PhotoPreview.maximumBytes + 1) ?? Data()
            guard PhotoPreview.thumbnail(data) != nil else { throw PhotoFailure.unsupported }
            return ImportedPhoto(data: data)
        }
    }
}

struct NativeStillCamera: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.image.identifier]
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (UIImage?) -> Void
        init(completion: @escaping (UIImage?) -> Void) { self.completion = completion }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { completion(nil) }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            completion(info[.originalImage] as? UIImage)
        }
    }
}

struct FieldPhotosView: View {
    @EnvironmentObject var store: RecordStore
    @Environment(\.scenePhase) var scenePhase
    @State private var propertyID: UUID?
    @State private var showCamera = false
    @State private var authorizing = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var previewData: Data?
    @State private var previewImage: UIImage?
    @State private var source = ""
    @State private var message: String?
    @State private var loading = false
    @State private var cameraRequest = UUID()
    var body: some View {
        List {
            Section("Field photos") {
                Picker("Property", selection: $propertyID) {
                    Text("Choose a property").tag(Optional<UUID>.none)
                    ForEach(store.records.properties) { Text($0.name).tag(Optional($0.id)) }
                }
                Text("Photos stay on this phone. No AI analysis or upload is connected. This early build saves up to four photos, each under 12 MB.").font(.footnote)
                Button("Take photo", systemImage: "camera") { requestCamera() }
                    .disabled(authorizing || loading || propertyID == nil)
                PhotosPicker(selection: $pickerItem, matching: .images) { Label("Choose existing photo", systemImage: "photo") }
                    .disabled(loading || propertyID == nil)
                if loading { ProgressView("Loading selected photo…") }
                if let message { Text(message).font(.footnote) }
            }
            if let image = previewImage {
                Section("Review before saving") {
                    Image(uiImage: image).resizable().scaledToFit().accessibilityLabel("Selected photo preview")
                    Text(source).font(.caption)
                    Button("Save to selected property") { savePreview() }.disabled(propertyID == nil || !store.canWrite)
                    Button("Discard preview", role: .destructive) { previewData = nil; previewImage = nil }
                }
            }
            Section("Saved on this phone") {
                ForEach(store.records.photos ?? []) { photo in
                    VStack(alignment: .leading) {
                        Text(photo.property.name).font(.headline)
                        if let image = PhotoPreview.thumbnail(photo.imageData) {
                            Image(uiImage: image).resizable().scaledToFit().accessibilityLabel("Saved field photo for \(photo.property.name)")
                        }
                        Text(photo.capturedAt, style: .date)
                        Text(photo.source).font(.caption)
                        Button("Delete photo", role: .destructive) {
                            do { try store.deletePhoto(id: photo.id) }
                            catch { message = "Photo could not be deleted: \(error.localizedDescription)" }
                        }
                    }
                }
            }
        }
        .navigationTitle("Field photos")
        .fullScreenCover(isPresented: $showCamera) {
            NativeStillCamera { image in
                showCamera = false
                guard let image else { return }
                guard let data = image.jpegData(compressionQuality: 0.95) else { message = PhotoFailure.unsupported.rawValue; return }
                setPreview(data, source: "Native camera image saved as JPEG; preview is resized. No generated edits.")
            }.ignoresSafeArea()
        }
        .task(id: pickerItem) {
            guard let item = pickerItem else { return }
            loading = true
            defer { loading = false }
            do {
                guard let imported = try await item.loadTransferable(type: ImportedPhoto.self) else { throw PhotoFailure.unsupported }
                guard !Task.isCancelled else { return }
                setPreview(imported.data, source: "Selected photo retained as imported; preview is resized. Import time is shown, not original capture time.")
            } catch { if !Task.isCancelled { message = "Photo import failed. Your existing photos are unchanged. \(error.localizedDescription)" } }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { cameraRequest = UUID(); showCamera = false; authorizing = false }
        }
        .onDisappear { cameraRequest = UUID(); authorizing = false }
    }
    private func requestCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            message = "Camera unavailable. Choose an existing photo instead."; return
        }
        let request = UUID(); cameraRequest = request; authorizing = true
        Task { @MainActor in
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            var allowed = status == .authorized
            if status == .notDetermined { allowed = await AVCaptureDevice.requestAccess(for: .video) }
            guard cameraRequest == request else { return }
            authorizing = false
            guard allowed else { message = "Camera access is denied or restricted. Choose an existing photo, or enable camera access in iPhone Settings."; return }
            showCamera = true
        }
    }
    private func setPreview(_ data: Data, source: String) {
        guard let image = PhotoPreview.thumbnail(data) else { message = PhotoFailure.unsupported.rawValue; return }
        previewData = data; previewImage = image; self.source = source; message = nil
    }
    private func savePreview() {
        guard let data = previewData, let property = store.records.properties.first(where: { $0.id == propertyID }) else { return }
        do {
            try store.savePhoto(FieldPhoto(property: property, source: source, imageData: data))
            previewData = nil; previewImage = nil; message = "Photo saved locally."
        } catch { message = "Could not save photo: \(error.localizedDescription)" }
    }
}
