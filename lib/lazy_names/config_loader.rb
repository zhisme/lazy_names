require 'yaml'

module LazyNames
  class ConfigLoader
    class NoConfig < StandardError; end
    class ConfigNotResolved < StandardError; end
    class NamespaceNotFound < StandardError; end
    class NoDefinitions < StandardError; end

    class << self
      BasicConfig = Struct.new(:path, :definitions)
      HOME_PATH = '~/.lazy_names.yml'.freeze

      def call(namespace:, path: nil)
        return read_from_path(namespace, path) if path

        config = read_from_project if config_in_project_path?
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

      def read_from_project
        definitions = find_project_definitions

        BasicConfig.new(project_path, definitions)
      end

      def find_project_definitions
        read_config(project_path)['definitions'].to_hash

      rescue NoMethodError
        raise NoDefinitions, "No definitions found in #{project_path}. " \
          'See config example .lazy_names.tt.project.yml'
      end

      def find_definitions(path, namespace)
        find_namespace_contents(path, namespace)['definitions'].to_hash

      rescue NoMethodError
        raise NoDefinitions, "No definitions found in #{path}. " \
          'See config example in .lazy_names.tt.yml'
      end

      def find_namespace_contents(path, namespace)
        read_config(path)[namespace].to_hash
      rescue NoMethodError
        raise NamespaceNotFound, "No namespace found in #{path}. " \
          'See config example in .lazy_names.tt.yml and check README'
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
