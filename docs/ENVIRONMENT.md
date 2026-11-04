# Development environment audit

Audit date: 2026-11-02 (America/New_York)

Read-only audit; no software was installed and no external services were configured. Results establish tool availability, not application compatibility or a successful native build.

## Verified available

| Component | Observed version | Evidence |
| --- | --- | --- |
| Windows | 10.0.26300.0 | OS version inspection |
| PowerShell | 7.6.5 | PowerShell version inspection |
| Node.js | v24.22.1 | Bundled executable `--version` completed |
| pnpm | 11.25.0 | Bundled executable `--version` completed |
| Git | 2.53.0.windows.3 | Bundled executable `--version` completed |
| Python | 3.12.14 | Bundled executable `--version` completed |

Verified executable paths:

```text
Node:   C:\Users\brasw\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe
pnpm:   C:\Users\brasw\.cache\codex-runtimes\codex-primary-runtime\dependencies\bin\fallback\pnpm.cmd
Git:    C:\Users\brasw\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe
Python: C:\Users\brasw\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe
```

The `python` command on PATH resolves to the WindowsApps alias. Use the verified bundled interpreter explicitly.

## Not found in bounded checks

- On PATH: npm, npx, Yarn, Java, Javac, adb, emulator, sdkmanager, Docker, Flutter, Dart, and xcodebuild.
- Environment variables `ANDROID_HOME`, `ANDROID_SDK_ROOT`, and `JAVA_HOME` are unset.
- Common installation locations for Android SDK/Android Studio, JDK, and Docker, plus standard user `.android`, `.gradle`, and `.expo` directories, were absent.

These checks do not establish that a tool is absent from every possible nonstandard location.

## Checks actually performed

1. Executed version checks for the bundled Node, pnpm, Git, and Python executables.
2. Inspected OS and PowerShell versions.
3. Used `Get-Command` to check common development executables.
4. Used bounded `Test-Path` checks for common native development installation locations.
5. Read only the three SDK/JDK environment variables listed above; no general environment-variable or credential dump was performed.
6. Inspected the current workspace and likely local source locations for the missing specification.

## Build and verification implications

- JavaScript or backend tooling can be evaluated once the full specification establishes the architecture. No framework, package compatibility, package retrieval, or network access has been validated.
- No local Android build/emulator capability is verified. After architecture selection, check for a nonstandard owner-installed SDK or provision the appropriate JDK/Android SDK/emulator.
- This Windows host cannot run local Xcode/iOS builds. A Mac or suitable remote macOS build service is required for iOS build evidence. No such access, Apple developer membership, signing identity, or store account has been inspected or assumed.
- A native device/emulator test route is still required for camera, microphone/dictation, location permissions, navigation, and saved-result persistence.
- No dependencies have been installed. No app/backend code has been compiled, run, or tested. No signing, store submission, deployment, or billing action has been performed.

## Setup tracking

| Need | When it becomes actionable | Current owner action |
| --- | --- | --- |
| Complete Version 3.0 source | Now, before implementation | Supply the existing path/link or attach the source |
| Android SDK/JDK and device/emulator route | After architecture selection | None requested yet; check for existing nonstandard installations first |
| Mac or remote macOS build route | Phase 0 build/release design | Access to be identified; no service selected or purchased |
| Backend and any speech/location services | When required by the specification and implementation | No provider selected; no credentials requested |
| Apple/Google developer and billing configuration | Release preparation | Prepare concrete setup/review artifacts before enabling publication or billing |

Store and service requirements must be checked against current official documentation when the actual architecture and release path are selected. This audit does not certify submission readiness.
