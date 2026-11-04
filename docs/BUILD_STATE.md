# Build state — 2026-11-03

## November 4 — private GitHub repository

### November 4 — runner capacity recovery and automatic builds

Run 41851076120 failed before any steps: simulator cancelled after 15m 2s, runner_id=0. GitHub annotations: Internal server error (correlation d81ab36a-a25c-43a2-975e-4a470e98f24d); job not acquired by hosted runner after multiple attempts; macOS ARM capacity constraints. This was not a compiler failure or evidence of depleted allowance. Owner authorized automatic builds and use of included allowance with no added money. Changed runner to standard macos-26-intel (official runner-images inventory confirms label and Xcode 26.6 default), added path-filtered main pushes, retained manual confirmation, variable gate, 25-minute timeout, read-only job token, and 3-day artifacts. Paid budget remains $0. A relevant push will retry on the Intel pool; success must be verified separately.

### November 4 — first cloud run submitted

Follow-up result check (GitHub API): existing run 41851076120 remains queued, attempt 1, conclusion null; simulator job 126647284551 also queued with no steps or logs URL. No build/test result is available. No additional run dispatched and no settings changed. Next: recheck this same run; inspect job logs once a runner starts.

User authorized continuation after allowance review. Set repository variable CLOUD_BUILD_ENABLED=true and verified saved value; dispatched exactly one manual run with confirm_compute=true on main commit 3ae48e01ee370d86c9239792921b865afb62f60f. Run https://github.com/braswelljustin1-web/turf-native/actions/runs/41851076120 ; job 126647284551. Last observed after approximately four minutes: Queued, condition evaluated true, waiting for hosted macos-26 runner. No checkout, compilation or tests observed yet; no result claimed. Existing 25-minute running-job timeout remains; queue wait is separate. Paid budget unchanged at $0. Publication/signing untouched. Gate remains true but workflow is manual only and each dispatch requires confirm_compute. Next: check this existing run to completion before dispatching another; inspect logs and save results. Screenshot docs/evidence/first-cloud-run.png. Local checkpoint not uploaded.

### November 4 — read-only allowance review

Signed-in GitHub Billing Overview verified GitHub Free, November 1-30 2026: $0 compute used / $12 included; Actions storage 0 GB / 0.5 GB; total billable Actions usage $0. Included limits reset in 27 days as displayed. Budgets page verified account-wide Actions budget $0.00, $0.00 spent, status Usage blocked; included-usage alerts On. GitHub documentation distinguishes budgets for paid use from included allowance. No settings changed, no workflow enabled/dispatched, no payment information collected. Next small batch: authorize one manual simulator build while preserving the $0 paid budget and existing 25-minute job timeout; execution eligibility remains untested. Sources: https://github.com/settings/billing and https://github.com/settings/billing/budgets and https://docs.github.com/en/billing/concepts/budgets-and-alerts . This local checkpoint is not uploaded.

Transfer verified: main points to 3ae48e01ee370d86c9239792921b865afb62f60f; all 39 expected file paths are present, with no truncated listing. GitHub reports zero workflow runs. Local verification evidence: docs/evidence/github-transfer.json. This checkpoint and evidence were saved after the source commit and are not yet uploaded. Next executable step: review account Actions allowance/spending controls, then obtain approval for one manually gated simulator build. No native build or device tests ran in this batch.

Verified owner-connected GitHub account: braswelljustin1-web. Created private repository https://github.com/braswelljustin1-web/turf-native and verified connector push/admin access. Initial README commit: c6fec725fb45662a31ac22de5d54f99e082b68df. The source transfer follows as one commit; final verification is recorded locally in docs/evidence/github-transfer.json when successful.

Cloud-build enable variable has not been set and no workflow was dispatched. Account compute allowance/spending controls remain unreviewed. Publication, signing and billing remain disabled. Native code remains SOURCE PREPARED, not BUILD VERIFIED.

## November 4 — transfer preparation

Owner said to go ahead after cloud configuration. GitHub is not connected and `gh` is not installed. GitHub plugin discovery found an available uninstalled connector; a connection suggestion was presented. The owner must complete secure sign-in/connection before repository access can be verified. Do not request passwords or tokens in chat.

Prepared scripts/package_source.py to package allowlisted project source, including .github/workflows, while excluding caches, private data and build artifacts. Output: build/transfer/turf-native-source.zip with source-manifest.json. Packaging checks include basic known credential patterns, ZIP integrity and per-file SHA-256 verification. Pattern scanning is not a complete secret/security audit.

No repository created, source uploaded, cloud variable enabled or build dispatched. Next: finish GitHub connection, inspect the authorized account and private-repository destination, then transfer source. Check account compute allowance/spending controls before enabling or dispatching the manual cloud job. Continue in small batches.

## Latest small batch: cloud build configuration

