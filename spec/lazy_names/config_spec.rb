require 'spec_helper'
require 'pry'
require 'support/shared_context/with_paths'
require 'support/shared_context/with_config_contents'

RSpec.describe LazyNames::Config do
  include_context 'with paths'
  include_context 'with valid namespaced contents'

  let(:config) { described_class.new(definitions, project_path) }

  describe '.new' do
    subject { config }

    it { should be_a(described_class) }
    it { expect(subject.path).to eq(project_path) }
    it { expect(subject.errors).to be_a(Struct) }
  end

  describe '.constants' do
    subject { config.constants }

    it { should eq(definitions.keys) }
  end

  describe '.lazy_names' do
    subject { config.lazy_names }

    it { should eq(definitions.values) }
  end

  describe '.lazy_name' do
    subject { config.lazy_name(name) }

    context 'when valid' do
      let(:name) { 'User::CreditCard' }

      it 'returns short name' do
        should eq('UCC')
      end
    end

    context 'when invalid' do
      let(:name) { 'Undefined' }

      it { should eq(nil) }
    end
  end

  describe 'validate!' do
    subject { config.validate! }

    context 'when valid' do
      before { allow(config.validator).to receive(:call).and_return(true) }

      it 'no definitions removed' do
        expect { subject }.to_not change { config.errors }
      end
    end

    context 'when invalid' do
      context 'when undefined constants' do
        it { expect { subject }.to change { config.errors.undefined }.to(['User::CreditCard']) }
        it { expect { subject }.to change { config.constants }.to([]) }
      end

      context 'when already defined' do
        include_context 'with already defined contents'

        before { allow(config.validator).to receive(:validate_constants!).and_return(true) }

        it { expect { subject }.to change { config.errors.already_defined }.to(['UCC']) }
      end
    end
  end
end
