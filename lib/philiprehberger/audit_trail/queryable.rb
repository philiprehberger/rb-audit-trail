# frozen_string_literal: true

module Philiprehberger
  module AuditTrail
    # Query builder for filtering audit events by multiple criteria.
    module Queryable
      COUNT_BY_ALLOWED_FIELDS = %i[entity_id entity_type action changes actor metadata timestamp].freeze

      # Filter events by actor, action, entity_id, after, and before.
      #
      # @param filters [Hash] filter criteria
      # @return [Array<Event>] matching events
      def query(**filters)
        @store.select do |event|
          matches_filters?(event, filters)
        end
      end

      # Aggregate event counts grouped by the value of the given field.
      #
      # Iterates every event in the current filtered set (all stored events
      # when no filters are supplied, otherwise the result of {#query}) and
      # returns a `{value => count}` Hash. Keys are ordered by insertion.
      # Events whose accessor returns `nil` are grouped under `nil`.
      #
      # @param field [Symbol, String] Event accessor to group by
      # @param filters [Hash] optional filter criteria (same keywords as `query`)
      # @return [Hash{Object => Integer}] counts keyed by field value
      # @raise [ArgumentError] if `field` is not a Symbol/String or not an Event accessor
      def count_by(field, **filters)
        validate_count_by_field!(field)
        accessor = field.to_sym
        events = filters.empty? ? @store.all : query(**filters)
        events.each_with_object({}) do |event, counts|
          key = event.public_send(accessor)
          counts[key] = (counts[key] || 0) + 1
        end
      end

      private

      def matches_filters?(event, filters)
        match_field?(event, filters) && match_time?(event, filters)
      end

      def match_field?(event, filters)
        matches_value?(event.actor, filters[:actor]) &&
          matches_value?(event.action, filters[:action]) &&
          matches_value?(event.entity_id, filters[:entity_id]) &&
          matches_value?(event.entity_type, filters[:entity_type])
      end

      def match_time?(event, filters)
        return false if filters[:after] && event.timestamp <= filters[:after]
        return false if filters[:before] && event.timestamp >= filters[:before]

        true
      end

      def matches_value?(actual, expected)
        return true if expected.nil?
        return expected.include?(actual) if expected.is_a?(Array)

        actual == expected
      end

      def validate_count_by_field!(field)
        unless field.is_a?(Symbol) || field.is_a?(String)
          raise ArgumentError, "field must be a Symbol or String, got #{field.class}"
        end

        return if COUNT_BY_ALLOWED_FIELDS.include?(field.to_sym)

        raise ArgumentError,
              "invalid field: #{field}. Must be one of #{COUNT_BY_ALLOWED_FIELDS.join(', ')}"
      end
    end
  end
end
