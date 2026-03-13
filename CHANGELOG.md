# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-03-13

### Added
- Initial release
- `Event` data class for audit events with entity, action, changes, actor, and timestamp
- `Differ` module for computing field-level diffs between hashes
- `MemoryStore` thread-safe in-memory event storage
- `Tracker` class for recording, diffing, and querying audit events
