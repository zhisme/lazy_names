# frozen_string_literal: true

module LazyNames
  class FindNamespace
    class << self
      ##
      # Find project namespace by folder name
      #
      def call(path = Dir.pwd)
        path.split('/').last
      end
    end
  end
end
