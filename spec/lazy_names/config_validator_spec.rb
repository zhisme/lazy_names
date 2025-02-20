# frozen_string_literal: true

require 'spec_helper'

TEST_CONST = 'MMC'

RSpec.describe LazyNames::ConfigValidator do
  describe '.new' do
    subject(:config_validator) { described_class.new(lazy_names, constants) }

    let(:constants) { ['MyModule::MyClass'] }
    let(:lazy_names) { ['Mmc'] }

    it { is_expected.to be_a(described_class) }
    it { expect(config_validator.errors).to eq(described_class::Errors.new([], [])) }
  end

  describe '.call' do
    subject(:config_validator) { validator.call }

    let(:validator) { described_class.new(lazy_names, constants) }
    let(:constants) { ['MyModule::MyClass'] }
    let(:lazy_names) { ['Mmc'] }

    context 'with constants' do
      context 'when valid' do
        before { allow(validator).to receive(:resolve_const_in_project).with(constants.first).and_return(TEST_CONST) }

        it { is_expected.to be_a(described_class) }
        it { expect(config_validator.errors.undefined).to be_empty }
        it { expect(config_validator.errors.already_defined).to be_empty }
      end

      context 'when invalid' do
        it { is_expected.to be_a(described_class) }
        it { expect(config_validator.errors.undefined).to eq(constants) }
        it { expect(config_validator.errors.already_defined).to be_empty }
      end
    end

    context 'when lazy_names' do
      before { allow(validator).to receive(:resolve_const_in_project).with(constants.first).and_return(TEST_CONST) }

      context 'when valid' do
        it { is_expected.to be_a(described_class) }
        it { expect(config_validator.errors.undefined).to be_empty }
        it { expect(config_validator.errors.already_defined).to be_empty }
      end

      context 'when invalid' do
        let(:lazy_names) { %w[Mmc MMC Mmc] }

        it { is_expected.to be_a(described_class) }
        it { expect(config_validator.errors.undefined).to be_empty }
        it { expect(config_validator.errors.already_defined).to eq(['Mmc']) }
      end
    end
  end
end
