# frozen_string_literal: true

module Philiprehberger
  module AuditTrail
    # Main tracker class for recording and querying audit events.
    class Tracker
      # @param store [#push, #select, #all, #clear!, #size] pluggable event storage
      def initialize(store: MemoryStore.new)
        @store = store
      end

      # Record an audit event.
      #
      # @param entity_id [String] identifier of the audited entity
      # @param entity_type [String] type/class of the audited entity
      # @param action [Symbol] the action performed
      # @param changes [Hash] hash of field changes
      # @param actor [String, nil] who performed the action
      # @param metadata [Hash] additional context
      # @return [Event] the recorded event
      def record(entity_id:, entity_type:, action:, changes: {}, actor: nil, metadata: {})
        event = Event.new(
          entity_id: entity_id, entity_type: entity_type,
          action: action, changes: changes,
          actor: actor, metadata: metadata
        )
        @store.push(event)
      end

      # Compute the diff between two hashes.
      #
      # @param before [Hash] the original state
      # @param after [Hash] the new state
      # @return [Hash] changed fields
      def diff(before, after)
        Differ.call(before: before, after: after)
      end

      # Diff two hashes and record the change as an :update event.
      #
      # @param entity_id [String] identifier of the audited entity
      # @param entity_type [String] type/class of the audited entity
      # @param before [Hash] the original state
      # @param after [Hash] the new state
      # @param actor [String, nil] who performed the action
      # @param metadata [Hash] additional context
      # @return [Event] the recorded event
      def record_change(entity_id:, entity_type:, before:, after:, actor: nil, metadata: {})
        changes = Differ.call(before: before, after: after)
        record(
          entity_id: entity_id, entity_type: entity_type,
          action: :update, changes: changes,
          actor: actor, metadata: metadata
        )
      end

      # Query events for a specific entity.
      #
      # @param entity_id [String] identifier to filter by
      # @param entity_type [String, nil] optional type filter
      # @return [Array<Event>] matching events
      def history(entity_id:, entity_type: nil)
        @store.select do |event|
          matches_entity?(event, entity_id, entity_type)
        end
      end

      # Return all stored events.
      #
      # @return [Array<Event>] all events
      def events
        @store.all
      end

      # Remove all events from the store.
      #
      # @return [void]
      def clear!
        @store.clear!
      end

      private

      def matches_entity?(event, entity_id, entity_type)
        return false unless event.entity_id == entity_id
        return true if entity_type.nil?

        event.entity_type == entity_type
      end
    end
  end
end
