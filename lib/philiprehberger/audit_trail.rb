# frozen_string_literal: true

require_relative "audit_trail/version"
require_relative "audit_trail/event"
require_relative "audit_trail/differ"
require_relative "audit_trail/memory_store"
require_relative "audit_trail/tracker"

module Philiprehberger
  module AuditTrail
    class Error < StandardError; end
  end
end
