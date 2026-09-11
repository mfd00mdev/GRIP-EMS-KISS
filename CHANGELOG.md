# Changelog

All notable changes to K.I.S.S. (Keep It Simple, Stupid) will be listed here.

## [0.1.2]

### Added
- Now warns before letting you select a sequence with a space in its name.
- Fixed some anchorpoint issues for descriptions.
- Added textures in the nav arrows instead of unicode which can fail on different fonts.

### Fixed
- Fixed the Step 2 warning text bleeding past the edge of the window on some clients.
- Fixed the Previous/Next arrows showing as a placeholder character on clients using a custom UI font.

## [0.1.1]

### Fixed
- Binding punctuation keys (like `.`) now works correctly. Before this fix, K.I.S.S. sent the raw internal key name (like `PERIOD`) to GRIP-EMS instead of the character it actually displays, so the bind silently failed to match anything.
- K.I.S.S. no longer shows a sequence as "bound" unless the bind was actually sent to GRIP-EMS. Before this fix, the wizard could show a green success message even when the bind never went through.
- Sequences with a space in their name (like `DummyAnalyzer > Best (Solo)`) can no longer be bound, unbound, or deleted through the wizard. GRIP-EMS's own `/gems` commands can't read a full name once it hits a space, even in quotes, so trying anyway would either fail silently or, in the case of delete, risk deleting the wrong sequence entirely. This is a limitation in GRIP-EMS itself (already reported to their Discord), not something K.I.S.S. can work around. The wizard now warns you and points you to GRIP-EMS's own Keybind tab instead, where binding names with spaces works fine.

### Changed
- Bumped the `.toc` Interface version to match the current client (12.1.0).

## [0.1.0]

### Added
- Initial release of the guided setup wizard for GRIP-EMS.
- Step 1: pick an already-imported sequence, or get routed to GRIP-EMS's own import window (with LazyGrip and HouseOfMacros links if you don't have a sequence yet).
- Step 2: one-click key binding, applied through GRIP-EMS's own `/gems bind` command.
- Step 3: a troubleshooting checklist, plus a Discord link if something's still not working.
- Auto-opens on first install. Reopen anytime with `/gems kiss`.
