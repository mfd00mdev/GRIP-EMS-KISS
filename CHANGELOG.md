# Changelog

All notable changes to K.I.S.S. (Keep It Simple, Stupid) will be listed here.

## [0.1.1]

### Fixed
- Fixed . and other punctuation keys not binding correctly.
- Wizard no longer claims a bind worked when it didn't.
- Sequence names with spaces (e.g. DummyAnalyzer > Best (Solo)) can't be bound, unbound, or deleted here anymore — GRIP-EMS's own commands break on spaces. Reported upstream. Use GRIP-EMS's Keybind tab for those instead.

### Changed
- Bumped the `.toc` Interface version to match the current client (12.1.0).

## [0.1.0]

### Added
- Initial release of the guided setup wizard for GRIP-EMS.