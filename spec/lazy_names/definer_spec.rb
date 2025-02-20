# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_context/with_config'

module LazyNames
  class MyClass; end # rubocop:disable Lint/EmptyClass
end

RSpec.describe LazyNames::Definer do
  describe '.call' do
    subject(:definer) { described_class.call(config, binding) }

    include_context 'with config'

    let(:top_level_binding) { TOPLEVEL_BINDING }

    context 'when valid' do
      let(:lazy_names) { ['LN_MC'] }

      it { expect { definer }.not_to raise_error }

      it 'defines constant by lazy name' do
        definer
        expect(LN_MC).to eq(LazyNames::MyClass)
      end
    end

    context 'when invalid' do
      let(:lazy_names) { ['LN_AC'] }
      let(:constants) { ['LazyNames::AnotherClass'] }

      it 'fails if origin is undefined' do
        expect { definer }.to raise_error(NameError)
      end
    end
  end
end
