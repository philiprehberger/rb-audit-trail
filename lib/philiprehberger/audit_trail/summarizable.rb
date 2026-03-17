# frozen_string_literal: true

module Philiprehberger
  module AuditTrail
    # Summary aggregation for audit events.
    module Summarizable
      VALID_GROUP_KEYS = %i[actor action entity_id].freeze

      # Aggregate event counts grouped by the specified field.
      #
      # @param group_by [Symbol] :actor, :action, or :entity_id
      # @return [Hash] counts keyed by field value
      def summary(group_by:)
        validate_group_key!(group_by)
        @store.all.each_with_object(Hash.new(0)) do |event, counts|
          key = event.public_send(group_by)
          counts[key] += 1
        end
      end

      private

      def validate_group_key!(key)
        return if VALID_GROUP_KEYS.include?(key)

        raise ArgumentError, "invalid group_by: #{key}. Must be one of #{VALID_GROUP_KEYS.join(', ')}"
      end
    end
  end
end
