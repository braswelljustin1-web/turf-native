import SwiftUI
import Speech
import AVFoundation
import Combine
import UIKit

@MainActor final class DictationController: ObservableObject {
    @Published var transcript = ""
    @Published private(set) var busy = false
    @Published private(set) var listening = false
    @Published private(set) var seconds = 0
    @Published private(set) var status = "Type a note or start on-device English (US) dictation."
    private let engine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var ticker: Task<Void, Never>?
    private var generation = UUID()
    private var installedTap = false
    private var activeAudioSession = false
    private var observers = Set<AnyCancellable>()

    init() {
        for name in [UIApplication.didEnterBackgroundNotification, AVAudioSession.interruptionNotification,
                     AVAudioSession.mediaServicesWereResetNotification] {
            NotificationCenter.default.publisher(for: name).sink { [weak self] _ in
                Task { @MainActor in
                    guard let self, self.busy else { return }
                    self.stop(message: "Recording stopped after an interruption. Review the partial transcript; restart when ready.")
                }
            }.store(in: &observers)
        }
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification).sink { [weak self] note in
            let reason = (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? NSNumber)?.uintValue
            guard reason != AVAudioSession.RouteChangeReason.categoryChange.rawValue else { return }
            Task { @MainActor in
                guard let self, self.listening else { return }
                self.stop(message: "Audio device changed. Review the partial transcript and restart when ready.")
            }
        }.store(in: &observers)
    }

    func start() {
        guard !busy else { return }
        guard let recognizer, recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
            status = "On-device English (US) recognition is unavailable on this device. You can type below; audio will not be sent to a remote service."
            return
        }
        generation = UUID()
        let token = generation
        busy = true; seconds = 0; status = "Checking speech and microphone access…"
        Task { @MainActor in
            let speech = await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
                SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
            }
            guard generation == token else { return }
            guard speech == .authorized else { stop(message: "Speech access is denied or restricted. Type below, or review access in iPhone Settings."); return }
            var microphone = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
            if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
                microphone = await AVCaptureDevice.requestAccess(for: .audio)
            }
            guard generation == token else { return }
            guard microphone else { stop(message: "Microphone access is denied or restricted. Typed notes remain available."); return }
            guard UIApplication.shared.applicationState == .active,
                  recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
                stop(message: "Dictation is unavailable right now. Return to the app and try again, or type below."); return
            }
            do { try begin(recognizer: recognizer, token: token) }
            catch { stop(message: "Could not start audio capture. Typed notes remain available.") }
        }
    }

    private func begin(recognizer: SFSpeechRecognizer, token: UUID) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement)
        try session.setActive(true)
        activeAudioSession = true
        let format = engine.inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { throw CocoaError(.featureUnsupported) }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        self.request = request
        transcript = ""
        engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in request.append(buffer) }
        installedTap = true
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            let text = result?.bestTranscription.formattedString
            let final = result?.isFinal == true
            let failed = error != nil
            Task { @MainActor in
                guard let self, self.generation == token else { return }
                if let text { self.transcript = text }
                if failed { self.stop(message: "Recognition stopped. Review any partial text or type your note.") }
                else if final { self.stop(message: "Dictation finished. Review names, numbers and units before inserting.") }
            }
        }
        engine.prepare()
        try engine.start()
        listening = true; status = "Listening on this device…"
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self, self.generation == token else { return }
                self.seconds += 1
                if AVCaptureDevice.authorizationStatus(for: .audio) != .authorized || SFSpeechRecognizer.authorizationStatus() != .authorized {
                    self.stop(message: "Access was revoked. Recording stopped; typed notes are available."); return
                }
                if self.seconds >= 60 { self.stop(message: "60-second dictation limit reached. Review this transcript before starting another."); return }
            }
        }
    }

    func stop(message: String = "Recording stopped. The final words may be incomplete; review and edit before inserting.") {
        generation = UUID() // Late permission/recognition callbacks cannot restart capture or overwrite edits.
        ticker?.cancel(); ticker = nil
        engine.stop()
        if installedTap { engine.inputNode.removeTap(onBus: 0); installedTap = false }
        request?.endAudio()
        recognitionTask?.cancel(); recognitionTask = nil; request = nil
        if activeAudioSession {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            activeAudioSession = false
        }
        busy = false; listening = false; status = message
    }
    func cancel() {
        stop(message: "Dictation canceled. Your existing note is unchanged.")
        transcript = ""
    }
}

