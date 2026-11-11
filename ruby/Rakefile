# frozen_string_literal: true

require "minitest/test_task"
require "rubocop/rake_task"

Minitest::TestTask.create(:test) do |t|
  t.libs << "lib"
  t.test_globs = ["test/test_*.rb"]
  t.warning = true
end

RuboCop::RakeTask.new

task default: %i[test rubocop]
