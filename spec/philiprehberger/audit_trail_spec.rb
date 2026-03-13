# frozen_string_literal: true

require "spec_helper"

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
