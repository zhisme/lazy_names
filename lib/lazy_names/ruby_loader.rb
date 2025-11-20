# frozen_string_literal: true

module LazyNames
  class RubyLoader
    CONFIG_FILE = '.lazy_names.rb'

    def self.load!(binding)
      new.load!(binding)
    end

    def initialize
      @loaded_count = 0
      @skipped_count = 0
      @error_count = 0
    end

    def load!(binding)
      path = find_config_file
      unless path
        Logger.warn("No #{CONFIG_FILE} found")
        return
      end

      Logger.info("Loading definitions from #{path}")

      File.readlines(path).each_with_index do |line, index|
        line_number = index + 1
        process_line(line, line_number, binding)
      end

      log_summary
    end

    private

    def find_config_file
      project_config = File.join(Dir.pwd, CONFIG_FILE)
      return project_config if File.exist?(project_config)

      home_config = File.join(Dir.home, CONFIG_FILE)
      return home_config if File.exist?(home_config)

      nil
    end

    def process_line(line, line_number, binding)
      result = LineValidator.validate(line)

      if result.valid?
        eval_line(line, binding)
        @loaded_count += 1
      elsif result.error
        Logger.warn("Line #{line_number}: #{result.error} - #{line.strip}")
        @error_count += 1
      else
        # Blank line or comment - skip silently
        @skipped_count += 1
      end
    rescue StandardError => e
      Logger.warn("Line #{line_number}: #{e.message}")
      @error_count += 1
    end

    def eval_line(line, binding)
      binding.eval(line)
    end

    def log_summary
      Logger.info("Loaded #{@loaded_count} definitions") if @loaded_count > 0
      Logger.warn("Skipped #{@error_count} invalid lines") if @error_count > 0
    end
  end
end