SOURCE PREPARED: `.github/workflows/ios-build.yml` and `scripts/ci_ios.py` define one manual macOS 26 unsigned simulator build/test job. Execution requires both the CLOUD_BUILD_ENABLED repository variable and explicit dispatch confirmation. Read-only repository access, no persisted checkout credentials, 25-minute job timeout, no automatic retries, one running workflow-group job, three-day evidence retention. No signing, Apple upload, publication or billing steps.

TEST RESULT: `python scripts/ci_ios.py --self-test` passed synthetic available-iPhone selection and missing-device failure cases on Windows. Python syntax compilation passed. Workflow YAML was inspected but a parser-based validation attempt could not run: the bundled js-yaml module is absent (PyYAML is also absent). No package was installed to expand this small batch. GitHub workflow acceptance and actual macOS execution remain unverified.

No repository was created or uploaded, no cloud run was started, no account costs were incurred by running this workflow, and no Apple credentials were requested. `docs/CLOUD_BUILD.md` contains the concrete configuration, owner setup, spending review and evidence retrieval steps. Private Actions usage/cost depends on the owner's account and is not known.

NEXT: owner reviews cloud setup and account allowance/spending controls, then authorizes source transfer to an owner-controlled private GitHub repository. After configuration is enabled and one run explicitly authorized, collect actual compiler/test evidence and fix reported failures. This unsigned route does not install an app on the user's iPhone; signing/distribution is a later reviewed setup.

## Latest small batch: on-device field-note dictation

TEST RESULT: `python scripts/generate_xcode.py` and `python scripts/check_project.py` completed successfully on Windows after this change. Six app/core sources and two test source files are referenced. Static checks include microphone/speech purpose keys and the absence of background modes. Evidence: docs/evidence/project-integrity.json. This is project-structure evidence only, not native compilation or microphone verification.

SOURCE PREPARED: Field Tools → Field notes and dictation. User-started English (US) recognition requires on-device capability, speech permission and microphone permission; unsupported/denied states retain typing. Editable transcript, visible listening/elapsed time, 60-second limit, stop/cancel and mandatory names/numbers/units review before insertion. Raw audio is not written to disk or sent by an app network path. No remote transcription fallback. Transcripts do not populate calculators or approve plans.

Capture cleanup covers background, leaving the view, call/audio interruption, route change, media reset, permission revocation monitoring and recognition errors. Generation tokens reject late callbacks after cancellation. Stop retains the latest partial text and warns that final words may be incomplete. Cancel discards only the current transcript. Typed/inserted note drafts persist locally with property selection; saved notes retain a property snapshot and can be deleted. Uninserted transcripts remain in memory only. Chat dictation/conversation integration remains pending.

Native note persistence/property-boundary/length/deletion test added but NOT executed. Still no macOS/Xcode runner or physical-iPhone test evidence. Next executable step is the native build and microphone checklist in SETUP.md. Next source increment, if requested within the small-batch budget, is persisted conversations and connecting the existing note/dictation workflow to Chat. Publication/billing remain disabled.

## Latest small batch: field photos

SOURCE PREPARED: Field Tools → Field photos now offers native still-camera capture, camera permission, native retake/cancel controls, selected-photo fallback, preview, explicit property association, local save and deletion. No microphone access, broad Photos-library permission, upload or AI analysis. Backgrounding dismisses the camera. Permission-dialog inactivity no longer cancels location acquisition prematurely.

Storage is bounded to four photos of at most 12 MB each in protected atomic local records. Imports retain received image bytes; camera images are encoded as JPEG and labeled accordingly. Previews are downsampled with orientation handling. Imported-photo dates mean import time. Unsaved previews are in memory only; durable media drafts and case/conversation integration remain pending.

TEST RESULT: project generation and static integrity checks passed on Windows, with five app/core sources and two test source files. Camera and When In Use location purpose strings are present; microphone, Always location and background access are absent. Added a native photo persistence/deletion/invalid-data test; it is NOT executed. No Swift compilation or device behavior is verified. See docs/evidence/project-integrity.json. Local xcodebuild/swift remain unavailable and no Mac host/CI is configured in this project. No remote connection was attempted.

NEXT: run the native build/device checklist when macOS access is available. Next small source increment: on-device dictation with editable transcript, stop/cancel/background recovery and text fallback. Publication/billing remain disabled. Continue small batches under the owner's usage constraint.

## Latest small batch: location and form drafts

SOURCE PREPARED: CoreLocation When In Use adapter, explicit user request, 20-second timeout, stale/invalid fix rejection, approximate accuracy and capture-time metadata, denial/restriction/manual fallback, cancellation on leaving/backgrounding. A captured fix never moves a saved property. It must be confirmed as the current property; country/locality/time zone remain manual, with no geocoding or remote upload.

