# Build state

CURRENT CHECKPOINT: See docs/BUILD_STATE.md (2026-11-03). It supersedes the historical intake status below, records iPhone-only scope and the limited-work batch, and includes executed calculator test results.

Updated: 2026-11-02 (America/New_York)

## Current status

Phase 0 is in progress. Phase A has not started.

The user requires the complete Version 3.0 master specification to be read before implementation. That document was not supplied in the visible conversation, the chat attachment inventory returned no artifacts, and bounded local filename searches did not locate it. A request for its existing path or accessible link is pending.

This directory contains project intake records only. It does not contain a working application, backend, native build, or completed milestone. The directory name `turf-native` is provisional; no product name or architecture has been selected.

## Authorized scope

1. Read the entire Version 3.0 master specification.
2. Complete Phase 0, then implement Phase A as defined by that specification.
3. Build a native iPhone and Android application with a secure backend and a verifiable Apple App Store submission path.
4. Preserve warm-season turf, cool-season turf, ornamentals, property-specific location guidance, native camera capture, microphone dictation, and deterministic calculators.
5. Deliver a first working milestone with native navigation, saved properties, location setup with manual fallback, camera and microphone permission/capture flows, and a working calculator with saved results.
6. Maintain actual project files, a requirements register, and continuation notes; run supported checks.
7. Identify external services and necessary owner setup; keep credentials outside source code.
8. Prepare publication and billing for review before enabling either.

## Records

- `REQUIREMENTS.csv`: provisional requirements extracted only from the user's message. It is not a substitute for the missing specification.
- `docs/SOURCE_INTAKE.md`: source availability, read status, and next intake procedure.
- `docs/ENVIRONMENT.md`: completed read-only environment audit and native build limitations.

## Completed work and actual verification

- Created this project intake directory, a provisional register containing 28 user-message requirements, a source-intake record, an environment audit, and credential/build-output ignore rules.
- Verified project-record integrity: 28 CSV rows, zero duplicate IDs, zero missing required fields, and all five expected files present. This check passed; it is not an application test.
- Verified executable versions: Node v24.22.1, pnpm 11.25.0, Git 2.53.0.windows.3, Python 3.12.14; host is Windows 10.0.26300.0 with PowerShell 7.6.5.
- No Android SDK/JDK was found on PATH or in checked common locations. Local iOS builds require macOS; a remote build route is not configured.
- No application code, backend, packages, native build, device test, or calculator test exists yet. No publication or billing has been enabled.

## Blocking conditions

1. Missing Version 3.0 master specification prevents the required full read and actual Phase 0/Phase A scope reconciliation.
2. Native build and device-test infrastructure remains unconfigured. This does not prevent later source implementation, but it limits what can be verified on this machine.

## Decisions and constraints

- Do not invent the specification's Phase 0 or Phase A definitions.
- Do not select a framework, backend provider, calculator formula, product rate, or external service until the complete specification has been read.
- Microphone recording alone must not be reported as completed dictation.
- A web preview, JavaScript check, or generated native project alone must not be reported as a tested native application.
- Publication and billing remain disabled. Do not create a paid subscription, deploy publicly, submit to a store, or enable purchases without the required review.
- No credentials have been requested, read, or added to these project files.

## Next executable step

Obtain the Version 3.0 specification through the pending file-path/link request (or a new attachment), read it end to end, record its exact filename/version/hash and page or section coverage, and reconcile every requirement into the register. Then complete the actual Phase 0 decisions and acceptance criteria before starting Phase A.

## Continuation rules

Resume from these files; do not treat provisional prompt requirements as full specification coverage. Update requirement statuses only with concrete implementation and verification evidence. Record exact commands, outcomes, blockers, and the next executable step after each implementation milestone.

## Superseding intake update
The source is now available and fully read. The missing-source blocker above is resolved. See docs/SPEC_RECEIVED.md and docs/SECTION_COVERAGE.csv. Phase 0 remains in progress; Phase A has not started.
