# philiprehberger-audit_trail

[![Tests](https://github.com/philiprehberger/rb-audit-trail/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-audit-trail/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-audit_trail.svg)](https://rubygems.org/gems/philiprehberger-audit_trail)

Generic audit trail for tracking changes with who, what, and when.

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-audit_trail"
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install philiprehberger-audit_trail
```

## Usage

```ruby
require "philiprehberger/audit_trail"

tracker = Philiprehberger::AuditTrail::Tracker.new

# Record an event directly
tracker.record(
  entity_id: "user:1",
  entity_type: "User",
  action: :create,
  changes: { name: { from: nil, to: "Alice" } },
  actor: "admin"
)
```

### Automatic Diff and Record

```ruby
before = { name: "Alice", email: "alice@example.com" }
after  = { name: "Alice", email: "alice@new.com", role: "admin" }

tracker.record_change(
  entity_id: "user:1",
  entity_type: "User",
  before: before,
  after: after,
  actor: "system"
)
# Automatically computes: { email: { from: "alice@example.com", to: "alice@new.com" },
#                           role:  { from: nil, to: "admin" } }
```

### Querying History

```ruby
# All events for an entity
tracker.history(entity_id: "user:1")

# Filter by entity type
tracker.history(entity_id: "user:1", entity_type: "User")

# All events
tracker.events
```

### Hash Diffing

```ruby
diff = tracker.diff(
  { name: "Alice", age: 30 },
  { name: "Bob", age: 30 }
)
# => { name: { from: "Alice", to: "Bob" } }
```

### Pluggable Storage

```ruby
# Default: in-memory store
tracker = Philiprehberger::AuditTrail::Tracker.new

# Custom store (must respond to push, select, all, clear!, size)
tracker = Philiprehberger::AuditTrail::Tracker.new(store: MyCustomStore.new)
```

## API

| Method / Class | Description |
|----------------|-------------|
| `Tracker.new(store:)` | Create a tracker with pluggable storage (default: `MemoryStore`) |
| `Tracker#record(entity_id:, entity_type:, action:, ...)` | Record an audit event |
| `Tracker#record_change(entity_id:, entity_type:, before:, after:, ...)` | Diff and record an update event |
| `Tracker#diff(before, after)` | Compute field-level diff between two hashes |
| `Tracker#history(entity_id:, entity_type:)` | Query events by entity |
| `Tracker#events` | Return all stored events |
| `Tracker#clear!` | Remove all events |
| `Event.new(entity_id:, entity_type:, action:, ...)` | Create an audit event |
| `Event#to_h` | Hash representation of the event |
| `Differ.call(before:, after:)` | Compute diff between two hashes |
| `MemoryStore.new` | Thread-safe in-memory event store |
| `MemoryStore#push(event)` | Append an event |
| `MemoryStore#select(&block)` | Filter events |
| `MemoryStore#all` | Return all events |
| `MemoryStore#clear!` | Remove all events |
| `MemoryStore#size` | Count of events |

## Development

```bash
bundle install
bundle exec rspec      # Run tests
bundle exec rubocop    # Check code style
```

## License

MIT
