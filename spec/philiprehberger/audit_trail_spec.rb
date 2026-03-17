# frozen_string_literal: true

require "spec_helper"
require "json"
require "csv"

RSpec.describe Philiprehberger::AuditTrail do
  it "has a version number" do
    expect(Philiprehberger::AuditTrail::VERSION).not_to be_nil
  end
end

RSpec.describe Philiprehberger::AuditTrail::Event do
  subject(:event) do
    described_class.new(
      entity_id: "user:1",
      entity_type: "User",
      action: :create,
      changes: { name: { from: nil, to: "Alice" } },
      actor: "admin",
      metadata: { ip: "127.0.0.1" }
    )
  end

  it "stores entity_id" do
    expect(event.entity_id).to eq("user:1")
  end

  it "stores entity_type" do
    expect(event.entity_type).to eq("User")
  end

  it "stores action" do
    expect(event.action).to eq(:create)
  end

  it "stores actor" do
    expect(event.actor).to eq("admin")
  end

  it "has a timestamp" do
    expect(event.timestamp).to be_a(Time)
  end

  describe "#to_h" do
    it "returns a hash representation" do
      hash = event.to_h
      expect(hash[:entity_id]).to eq("user:1")
      expect(hash[:entity_type]).to eq("User")
      expect(hash[:action]).to eq(:create)
      expect(hash[:changes]).to eq(name: { from: nil, to: "Alice" })
      expect(hash[:actor]).to eq("admin")
      expect(hash[:metadata]).to eq(ip: "127.0.0.1")
      expect(hash[:timestamp]).to be_a(Time)
    end
  end

  it "defaults actor to nil" do
    evt = described_class.new(entity_id: "1", entity_type: "X", action: :delete)
    expect(evt.actor).to be_nil
  end

  it "defaults changes to empty hash" do
    evt = described_class.new(entity_id: "1", entity_type: "X", action: :delete)
    expect(evt.changes).to eq({})
  end

  it "defaults metadata to empty hash" do
    evt = described_class.new(entity_id: "1", entity_type: "X", action: :delete)
    expect(evt.metadata).to eq({})
  end
end

RSpec.describe Philiprehberger::AuditTrail::Differ do
  describe ".call" do
    it "detects changed fields" do
      diff = described_class.call(before: { name: "Alice" }, after: { name: "Bob" })
      expect(diff).to eq(name: { from: "Alice", to: "Bob" })
    end

    it "detects added fields" do
      diff = described_class.call(before: {}, after: { name: "Alice" })
      expect(diff).to eq(name: { from: nil, to: "Alice" })
    end

    it "detects removed fields" do
      diff = described_class.call(before: { name: "Alice" }, after: {})
      expect(diff).to eq(name: { from: "Alice", to: nil })
    end

    it "returns empty hash for identical hashes" do
      diff = described_class.call(before: { a: 1, b: 2 }, after: { a: 1, b: 2 })
      expect(diff).to eq({})
    end

    it "handles multiple changed fields" do
      diff = described_class.call(
        before: { name: "Alice", age: 30 },
        after: { name: "Bob", age: 31 }
      )
      expect(diff).to eq(name: { from: "Alice", to: "Bob" }, age: { from: 30, to: 31 })
    end
  end
end

RSpec.describe Philiprehberger::AuditTrail::MemoryStore do
  subject(:store) { described_class.new }

  let(:event) do
    Philiprehberger::AuditTrail::Event.new(entity_id: "1", entity_type: "User", action: :create)
  end

  describe "#push_all" do
    it "appends multiple events at once" do
      events = Array.new(3) do |i|
        Philiprehberger::AuditTrail::Event.new(entity_id: i.to_s, entity_type: "User", action: :create)
      end
      store.push_all(events)
      expect(store.size).to eq(3)
    end
  end

  describe "#reject!" do
    it "removes events matching the block" do
      store.push(event)
      store.push(Philiprehberger::AuditTrail::Event.new(entity_id: "2", entity_type: "Post", action: :delete))
      store.reject! { |e| e.entity_type == "User" }
      expect(store.size).to eq(1)
      expect(store.all.first.entity_type).to eq("Post")
    end
  end
end

