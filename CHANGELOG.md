# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-04-09

### Added
- `query` now supports `entity_type:` filter
- `query` filters (`actor:`, `action:`, `entity_id:`, `entity_type:`) accept arrays for "value is one of" semantics

## [0.2.7] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.2.6] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.2.5] - 2026-03-26

### Changed

- Add Sponsor badge and fix License link format in README

## [0.2.4] - 2026-03-24

### Changed
- Expand test coverage to 65+ examples covering edge cases and error paths

## [0.2.3] - 2026-03-24

### Fixed
- Fix README one-liner to remove trailing period

## [0.2.2] - 2026-03-24

### Fixed
- Remove inline comments from Development section to match template

## [0.2.1] - 2026-03-22

### Changed
- Update rubocop configuration for Windows compatibility

## [0.2.0] - 2026-03-17

### Added
- Query builder: `query(actor:, action:, entity_id:, after:, before:)` for filtering events by multiple criteria
- Retention policy: `prune(before:)` to delete events older than a specified time
- Batch recording: `record_batch(entries)` to record multiple events in one call
- Export: `export(:json)` and `export(:csv)` to export audit log entries in structured formats
- Summary: `summary(group_by:)` to aggregate counts grouped by actor, action, or entity_id
- `MemoryStore#push_all` for batch event storage
- `MemoryStore#reject!` for retention policy support

## [0.1.3] - 2026-03-16

### Changed
- Add License badge to README
- Add bug_tracker_uri to gemspec

## [0.1.2] - 2026-03-13

### Fixed
- Reduce keyword parameters to ≤5 using `**opts` in Event, Tracker#record, Tracker#record_change

## [0.1.1] - 2026-03-13

## [0.1.0] - 2026-03-13

### Added
- Initial release
- `Event` data class for audit events with entity, action, changes, actor, and timestamp
- `Differ` module for computing field-level diffs between hashes
- `MemoryStore` thread-safe in-memory event storage
- `Tracker` class for recording, diffing, and querying audit events
