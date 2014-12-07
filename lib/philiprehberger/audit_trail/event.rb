# frozen_string_literal: true

module Philiprehberger
  module AuditTrail
    # Immutable data class representing a single audit event.
    class Event
      attr_reader :entity_id, :entity_type, :action, :changes, :actor, :metadata, :timestamp

      # @param entity_id [String] identifier of the audited entity
      # @param entity_type [String] type/class of the audited entity
      # @param action [Symbol] the action performed (:create, :update, :delete)
      # @param changes [Hash] hash of field changes
      # @param actor [String, nil] who performed the action
      # @param metadata [Hash] additional context
      # @param timestamp [Time] when the event occurred
      def initialize(entity_id:, entity_type:, action:, **opts)
        @entity_id = entity_id
        @entity_type = entity_type
        @action = action
        @changes = opts.fetch(:changes, {})
        @actor = opts[:actor]
        @metadata = opts.fetch(:metadata, {})
        @timestamp = opts.fetch(:timestamp, Time.now)
      end

      # Returns a hash representation of the event.
      #
      # @return [Hash] all event attributes as a hash
      def to_h
        {
          entity_id: @entity_id,
          entity_type: @entity_type,
          action: @action,
          changes: @changes,
          actor: @actor,
          metadata: @metadata,
          timestamp: @timestamp
        }
      end
    end
  end
end
