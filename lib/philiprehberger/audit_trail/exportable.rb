# frozen_string_literal: true

require "json"
require "csv"

module Philiprehberger
  module AuditTrail
    # Export audit events to JSON or CSV format.
    module Exportable
      EXPORT_HEADERS = %w[entity_id entity_type action actor timestamp].freeze

      # Export all events in the specified format.
      #
      # @param format [Symbol] :json or :csv
      # @return [String] formatted output
      def export(format)
        case format
        when :json then export_json
        when :csv then export_csv
        else raise ArgumentError, "unsupported format: #{format}"
        end
      end

      private

      def export_json
        JSON.generate(@store.all.map { |e| serialize_event(e) })
      end

      def export_csv
        CSV.generate do |csv|
          csv << EXPORT_HEADERS
          @store.all.each { |e| csv << event_row(e) }
        end
      end

      def serialize_event(event)
        h = event.to_h
        h[:action] = h[:action].to_s
        h[:timestamp] = h[:timestamp].iso8601
        h[:changes] = h[:changes].to_s
        h[:metadata] = h[:metadata].to_s
        h
      end

      def event_row(event)
        h = event.to_h
        [h[:entity_id], h[:entity_type], h[:action].to_s, h[:actor], h[:timestamp].iso8601]
      end
    end
  end
end
