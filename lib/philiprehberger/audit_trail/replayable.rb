# frozen_string_literal: true

module Philiprehberger
  module AuditTrail
    # Reconstructs entity state by replaying recorded events in chronological order.
    module Replayable
      # Replay events for an entity to rebuild its current (or point-in-time) state.
      #
      # Walks recorded events oldest-first and folds each `:changes` hash into a
      # state accumulator. `:create` and `:update` actions write `:to` values;
      # `:delete` clears the field. Other actions are skipped.
      #
      # @param entity_id [String] identifier of the entity to replay
      # @param entity_type [String, nil] optional type filter
      # @param until_time [Time, nil] cutoff timestamp; events at or before this time are included
      # @return [Hash] reconstructed state hash
      def replay(entity_id:, entity_type: nil, until_time: nil)
        events_for_replay(entity_id, entity_type, until_time).each_with_object({}) do |event, state|
          apply_event(state, event)
        end
      end

      private

      def events_for_replay(entity_id, entity_type, until_time)
        history(entity_id: entity_id, entity_type: entity_type)
          .select { |event| until_time.nil? || event.timestamp <= until_time }
          .sort_by(&:timestamp)
      end

      def apply_event(state, event)
        case event.action
        when :delete
          event.changes.each_key { |field| state.delete(field) }
        else
          event.changes.each do |field, change|
            state[field] = change.is_a?(Hash) && change.key?(:to) ? change[:to] : change
          end
        end
      end
    end
  end
end
