# Cloud iPhone build from Windows

Private repository: https://github.com/braswelljustin1-web/turf-native . The first cloud attempt failed before checkout because GitHub could not allocate an ARM runner. See BUILD_STATE for current run evidence.

## What is prepared

`.github/workflows/ios-build.yml` runs on the standard macos-26-intel runner to avoid the ARM capacity failure. GitHub's runner image inventory lists Xcode 26.6 as default. It generates the Xcode project, checks its structure, runs the Python calculator tests, then builds and runs the native XCTest suite on an available iPhone simulator. It requires Xcode 26+ and fails if a compatible simulator is unavailable; it does not install large runtimes automatically.

This is an unsigned simulator build. It cannot install on your physical iPhone and does not produce a signed IPA, TestFlight upload or App Store submission. No Apple account, signing certificate, provider key or paid developer membership is needed for this unsigned test job.

The owner authorized automatic builds on relevant main-branch pushes (ios, backend, scripts, or this workflow). Documentation-only pushes do not build. Manual dispatch remains available with its confirmation checkbox. Both paths require CLOUD_BUILD_ENABLED=true. This gate is not a billing cap. The account's $0 paid Actions budget is unchanged; included allowance is used first. Job timeout: 25 minutes. One running job at a time; additional requests can queue. Artifact retention: three days. No scheduled builds or automated retries.

## Owner setup, before running

1. Use an owner-controlled **private GitHub repository** for the source. Do not make the code public merely to obtain free runner time.
2. Review the GitHub account's included Actions usage and spending controls, including any overage and storage charges. Configure the desired spending limit before enabling compute. Included minutes or free access have not been verified for this account.
3. Transfer the project source into that repository, preserving `.github/workflows`. Use Git/GitHub Desktop or an authorized upload workflow that respects `.gitignore`. Do not upload `.env`, private data, captures, build outputs, credentials or unrelated Downloads files. No repository creation/upload is authorized or performed by this configuration-only batch.
4. Put the workflow on the repository's default branch. Allow GitHub-owned Actions if the account's policy requires it. Dependencies currently use the documented `actions/checkout@v7` and `actions/upload-artifact@v7` major-version tags; these tags may move. For stronger reproducibility, review and pin exact release SHAs before the first run.
5. After reviewing the concrete configuration and account costs, add the repository Actions variable `CLOUD_BUILD_ENABLED` with value `true` under Settings → Secrets and variables → Actions → Variables. No secret is needed.
6. Open Actions → **iPhone simulator build (manual only)** → Run workflow. Select the reviewed branch and check the compute confirmation box for one run.

## Review the result

Download `iphone-simulator-evidence-<run>-<attempt>` from the run page within three days. It contains `run.json`, individual command logs and, if Xcode reached testing, `PhaseA.xcresult`. Open the text logs on Windows; the result bundle can be inspected later with Xcode. A green workflow means only the checks that actually ran passed; inspect the native test result before upgrading BUILD_STATE to BUILD VERIFIED.

If the build fails, retain the first actual compiler/test error from `xcode-tests.txt` or `xcode-project.txt`. Do not keep rerunning unchanged failing source. If the job is skipped, check the two explicit enable conditions. If it times out, the job itself is the authoritative failure record; the process may not have finalized run.json or uploaded all evidence.

To stop future runs, remove `CLOUD_BUILD_ENABLED` or change it to `false`. Cancel an already-running job separately from Actions.

## What follows a successful simulator build

Physical-iPhone installation needs a separate signing/distribution setup. Prepare that later for owner review; no certificates, Apple credentials, TestFlight settings, billing products or publication steps are in this workflow. Simulator success does not verify actual camera/microphone permission, hardware capture or interruptions.

## Official sources checked for this configuration

- [GitHub macOS runners and private-repository usage](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
- [Checkout action](https://github.com/actions/checkout)
- [Artifact upload and retention](https://github.com/actions/upload-artifact)

Configuration prepared November 3, 2026. Account eligibility, actual cost and first cloud execution remain unknown.

