# Native build handoff

Windows users without a Mac: see [CLOUD_BUILD.md](CLOUD_BUILD.md) for the prepared manual GitHub macOS build route. It has not been enabled or executed. This first route builds/tests for Simulator only; physical-iPhone installation needs separate signing/distribution setup.

Latest dictation check: Field Tools → Field notes and dictation. On a physical iPhone, verify English (US) on-device support, contextual speech/microphone prompts, denial/restriction and typing fallback, no capture before Start, visible elapsed time, editable transcript after Stop, review-before-insert, Cancel preserving the typed draft, and the 60-second cap. Test airplane mode, headphones/route changes, a phone call, backgrounding, leaving the view and revoked permission. Confirm microphone indicators stop and no late callback resumes recording. Stop deliberately keeps the last partial transcript and identifies potential incomplete final words.

Insert reviewed text into a note, select its property, restart and verify draft recovery; save/restart/delete and verify property isolation. Uninserted transcripts are not durable and raw audio is not saved. No Chat integration, remote transcription, or realtime voice is implemented. These procedures and the new native persistence test are written but NOT executed. Microphone and speech purpose strings are now included; earlier statements below about their absence are historical.

Speech API references reviewed: [buffer recognition](https://developer.apple.com/documentation/speech/sfspeechaudiobufferrecognitionrequest), [on-device requirement](https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition). The current live-audio sample references newer APIs; this source uses the documented SFSpeech APIs compatible with the chosen iOS 17 deployment target.

Source prepared; no iOS compilation has run on this Windows machine.

On a Mac with Xcode 26+ and an installed iPhone simulator, from the project root:

```sh
python3 scripts/generate_xcode.py
xcodebuild -list -project ios/TurfOrnamentalPro.xcodeproj
xcodebuild -showdestinations -project ios/TurfOrnamentalPro.xcodeproj -scheme TurfOrnamentalPro
```

Select an available iPhone simulator UDID from that output, then run:

```sh
xcodebuild test -project ios/TurfOrnamentalPro.xcodeproj -scheme TurfOrnamentalPro -destination 'platform=iOS Simulator,id=REPLACE_WITH_AVAILABLE_UDID' CODE_SIGNING_ALLOWED=NO -resultBundlePath build/PhaseA.xcresult
```

The calculator can also be tested independently with `swift test --package-path ios`. Neither command has been executed here. Keep the result bundle and record Xcode/SDK, simulator/device, date and source version.

For a physical phone, open the project, select the owner's signing team and a unique bundle identifier in Xcode, then build and run. Do not paste credentials or signing keys into chat. `com.example.TurfOrnamentalPro` is a development placeholder, not an approved release identifier.

Current source journey: Properties → Add property manually → confirm country/locality/time zone → Field Tools → enter actual treated area, explicit rate/unit and basis → Calculate → select property → Save result → Library. Quit/relaunch and verify persistence. Try invalid numbers and change inputs after calculation; old output must disappear.

Pending: persisted form drafts/conversations, device location, camera, speech, measured display precision, complete species/zone model, accessibility/device checks, shared client/server fixture parity, app icon, production backend/authentication, privacy/release review and all later phases. No claim of a working native milestone until an actual build and journey pass.

Location update: the project requests When In Use location only. In New property, test Use my location, denial/manual fallback, timeout, cancellation and backgrounding. Confirm that a fix is attached only when the user confirms being at that property. Country/locality/time zone remain manual; geocoding is unavailable.

Camera update: Field Tools → Field photos → select property → Take photo or Choose existing photo → preview → Save. Test retake, cancel, denied/restricted/unavailable camera, backgrounding, import failure, orientation and oversize images. A still photo must not request microphone permission. Restart and verify saved images/property association, then delete one and verify the property remains. Imported bytes are retained; native captures are JPEG encoded and labeled. Limit: four photos, 12 MB each. Unsaved previews are not durable. Camera purpose is declared; microphone and broad photo-library access are absent. These procedures have NOT been executed on a device.

Draft update: enter unfinished property and calculator fields, close/relaunch and verify restoration. Confirm saving a property clears only its own draft. Run RecordStoreTests on the iOS test target; these tests have been written but not executed. The privacy manifest declares no off-device collection and no tracking; reassess every SDK/API addition and audit the built artifact before release.
