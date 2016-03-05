# frozen_string_literal: true

module Philiprehberger
  module AuditTrail
    # Retention policy support for removing old audit events.
    module Prunable
      # Delete events older than the specified time.
      #
      # @param before [Time] remove events with timestamp before this time
      # @return [void]
      def prune(before:)
        @store.reject! { |event| event.timestamp < before }
      end
    end
  end
end
