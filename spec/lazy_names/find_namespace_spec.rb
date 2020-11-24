require 'spec_helper'

RSpec.describe LazyNames::FindNamespace do
  describe '.call' do
    subject { described_class.call(path) }

    let(:path) { '/Users/my_projects/' + expected_name }

    context 'when simple name' do
      let(:expected_name) { 'awesome' }

      it { expect(subject).to eq(expected_name) }
    end

    context 'when dashes' do
      let(:expected_name) { 'awesome_product' }

      it { expect(subject).to eq(expected_name) }
    end

    context 'when slashes' do
      let(:expected_name) { '/my/project/inside/this/folder' }

      it { expect(subject).to eq('folder') }
    end
  end
end
