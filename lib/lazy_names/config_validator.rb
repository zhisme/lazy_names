# frozen_string_literal: true

module LazyNames
  class ConfigValidator
    attr_reader :errors

    Errors = Struct.new(:undefined, :already_defined)

    def initialize(lazy_names, constants)
      @errors = Errors.new([], [])
      @constants = constants
      @lazy_names = lazy_names
    end

    def call
      validate_constants!
      validate_lazy_names!

      self
    end

    private

    attr_reader :lazy_names, :constants

    def validate_constants!
      constants.each do |c|
        resolve_const_in_project(c)
      rescue NameError
        self.errors.undefined << c
      end
    end

    def validate_lazy_names!
      a = lazy_names.uniq
      b = lazy_names

      diff = difference(b, a)

      return unless diff

      diff.each { |name| self.errors.already_defined << name }
    end

    def resolve_const_in_project(const)
      Module.const_get(const)
    end

    def difference(arr, other)
      copy = arr.dup
      other.each do |e|
        i = copy.rindex(e)
        copy.delete_at(i) if i
      end

      copy
    end
  end
end
