# Initial architecture

SwiftUI presentation → typed property/calculation records → pure Foundation calculation core → protected local JSON persistence.

Native location, camera and on-device speech adapters will be added next, with user-initiated permissions and manual/text fallbacks. They are not implemented in this batch. No remote upload or AI request exists in the client.

The existing Python/SQLite development API is loopback-only and separate from the app. Managed authentication, transactional production database, private object storage, bounded jobs, provider secrets and deployment are subsequent backend work. Do not expose the current development server publicly.

Build route: generated `ios/TurfOrnamentalPro.xcodeproj` → Xcode on macOS → simulator tests → physical iPhone permissions/persistence checks → authorized signing and distribution archive → validation → owner review → TestFlight/submission only when authorized.

Current block: no macOS/Xcode runner is connected. Source and structural checks cannot prove compilation or device behavior.
