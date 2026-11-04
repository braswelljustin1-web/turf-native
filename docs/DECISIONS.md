# Decisions — 2026-11-03

- OWNER REQUIREMENT: iPhone now; Android deferred. No publication or billing activation.
- DESIGN DECISION: SwiftUI, iPhone-only, minimum iOS 17, Swift 5 language mode; use Xcode 26+ and iOS 26 SDK for the documented current submission path. Minimum supported OS is distinct from build SDK. iPad is not claimed tested.
- DESIGN DECISION: dependency-free native source and deterministic project generator. Python standard library generates a checked-in Xcode project; no project-generation package needs installation.
- DESIGN DECISION: local protected JSON storage for the first small single-user slice. Atomic saves happen before success is shown; read failures prevent overwriting existing records. Cloud sync and production authentication remain Phase B work.
- DESIGN DECISION: first native calculator handles anonymous area-rate arithmetic with explicit mass/liquid units. No product identity, catalog approval, or chemical recommendation is implied. Swift Decimal and the Python decimal engine must pass shared fixtures before parity is claimed.
- DESIGN DECISION: current public interface uses English and explicit decimal-point input; grouping and decimal commas are rejected with an explanation until locale-aware entry is implemented.
- UNKNOWN: Mac/CI access, owner bundle ID, signing team, provider accounts, qualified product reviewers, commercial demand and selected pricing.
- DESIGN DECISION: preserve all specification sections in the existing coverage map; later capabilities are planned, not advertised as available. Phase 0 full register decomposition and commercial evidence preparation remain incomplete.
