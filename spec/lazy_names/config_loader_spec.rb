require 'spec_helper'
require 'lazy_names/config_loader'
require 'support/shared_examples/expected_path'
require 'support/shared_context/with_paths'
require 'support/shared_context/with_config_contents'

RSpec.describe LazyNames::ConfigLoader do
  describe '.call' do
    subject { described_class.call(namespace: namespace, path: path) }

    include_context 'with paths'
    include_context 'with valid contents'

    let(:path) { nil }

    context 'when config invalid' do
      include_context 'with malformed contents'

      let(:path) { valid_path }

      before { allow(described_class).to receive(:read_config).with(path).and_return(config_contents) }

      context 'when namespace' do
        context 'matches config' do
          it { should be_a(Struct) }
          it { expect { subject }.to_not raise_error }
        end

        context 'not matches config' do
          include_context 'with wrong namespace'

          it { expect { subject }.to raise_error(described_class::NamespaceNotFound) }
        end
      end
    end

    context 'when path' do
      context 'when valid' do
        let(:expected_path) { valid_path }
        let(:path) { valid_path }

        before { allow(described_class).to receive(:read_config).with(path).and_return(config_contents) }

        include_examples 'returns expected path'

        it { should be_a(Struct) }
      end

      context 'when invalid' do
        let(:path) { invalid_path }

        it { expect { subject }.to raise_error(described_class::NoConfig) }
      end
    end

    context 'when project' do
      before do
        allow(described_class).to receive(:project_path).and_return(project_path)
        allow(described_class).to receive(:config_in_project_path?).and_return(true)
        allow(described_class).to receive(:read_config).with(project_path).and_return(config_contents)
      end

      it { expect(subject).to be_a(Struct) }

      context 'when valid' do
        let(:expected_path) { project_path }

        include_examples 'returns expected path'
      end

      context 'when invalid' do
        let(:expected_path) { home_path }

        before do
          allow(described_class).to receive(:config_in_project_path?).and_return(false)
          allow(described_class).to receive(:home_path).and_return(home_path)
          allow(described_class).to receive(:read_config).with(home_path).and_return(config_contents)
        end

        include_examples 'returns expected path'
      end
    end

    context 'when home dir' do
      let(:expected_path) { home_path }

      before do
        allow(described_class).to receive(:read_from_project).and_return(false)
        allow(described_class).to receive(:home_path).and_return(home_path)
      end

      context 'when valid' do
        before do
          allow(described_class).to receive(:read_config).with(home_path).and_return(config_contents)
        end

        include_examples 'returns expected path'

        it { expect(subject).to be_a(Struct) }
      end

      context 'when invalid' do
        it { expect { subject }.to raise_error(described_class::NoConfig) }
      end
    end
  end
end
