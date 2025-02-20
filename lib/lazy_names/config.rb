# frozen_string_literal: true

module LazyNames
  class Config
    extend Forwardable

    attr_reader :path, :validator

    def_delegator :@validator, :errors

    def initialize(definitions, path)
      @definitions = definitions
      @path = path
      @validator = ConfigValidator.new(definitions.values, definitions.keys)
    end

    def constants
      definitions.keys
    end

    def lazy_names
      definitions.values
    end

    def lazy_name(name)
      definitions[name]
    end

    def validate!
      validator.()
      remove_invalid_definitions!
    end

    private

    def remove_invalid_definitions!
      errors.undefined.each { |name| definitions.delete(name) }
    end

    attr_reader :definitions
  end
end
