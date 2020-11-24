require 'yaml'

module LazyNames
  class ConfigLoader
    class NoConfig < StandardError; end
    class ConfigNotResolved < StandardError; end
    class NamespaceNotFound < StandardError; end

    class << self
      BasicConfig = Struct.new(:path, :definitions)
      HOME_PATH = '~/.lazy_names.yml'.freeze

      def call(namespace:, path: nil)
        return read_from_path(namespace, path) if path

        config = read_from_project(namespace)
        config ||= read_from_home_dir(namespace)

        config
      end

      private

      def read_from_path(namespace, path)
        definitions = find_definitions(path, namespace)

        BasicConfig.new(path, definitions)
      rescue Errno::ENOENT, Errno::ENOTDIR
        raise NoConfig, "No config found by given path: #{path}"
      end

      def read_from_home_dir(namespace)
        definitions = find_definitions(home_path, namespace)

        BasicConfig.new(home_path, definitions)
      rescue Errno::ENOENT
        raise NoConfig, 'No config found in your home directory. ' \
          'Create ~/.lazy_names.yml'
      end

      def read_from_project(namespace)
        return false unless config_in_project_path?

        definitions = find_definitions(project_path, namespace)

        BasicConfig.new(project_path, definitions)
      end

      def find_definitions(path, namespace)
        read_config(path)[namespace]['definitions'].to_h

      rescue NoMethodError
        raise NamespaceNotFound
      end

      def config_in_project_path?
        File.exist?(project_path)
      end

      def read_config(path)
        YAML.safe_load(File.read(path))
      end

      def project_path
        File.expand_path(Pathname.new(Dir.pwd).join('.lazy_names.yml'))
      end

      def home_path
        File.expand_path(HOME_PATH)
      end
    end
  end
end
