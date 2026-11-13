# BilibiliLive

Native tvOS Bilibili client, targeting tvOS 16+. `BilibiliLive/Module` owns screens and navigation; `Component` owns shared feed and player UI; `Request` owns service calls and account persistence; `Vendor` contains bundled integrations. For feed, player and dependency details, read `docs/agent-reference.md`.

Build with `xcodebuild -project BilibiliLive.xcodeproj -scheme BilibiliLive -destination 'generic/platform=tvOS' CODE_SIGNING_ALLOWED=NO build`. Fastlane's `build_simulator` and `build_unsign_ipa` lanes are available for their respective artifacts. There is no dedicated test suite; build affected targets, exercise remote focus on a simulator, and verify device behavior when the change requires it.

Use native tvOS controls and system materials, preserve remote focus and readable typography, and share existing feed/player components rather than creating parallel implementations. Follow user preferences for navigation and account handling. Keep app state and credentials local; never commit cookies, tokens, signing profiles or personal content. Preserve unrelated workspace edits.

Pixel icon source is `Artwork/pixel-icon.png`; regenerate the layered icon and App Store assets with `swift scripts/generate-pixel-icon.swift`, then commit source and generated files together. Keep SPM resolved versions and generated protocol files under their existing project conventions. Distinguish simulator, mock and real-device evidence.
