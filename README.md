# philiprehberger-audit_trail

[![Tests](https://github.com/philiprehberger/rb-audit-trail/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-audit-trail/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-audit_trail.svg)](https://rubygems.org/gems/philiprehberger-audit_trail)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-audit-trail)](https://github.com/philiprehberger/rb-audit-trail/commits/main)

Generic audit trail for tracking changes with who, what, and when

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-audit_trail"
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

### Query Builder

```ruby
# Filter by actor
tracker.query(actor: "admin")

# Filter by action
tracker.query(action: :update)

# Filter by entity_id
tracker.query(entity_id: "user:1")

# Filter by entity_type
tracker.query(entity_type: "User")

# Array filters: match any of the listed values
tracker.query(action: [:create, :update])
tracker.query(actor: ["alice", "bob"], entity_type: ["User", "Post"])

# Filter by time range
tracker.query(after: Time.now - 86_400, before: Time.now)

# Combine multiple filters
tracker.query(actor: "admin", action: :update, after: Time.now - 7 * 86_400)
```

### Counting Events

```ruby
# Total event count
tracker.count
# => 4

# Count with the same filters as query
tracker.count(actor: 'admin')
tracker.count(action: :update)
tracker.count(actor: 'admin', action: :create)
tracker.count(after: Time.now - 86_400, before: Time.now)
```

### Batch Recording

```ruby
tracker.record_batch([
  { entity_id: "1", entity_type: "User", action: :create, actor: "admin" },
  { entity_id: "2", entity_type: "Post", action: :update, actor: "editor" },
  { entity_id: "3", entity_type: "User", action: :delete, actor: "admin" }
])
```

### Retention Policy

```ruby
# Remove events older than 90 days
tracker.prune(before: Time.now - 90 * 86_400)
```

### Export

```ruby
# Export as JSON
json_output = tracker.export(:json)
# => '[{"entity_id":"1","entity_type":"User","action":"create",...}]'

# Export as CSV
csv_output = tracker.export(:csv)
# => "entity_id,entity_type,action,actor,timestamp\n1,User,create,admin,..."
```

### Summary

```ruby
# Count events grouped by actor
tracker.summary(group_by: :actor)
# => { "admin" => 5, "editor" => 3 }

# Count events grouped by action
tracker.summary(group_by: :action)
# => { create: 4, update: 3, delete: 1 }

# Count events grouped by entity_id
tracker.summary(group_by: :entity_id)
# => { "1" => 3, "2" => 2 }
```

### Count By Field

```ruby
# Tally events by any Event accessor; keys are ordered by insertion.
tracker.count_by(:action)
# => { create: 2, update: 1, delete: 1 }

tracker.count_by(:actor)
# => { "admin" => 2, "editor" => 2 }

# Combine with query-style filters to count only the filtered subset.
tracker.count_by(:action, actor: 'admin')
# => { create: 1, delete: 1 }
```

### Replay State

```ruby
tracker.record(
  entity_id: "user:1", entity_type: "User", action: :create,
  changes: { name: { from: nil, to: "Alice" }, role: { from: nil, to: "member" } }
)
tracker.record(
  entity_id: "user:1", entity_type: "User", action: :update,
  changes: { role: { from: "member", to: "admin" } }
)

tracker.replay(entity_id: "user:1")
# => { name: "Alice", role: "admin" }

# Point-in-time snapshot
tracker.replay(entity_id: "user:1", until_time: Time.now - 60)
# => { name: "Alice", role: "member" }
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

# Custom store (must respond to push, push_all, select, reject!, all, clear!, size)
tracker = Philiprehberger::AuditTrail::Tracker.new(store: MyCustomStore.new)
```

## API

| Method / Class | Description |
|----------------|-------------|
| `Tracker.new(store:)` | Create a tracker with pluggable storage (default: `MemoryStore`) |
| `Tracker#record(entity_id:, entity_type:, action:, ...)` | Record an audit event |
| `Tracker#record_change(entity_id:, entity_type:, before:, after:, ...)` | Diff and record an update event |
| `Tracker#record_batch(entries)` | Record multiple events in one call |
| `Tracker#diff(before, after)` | Compute field-level diff between two hashes |
| `Tracker#history(entity_id:, entity_type:)` | Query events by entity |
| `Tracker#query(actor:, action:, entity_id:, entity_type:, after:, before:)` | Filter events by multiple criteria (scalar or array values) |
| `Tracker#count(**filters)` | Count stored events, optionally filtered with the same keywords as `query` |
| `Tracker#prune(before:)` | Delete events older than the specified time |
| `Tracker#export(format)` | Export events as `:json` or `:csv` |
| `Tracker#summary(group_by:)` | Aggregate counts by `:actor`, `:action`, or `:entity_id` |
| `Tracker#count_by(field, **filters)` | Tally events grouped by any Event accessor, optionally filtered with `query` keywords |
| `Tracker#replay(entity_id:, entity_type:, until_time:)` | Reconstruct entity state by replaying recorded events in chronological order |
| `Tracker#events` | Return all stored events |
| `Tracker#clear!` | Remove all events |
| `Event.new(entity_id:, entity_type:, action:, ...)` | Create an audit event |
| `Event#to_h` | Hash representation of the event |
| `Differ.call(before:, after:)` | Compute diff between two hashes |
| `MemoryStore.new` | Thread-safe in-memory event store |
| `MemoryStore#push(event)` | Append an event |
| `MemoryStore#push_all(events)` | Append multiple events |
| `MemoryStore#select(&block)` | Filter events |
| `MemoryStore#reject!(&block)` | Remove matching events |
| `MemoryStore#all` | Return all events |
| `MemoryStore#clear!` | Remove all events |
| `MemoryStore#size` | Count of events |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-audit-trail)

🐛 [Report issues](https://github.com/philiprehberger/rb-audit-trail/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-audit-trail/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
