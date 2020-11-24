require 'spec_helper'
require 'support/shared_context/with_config'

RSpec.describe LazyNames::Definer do
  describe '.call' do
    subject { described_class.call(config, binding) }

    include_context 'with config'

    let(:top_level_binding) { TOPLEVEL_BINDING }

    context 'when valid' do
      let(:lazy_names) { ['LN_MC'] }

      before do
        class LazyNames::MyClass; end
      end

      it 'defines constant by lazy name' do
        expect { subject }.to_not raise_error
        expect(LN_MC).to eq(LazyNames::MyClass)
      end
    end

    context 'when invalid' do
      let(:lazy_names) { ['LN_AC'] }
      let(:constants) { ['LazyNames::AnotherClass'] }

      it 'fails if origin is undefined' do
        expect { subject }.to raise_error(NameError)
      end
    end
  end
end
