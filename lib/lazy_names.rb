# frozen_string_literal: true

require_relative 'lazy_names/version'
require_relative 'lazy_names/logger'
require_relative 'lazy_names/line_validator'
require_relative 'lazy_names/ruby_loader'

module LazyNames
  def self.load_definitions!(top_level_binding = binding)
    RubyLoader.load!(top_level_binding)
  end
end
