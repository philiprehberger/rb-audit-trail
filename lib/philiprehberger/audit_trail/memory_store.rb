# frozen_string_literal: true

module Philiprehberger
  module AuditTrail
    # Thread-safe in-memory storage for audit events.
    class MemoryStore
      def initialize
        @events = []
        @mutex = Mutex.new
      end

      # Append an event to the store.
      #
      # @param event [Event] the audit event to store
      # @return [Event] the stored event
      def push(event)
        @mutex.synchronize { @events << event }
        event
      end

      # Filter events using a block.
      #
      # @yield [Event] block to filter events
      # @return [Array<Event>] matching events
      def select(&block)
        @mutex.synchronize { @events.select(&block) }
      end

      # Return all stored events.
      #
      # @return [Array<Event>] all events
      def all
        @mutex.synchronize { @events.dup }
      end

      # Remove all events from the store.
      #
      # @return [void]
      def clear!
        @mutex.synchronize { @events.clear }
      end

      # Return the number of stored events.
      #
      # @return [Integer] event count
      def size
        @mutex.synchronize { @events.size }
      end
    end
  end
end
