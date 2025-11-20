# frozen_string_literal: true

module LazyNames
  class Logger
    class << self
      def info(message)
        puts message
      end

      def warn(message)
        Kernel.warn(message)
      end

      def warn_undefined(errors, config_path)
        return if errors.empty?

        message = <<~MSG
          Error loading lazy_names gem.
          Found #{errors.size} undefined constants.
          Please check spelling for #{errors.join(', ')}
          #{config_path}
          \n
        MSG

        Kernel.warn(message)
      end

      def warn_duplicate_definition(errors, config_path)
        return if errors.empty?

        message = <<~MSG
          Error loading lazy_names gem.
          Found #{errors.size} already defined constants.
          Using same lazy names for different constants may lead to unexpected results
          Avoid duplications in your config file.
          #{config_path}
          \n
        MSG

        Kernel.warn(message)
      end

      def warn_empty_definitions(errors, config_path)
        return unless errors

        message = <<~MSG
          Error loading lazy_names gem.
          Seems like you misspelled namespace in config.
          #{config_path}
          Please ensure word definitions exists in config
          or check .lazy_names.tt.yml for consistency.
        MSG

        Kernel.warn(message)
      end
    end
  end
end
