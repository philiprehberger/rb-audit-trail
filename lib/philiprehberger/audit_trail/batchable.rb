# frozen_string_literal: true

module Philiprehberger
  module AuditTrail
    # Batch recording support for multiple audit events.
    module Batchable
      # Record multiple events in one call.
      #
      # @param entries [Array<Hash>] array of event attribute hashes
      # @return [Array<Event>] the recorded events
      def record_batch(entries)
        events = entries.map { |entry| Event.new(**entry) }
        @store.push_all(events)
      end
    end
  end
end
