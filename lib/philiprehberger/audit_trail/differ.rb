# frozen_string_literal: true

module Philiprehberger
  module AuditTrail
    # Hash diff utility that computes field-level changes between two hashes.
    module Differ
      # Compute the diff between two hashes.
      #
      # @param before [Hash] the original state
      # @param after [Hash] the new state
      # @return [Hash] changed fields as { field => { from: old, to: new } }
      def self.call(before:, after:)
        all_keys = (before.keys + after.keys).uniq
        all_keys.each_with_object({}) do |key, diff|
          old_val = before[key]
          new_val = after[key]
          diff[key] = { from: old_val, to: new_val } unless old_val == new_val
        end
      end
    end
  end
end
