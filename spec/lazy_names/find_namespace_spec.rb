# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LazyNames::FindNamespace do
  describe '.call' do
    subject { described_class.call(path) }

    let(:path) { "/Users/my_projects/#{project_name}" }

    context 'when simple name' do
      let(:project_name) { 'awesome' }

      it { is_expected.to eq(project_name) }
    end

    context 'when dashes' do
      let(:project_name) { 'awesome_product' }

      it { is_expected.to eq(project_name) }
    end

    context 'when slashes' do
      let(:project_name) { '/my/project/inside/this/folder' }

      it { is_expected.to eq('folder') }
    end
  end
end
