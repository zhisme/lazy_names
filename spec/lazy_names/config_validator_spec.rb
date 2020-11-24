require 'spec_helper'

RSpec.describe LazyNames::ConfigValidator do
  describe '.new' do
    subject { described_class.new(lazy_names, constants) }

    let(:constants) { ['MyModule::MyClass'] }
    let(:lazy_names) { ['Mmc'] }

    it { should be_a(described_class) }
    it { expect(subject.errors).to eq(described_class::Errors.new([], [])) }
  end

  describe '.call' do
    subject { validator.call }

    let(:validator) { described_class.new(lazy_names, constants) }
    let(:constants) { ['MyModule::MyClass'] }
    let(:lazy_names) { ['Mmc'] }

    context 'when constants' do
      context 'valid' do
        let(:const) { double('MY_CONST') }

        before { allow(validator).to receive(:resolve_const_in_project).with(constants.first).and_return(const) }

        it { should be_a(described_class) }
        it { expect(subject.errors.undefined).to be_empty }
        it { expect(subject.errors.already_defined).to be_empty }
      end

      context 'invalid' do
        it { should be_a(described_class) }
        it { expect(subject.errors.undefined).to eq(constants) }
        it { expect(subject.errors.already_defined).to be_empty }
      end
    end

    context 'when lazy_names' do
      let(:const) { double('MY_CONST') }

      before { allow(validator).to receive(:resolve_const_in_project).with(constants.first).and_return(const) }

      context 'valid' do
        it { should be_a(described_class) }
        it { expect(subject.errors.undefined).to be_empty }
        it { expect(subject.errors.already_defined).to be_empty }
      end

      context 'invalid' do
        let(:lazy_names) { ['Mmc', 'MMC', 'Mmc'] }

        it { should be_a(described_class) }
        it { expect(subject.errors.undefined).to be_empty }
        it { expect(subject.errors.already_defined).to eq(['Mmc']) }
      end
    end
  end
end
