# frozen_string_literal: true

require_relative "lib/noosh24/version"

Gem::Specification.new do |spec|
  spec.name = "noosh24"
  spec.version = Noosh24::VERSION
  spec.authors = ["Noosh24"]
  spec.summary = "Official Ruby client for the Noosh24 Open API"
  spec.description = "Read a Noosh24 venue's menu, reservations, orders, payments, tables, customers, loyalty, " \
                     "stock and reviews, and create or cancel reservations."
  spec.homepage = "https://developer.noosh24.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "documentation_uri" => "https://developer.noosh24.com/reference",
    "source_code_uri" => "https://github.com/noosh24/sdks/tree/main/ruby",
    "bug_tracker_uri" => "https://github.com/noosh24/sdks/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb"] + %w[LICENSE README.md]
  spec.require_paths = ["lib"]
end
