# frozen_string_literal: true

module LazyNames
  class LineValidator
    ASSIGNMENT_PATTERN = /\A\s*([A-Z][A-Z0-9_]*)\s*=\s*([A-Z][A-Za-z0-9_:]*)\s*\z/.freeze

    class ValidationResult
      attr_reader :valid, :short_name, :full_constant, :error

      def initialize(valid:, short_name: nil, full_constant: nil, error: nil)
        @valid = valid
        @short_name = short_name
        @full_constant = full_constant
        @error = error
      end

      def valid?
        @valid
      end
    end

    def self.validate(line)
      return skip_result if skip_line?(line)

      match = line.match(ASSIGNMENT_PATTERN)
      return invalid_result('Invalid syntax') unless match

      short_name = match[1]
      full_constant = match[2]

      return invalid_result("Constant #{full_constant} not found") unless constant_exists?(full_constant)

      ValidationResult.new(
        valid: true,
        short_name: short_name,
        full_constant: full_constant
      )
    end

    def self.skip_line?(line)
      line.strip.empty? || line.strip.start_with?('#')
    end

    def self.constant_exists?(constant_path)
      Object.const_get(constant_path)
      true
    rescue NameError
      false
    end

    def self.skip_result
      ValidationResult.new(valid: false)
    end

    def self.invalid_result(error)
      ValidationResult.new(valid: false, error: error)
    end

    private_class_method :skip_line?, :constant_exists?, :skip_result, :invalid_result
  end
end
