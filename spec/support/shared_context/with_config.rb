# frozen_string_literal: true

RSpec.shared_context 'with config' do
  let(:config) { instance_double(LazyNames::Config) }
  let(:constants) { ['LazyNames::MyClass'] }
  let(:lazy_names) { ['LNc'] }

  before do
    allow(config).to receive(:constants).and_return(constants)
    allow(config).to receive(:lazy_name).with(constants.first).and_return(lazy_names.first)
  end
end
