# frozen_string_literal: true

module LazyNames
  class Definer
    class << self
      def call(config, top_level_binding)
        config.constants.each do |origin|
          eval <<-RUBY, top_level_binding, __FILE__, __LINE__ + 1 # rubocop:disable Security/Eval
            #{config.lazy_name(origin)} = #{origin} # LN_MC = LazyNames::MyClass. See spec/lazy_names/definer_spec.rb
          RUBY
        end
      end
    end
  end
end
