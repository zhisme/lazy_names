module LazyNames
  class Definer
    class << self
      def call(config, top_level_binding)
        config.constants.each do |origin|
          eval <<-RUBY, top_level_binding, __FILE__, __LINE__ + 1
            #{config.lazy_name(origin)} = #{origin}
          RUBY
        end
      end
    end
  end
end