RSpec.describe Philiprehberger::AuditTrail::Tracker do
  subject(:tracker) { described_class.new }

  describe "#record" do
    it "records an event and retrieves it" do
      tracker.record(entity_id: "1", entity_type: "User", action: :create, actor: "admin")
      expect(tracker.events.size).to eq(1)
      expect(tracker.events.first.action).to eq(:create)
    end
  end

  describe "#record_change" do
    it "computes diff and records an update event" do
      tracker.record_change(
        entity_id: "1",
        entity_type: "User",
        before: { name: "Alice" },
        after: { name: "Bob" },
        actor: "admin"
      )

      event = tracker.events.first
      expect(event.action).to eq(:update)
      expect(event.changes).to eq(name: { from: "Alice", to: "Bob" })
    end
  end

  describe "#history" do
    before do
      tracker.record(entity_id: "1", entity_type: "User", action: :create)
      tracker.record(entity_id: "1", entity_type: "User", action: :update)
      tracker.record(entity_id: "2", entity_type: "User", action: :create)
      tracker.record(entity_id: "1", entity_type: "Post", action: :create)
    end

    it "filters by entity_id" do
      results = tracker.history(entity_id: "1")
      expect(results.size).to eq(3)
    end

    it "filters by entity_id and entity_type" do
      results = tracker.history(entity_id: "1", entity_type: "User")
      expect(results.size).to eq(2)
    end
  end

  describe "#events" do
    it "returns all recorded events" do
      tracker.record(entity_id: "1", entity_type: "User", action: :create)
      tracker.record(entity_id: "2", entity_type: "Post", action: :delete)
      expect(tracker.events.size).to eq(2)
    end
  end

  describe "#clear!" do
    it "removes all events" do
      tracker.record(entity_id: "1", entity_type: "User", action: :create)
      tracker.clear!
      expect(tracker.events).to be_empty
    end
  end

  describe "#query" do
    before do
      tracker.record(entity_id: "1", entity_type: "User", action: :create, actor: "admin")
      tracker.record(entity_id: "2", entity_type: "Post", action: :update, actor: "editor")
      tracker.record(entity_id: "3", entity_type: "User", action: :delete, actor: "admin")
      tracker.record(entity_id: "1", entity_type: "User", action: :update, actor: "editor")
    end

    it "filters by actor" do
      results = tracker.query(actor: "admin")
      expect(results.size).to eq(2)
      expect(results.map(&:actor)).to all(eq("admin"))
    end

    it "filters by action" do
      results = tracker.query(action: :update)
      expect(results.size).to eq(2)
      expect(results.map(&:action)).to all(eq(:update))
    end

    it "filters by entity_id" do
      results = tracker.query(entity_id: "1")
      expect(results.size).to eq(2)
      expect(results.map(&:entity_id)).to all(eq("1"))
    end

    it "filters by multiple criteria" do
      results = tracker.query(actor: "admin", action: :create)
      expect(results.size).to eq(1)
      expect(results.first.entity_id).to eq("1")
    end

    it "filters by after" do
      cutoff = tracker.events[1].timestamp
      results = tracker.query(after: cutoff)
      expect(results.size).to eq(2)
    end

    it "filters by before" do
      cutoff = tracker.events[2].timestamp
      results = tracker.query(before: cutoff)
      expect(results.size).to eq(2)
    end

    it "combines actor and time filters" do
      cutoff = tracker.events[1].timestamp
      results = tracker.query(actor: "admin", after: cutoff)
      expect(results.size).to eq(1)
      expect(results.first.action).to eq(:delete)
    end

    it "returns all events when no filters given" do
      results = tracker.query
      expect(results.size).to eq(4)
    end
  end

  describe "#prune" do
    it "removes events older than the given time" do
      old_time = Time.now - 200 * 86_400
      recent_time = Time.now - 10 * 86_400
      tracker.record(entity_id: "1", entity_type: "User", action: :create, timestamp: old_time)
      tracker.record(entity_id: "2", entity_type: "User", action: :update, timestamp: recent_time)
      tracker.record(entity_id: "3", entity_type: "User", action: :delete, timestamp: Time.now)

      tracker.prune(before: Time.now - 90 * 86_400)
      expect(tracker.events.size).to eq(2)
      expect(tracker.events.map(&:entity_id)).to contain_exactly("2", "3")
    end

    it "removes nothing when all events are recent" do
      tracker.record(entity_id: "1", entity_type: "User", action: :create)
      tracker.prune(before: Time.now - 90 * 86_400)
      expect(tracker.events.size).to eq(1)
    end

    it "removes all events when all are old" do
      old_time = Time.now - 200 * 86_400
      tracker.record(entity_id: "1", entity_type: "User", action: :create, timestamp: old_time)
      tracker.record(entity_id: "2", entity_type: "User", action: :update, timestamp: old_time)
      tracker.prune(before: Time.now - 90 * 86_400)
      expect(tracker.events).to be_empty
    end
  end

  describe "#record_batch" do
    it "records multiple events at once" do
      entries = [
        { entity_id: "1", entity_type: "User", action: :create, actor: "admin" },
        { entity_id: "2", entity_type: "Post", action: :update, actor: "editor" },
        { entity_id: "3", entity_type: "User", action: :delete, actor: "admin" }
      ]
      result = tracker.record_batch(entries)
      expect(result.size).to eq(3)
      expect(tracker.events.size).to eq(3)
    end

    it "returns Event objects" do
      entries = [{ entity_id: "1", entity_type: "User", action: :create }]
      result = tracker.record_batch(entries)
      expect(result.first).to be_a(Philiprehberger::AuditTrail::Event)
    end

    it "preserves event attributes" do
      entries = [{ entity_id: "1", entity_type: "User", action: :create, actor: "bot", metadata: { source: "api" } }]
      tracker.record_batch(entries)
      event = tracker.events.first
      expect(event.actor).to eq("bot")
      expect(event.metadata).to eq(source: "api")
    end

    it "handles empty batch" do
      result = tracker.record_batch([])
      expect(result).to eq([])
      expect(tracker.events).to be_empty
    end
  end

  describe "#export" do
    before do
      tracker.record(entity_id: "1", entity_type: "User", action: :create, actor: "admin")
      tracker.record(entity_id: "2", entity_type: "Post", action: :update, actor: "editor")
    end

    describe "JSON format" do
      it "exports events as a JSON array" do
        output = tracker.export(:json)
        parsed = JSON.parse(output)
        expect(parsed).to be_an(Array)
        expect(parsed.size).to eq(2)
      end

      it "includes all event fields" do
        output = tracker.export(:json)
        parsed = JSON.parse(output)
        entry = parsed.first
        expect(entry).to have_key("entity_id")
        expect(entry).to have_key("entity_type")
        expect(entry).to have_key("action")
        expect(entry).to have_key("actor")
        expect(entry).to have_key("timestamp")
      end

      it "serializes action as string" do
        output = tracker.export(:json)
        parsed = JSON.parse(output)
        expect(parsed.first["action"]).to eq("create")
      end

      it "serializes timestamp as ISO 8601" do
        output = tracker.export(:json)
        parsed = JSON.parse(output)
        expect { Time.iso8601(parsed.first["timestamp"]) }.not_to raise_error
      end
    end

    describe "CSV format" do
      it "exports events as CSV with headers" do
        output = tracker.export(:csv)
        rows = CSV.parse(output)
        expect(rows.first).to eq(%w[entity_id entity_type action actor timestamp])
        expect(rows.size).to eq(3) # header + 2 data rows
      end

      it "includes event data in rows" do
        output = tracker.export(:csv)
        rows = CSV.parse(output)
        expect(rows[1][0]).to eq("1")
        expect(rows[1][1]).to eq("User")
        expect(rows[1][2]).to eq("create")
        expect(rows[1][3]).to eq("admin")
      end
    end

    it "raises ArgumentError for unsupported format" do
      expect { tracker.export(:xml) }.to raise_error(ArgumentError, /unsupported format/)
    end
  end

  describe "#summary" do
    before do
      tracker.record(entity_id: "1", entity_type: "User", action: :create, actor: "admin")
      tracker.record(entity_id: "2", entity_type: "Post", action: :update, actor: "editor")
      tracker.record(entity_id: "3", entity_type: "User", action: :create, actor: "admin")
      tracker.record(entity_id: "1", entity_type: "User", action: :update, actor: "editor")
    end

    it "groups by actor" do
      result = tracker.summary(group_by: :actor)
      expect(result).to eq("admin" => 2, "editor" => 2)
    end

    it "groups by action" do
      result = tracker.summary(group_by: :action)
      expect(result).to eq(create: 2, update: 2)
    end

    it "groups by entity_id" do
      result = tracker.summary(group_by: :entity_id)
      expect(result).to eq("1" => 2, "2" => 1, "3" => 1)
    end

    it "raises ArgumentError for invalid group_by key" do
      expect { tracker.summary(group_by: :timestamp) }.to raise_error(ArgumentError, /invalid group_by/)
    end

    it "returns empty hash when no events" do
      empty_tracker = described_class.new
      result = empty_tracker.summary(group_by: :actor)
      expect(result).to eq({})
    end
  end

  describe "pluggable store" do
    it "works with a custom store that responds to the required interface" do
      custom_store = Class.new do
        def initialize
          @events = []
        end

        def push(event)
          @events << event
          event
        end

        def select(&block)
          @events.select(&block)
        end

        def all
          @events.dup
        end

        def clear!
          @events.clear
        end

        def size
          @events.size
        end
      end.new

      custom_tracker = described_class.new(store: custom_store)
      custom_tracker.record(entity_id: "1", entity_type: "User", action: :create)
      expect(custom_tracker.events.size).to eq(1)
    end
  end
end
