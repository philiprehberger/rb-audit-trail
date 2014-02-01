# frozen_string_literal: true

require_relative "lib/philiprehberger/audit_trail/version"

Gem::Specification.new do |spec|
  spec.name = "philiprehberger-audit_trail"
  spec.version = Philiprehberger::AuditTrail::VERSION
  spec.authors = ["Philip Rehberger"]
  spec.email = ["me@philiprehberger.com"]

  spec.summary = "Generic audit trail for tracking changes with who, what, and when"
  spec.description = "A lightweight audit trail library for tracking changes to hashes and objects " \
                     "with actor, action, diff, and timestamp support."
  spec.homepage = "https://github.com/philiprehberger/rb-audit-trail"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]
end
