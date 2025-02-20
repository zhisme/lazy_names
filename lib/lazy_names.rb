# frozen_string_literal: true

require 'lazy_names/version'
require 'lazy_names/find_namespace'
require 'lazy_names/config_loader'
require 'lazy_names/config'
require 'lazy_names/config_validator'
require 'lazy_names/definer'
require 'lazy_names/logger'

module LazyNames
  def self.load_definitions!(top_level_binding = TOPLEVEL_BINDING) # rubocop:disable Metrics/AbcSize
    basic_config = LazyNames::ConfigLoader
                   .(namespace: LazyNames::FindNamespace.())
    config = LazyNames::Config.new(basic_config.definitions, basic_config.path)
    config.validate!
    LazyNames::Definer.(config, top_level_binding)

    LazyNames::Logger.warn_undefined(config.errors.undefined, config.path)
    LazyNames::Logger.warn_duplicate_definition(config.errors.already_defined, config.path)
    LazyNames::Logger.warn_empty_definitions(config.constants.to_a.empty?, config.path)
  end
end
