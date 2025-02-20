# frozen_string_literal: true

require 'spec_helper'
require 'pry'
require 'support/shared_context/with_paths'
require 'support/shared_context/with_config_contents'

RSpec.describe LazyNames::Config do
  subject(:config) { described_class.new(definitions, project_path) }

  include_context 'with paths'
  include_context 'with valid namespaced contents'

  describe '.new' do
    it { is_expected.to be_a(described_class) }
    it { expect(config.path).to eq(project_path) }
    it { expect(config.errors).to be_a(Struct) }
  end

  describe '#constants' do
    subject { config.constants }

    it { is_expected.to eq(definitions.keys) }
  end

  describe '#lazy_names' do
    subject { config.lazy_names }

    it { is_expected.to eq(definitions.values) }
  end

  describe '#lazy_name' do
    subject(:lazy_name) { config.lazy_name(name) }

    context 'when valid' do
      let(:name) { 'User::CreditCard' }

      it { is_expected.to eq('UCC') }
    end

    context 'when invalid' do
      let(:name) { 'Undefined' }

      it { is_expected.to be_nil }
    end
  end

  describe '#validate!' do
    subject(:validate) { config.validate! }

    context 'when valid' do
      before { allow(config.validator).to receive(:call).and_return(true) }

      it 'no definitions removed' do
        expect { validate }.not_to(change(config, :errors))
      end
    end

    context 'when invalid' do
      context 'when undefined constants' do
        it { expect { validate }.to change { config.errors.undefined }.to(['User::CreditCard']) }
        it { expect { validate }.to change(config, :constants).to([]) }
      end

      context 'when already defined' do
        include_context 'with already defined contents'

        before { allow(config.validator).to receive(:validate_constants!).and_return(true) }

        it { expect { validate }.to change { config.errors.already_defined }.to(['UCC']) }
      end
    end
  end
end
