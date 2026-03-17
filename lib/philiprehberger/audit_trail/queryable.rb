# frozen_string_literal: true

module Philiprehberger
  module AuditTrail
    # Query builder for filtering audit events by multiple criteria.
    module Queryable
      # Filter events by actor, action, entity_id, after, and before.
      #
      # @param filters [Hash] filter criteria
      # @return [Array<Event>] matching events
      def query(**filters)
        @store.select do |event|
          matches_filters?(event, filters)
        end
      end

      private

      def matches_filters?(event, filters)
        match_field?(event, filters) && match_time?(event, filters)
      end

      def match_field?(event, filters)
        matches_value?(event.actor, filters[:actor]) &&
          matches_value?(event.action, filters[:action]) &&
          matches_value?(event.entity_id, filters[:entity_id])
      end

      def match_time?(event, filters)
        return false if filters[:after] && event.timestamp <= filters[:after]
        return false if filters[:before] && event.timestamp >= filters[:before]

        true
      end

      def matches_value?(actual, expected)
        return true if expected.nil?

        actual == expected
      end
    end
  end
end
