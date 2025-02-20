# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task default: %i[clean rubocop spec]

desc 'Run RuboCop'
RuboCop::RakeTask.new(:rubocop)

RSpec::Core::RakeTask.new(:spec)