struct FieldNote: Codable, Identifiable {
    var id = UUID()
    var property: PropertyRecord
    var text: String
    var createdAt = Date()
}
struct NoteDraft: Codable, Equatable {
    var text = ""
    var propertyID: UUID?
}

struct DictationView: View {
    @EnvironmentObject var store: RecordStore
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var dictation = DictationController()
    @State private var draft = NoteDraft()
    @State private var reviewed = false
    @State private var restored = false
    @State private var message: String?
    var body: some View {
        Form {
            Section("Dictate a field note") {
                Text("English (US), on-device only, up to 60 seconds. Audio is not saved or uploaded. On-device recognition must be available; otherwise type your note.").font(.footnote)
                Text(dictation.status)
                if dictation.listening { Label("Listening · \(dictation.seconds) seconds", systemImage: "mic.fill") }
                Button("Start dictation") { reviewed = false; dictation.start() }.disabled(dictation.busy || !dictation.transcript.isEmpty)
                if dictation.busy {
                    Button("Stop") { dictation.stop() }
                    Button("Cancel dictation", role: .cancel) { dictation.cancel() }
                }
                if !dictation.transcript.isEmpty {
                    TextEditor(text: $dictation.transcript).frame(minHeight: 100).disabled(dictation.busy).accessibilityLabel("Editable transcript")
                    Toggle("I checked product names, numbers, decimals and units", isOn: $reviewed).disabled(dictation.busy)
                    Button("Insert into note") {
                        draft.text += (draft.text.isEmpty ? "" : "\n") + dictation.transcript
                        dictation.cancel(); reviewed = false
                    }.disabled(dictation.busy || !reviewed || draft.text.count + dictation.transcript.count + 1 > 10000)
                    Button("Discard transcript", role: .destructive) { dictation.cancel(); reviewed = false }
                }
                Text("Transcript review does not validate a product, dose or application plan. Uninserted transcripts are not saved across app restarts.").font(.caption)
            }
            Section("Note draft") {
                Picker("Property", selection: $draft.propertyID) {
                    Text("Choose property").tag(Optional<UUID>.none)
                    ForEach(store.records.properties) { Text($0.name).tag(Optional($0.id)) }
                }
                TextEditor(text: $draft.text).frame(minHeight: 130).accessibilityLabel("Field note")
                Text("\(draft.text.count)/10000 characters. Draft text is saved locally.").font(.caption)
                Button("Save note") {
                    do { try store.saveNote(draft); draft = NoteDraft(); message = "Note saved locally." }
                    catch { message = "Could not save. Choose a property and enter 1–10000 characters; check storage access." }
                }.disabled(dictation.busy || draft.propertyID == nil || draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.text.count > 10000 || !store.canWrite)
                if let message { Text(message) }
            }
            Section("Saved notes") {
                ForEach(store.records.notes ?? []) { note in
                    VStack(alignment: .leading) {
                        Text(note.property.name).font(.headline)
                        Text(note.text).textSelection(.enabled)
                        Text(note.createdAt, style: .date).font(.caption)
                        Button("Delete note", role: .destructive) {
                            do { try store.deleteNote(id: note.id) }
                            catch { message = "Note could not be deleted." }
                        }
                    }
                }
            }
        }
        .navigationTitle("Field notes")
        .onAppear { if !restored { draft = store.records.noteDraft ?? NoteDraft(); restored = true } }
        .onChange(of: draft) { _, _ in
            guard restored else { return }
            do { try store.saveNoteDraft(draft) }
            catch { message = "Draft could not be saved. Keep this form open and check the 10000-character limit or storage access." }
        }
        .onChange(of: dictation.transcript) { _, _ in reviewed = false }
        .onChange(of: scenePhase) { _, phase in if phase == .background { dictation.stop(message: "Stopped when the app entered the background. Review partial text before inserting.") } }
        .onDisappear { dictation.stop() }
    }
}