SOURCE PREPARED: property and calculator edits persist through the protected atomic store, including incomplete numeric inputs. New optional fields preserve decoding of older records. Saving a property clears its draft atomically. Reopening requires fresh location confirmation; unsaved device fixes are deliberately not retained. Conversation drafts are still pending.

TEST RESULT: regenerated Xcode project and static integrity checks passed on Windows. Three native persistence/restart/legacy-decoding tests were added but NOT executed. CoreLocation and persistence behavior still require simulator and physical-iPhone verification; no native compilation occurred.

Next bounded step: run the macOS build when available, exercise location grant/denial/timeout/background and draft-restart tests, then add camera capture. Earlier pending-location/form-draft statements below are superseded by this source-prepared update; they are not evidence of native verification.

## Owner direction

OWNER REQUIREMENT: Focus on iPhone for now. Android is deferred, superseding the earlier two-platform milestone recorded in SPEC_RECEIVED.md.

OWNER REQUIREMENT: Use only 15% of Work usage right now. Account usage balance and a percentage spending limiter are not exposed to this session. This pass was deliberately limited to checking existing source, adding calculator tests, executing them, and saving this checkpoint. No claim of an exact percentage consumed is possible.

## Current workspace

Phase 0 reconciliation remains incomplete. Early calculator and development-backend source exists under backend/. A native iPhone project and first source slice now exist under ios/. No commit has been created. Current milestone status is SOURCE PREPARED; compilation and native behavior remain unverified.

The complete Version 3.0 specification was read in the previous session; source hash and intake are in SPEC_RECEIVED.md. Root REQUIREMENTS.csv and docs/SECTION_COVERAGE.csv remain provisional and must be reconciled before claiming Phase 0 complete.

## Implemented source

- Decimal-based calculator for area rates, tank coverage, recipe audit, percent volume, fertilizer, irrigation, calibration, tank splits, simple exclusions, pricing, residuals, seed and economics.
- Loopback-only development API with token authentication, owner-scoped SQLite records, idempotent calculation saves and version conflicts. This API has not been tested or deployed; it is not a production backend.
- Database migration source and calculator test suite.
- Native SwiftUI four-tab navigation, manual property form, protected atomic JSON storage, anonymous area-rate calculator, and saved calculation/property snapshots. Chat explicitly reports unavailable; no mock assistant replies.
- Deterministically generated Xcode app and XCTest targets with a shared scheme, Info.plist and initial privacy manifest. Four Swift calculator tests are written but not executed.
- Architecture/decision records, Phase A requirement rows and macOS build handoff in docs/ARCHITECTURE.md, docs/DECISIONS.md, docs/PHASE_A_REQUIREMENTS.csv and docs/SETUP.md.

## Actual test evidence

TEST RESULT: 2026-11-03, Windows, bundled Python 3.12.14, current uncommitted workspace.

Command: `python -m unittest backend.test_calculator -v` from the project directory, using the verified bundled Python executable.

Result: exit 0; 12 test methods passed. Covered N01, N02, N03, N04/N05, N06, N08, N11, N17, N18, N20, N38/N39 plus unknown residual and starting-water rejection. These are hypothetical arithmetic fixtures, not approved product rates. Remaining specification fixtures are not yet covered. No Swift parity, API, simulator, physical-device or store test has run.

TEST RESULT, continuation batch 2026-11-03: `python scripts/generate_xcode.py` completed, creating three app/core sources in the project plus one test source, two targets and a shared scheme. `python scripts/check_project.py` passed static object/reference, file-path, scheme and XML checks. Evidence: docs/evidence/project-integrity.json. This does not establish that Xcode can load or build the project.

## Remaining work and constraints

- Complete Phase 0 register, capability matrix, architecture, commercial assumptions, test plan and owner-action list.
- Compile and exercise the native source. Implement device location, camera, on-device dictation, persistent conversations/form drafts, complete species/zone context and measurement precision. Manual area setup and saved calculator source exist but are untested on iPhone.
- Test and harden the backend; managed production authentication, TLS, deployment and remote integrations are pending.
- Windows has no verified Swift/Xcode toolchain. Native compilation, signing and device testing require a Mac or configured macOS CI. No signing credentials are requested in chat.
- Apple documentation retrieved on 2026-11-02 reports Xcode 26+ and iOS 26 SDK for submission; deployment target is a separate decision. Recheck at submission: https://developer.apple.com/news/upcoming-requirements/
- Billing and publication remain disabled and require owner review before enabling.

## Next executable step

Continue Phase 0 register/capability/test-plan reconciliation, then add property-confirmed CoreLocation with manual fallback and persistent form drafts. If a macOS runner is available, execute the exact Xcode/Swift tests in docs/SETUP.md before claiming native functionality. Continue in small batches under the owner's usage constraint; an exact Work percentage cannot be measured. Camera and dictation follow as separate bounded increments. No new percentage allocation or reset is assumed.

