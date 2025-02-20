# frozen_string_literal: true

require 'spec_helper'
require 'lazy_names/config_loader'
require 'support/shared_examples/expected_path'
require 'support/shared_examples/no_definitions'
require 'support/shared_context/with_paths'
require 'support/shared_context/with_config_contents'

RSpec.describe LazyNames::ConfigLoader do
  describe '.call' do
    subject(:config_loader) { described_class.call(namespace: namespace, path: path) }

    include_context 'with paths'
    include_context 'with valid namespaced contents'

    let(:path) { nil }

    context 'when config invalid' do
      include_context 'with malformed contents'

      let(:path) { valid_path }

      context 'when namespace' do
        before { allow(described_class).to receive(:read_config).with(path).and_return(config_contents) }

        context 'when matches config' do
          context 'with no definitions found' do
            include_examples 'raises NoDefinitions error'
          end
        end

        context 'when not matches config' do
          include_context 'with wrong namespace'

          it { expect { config_loader }.to raise_error(described_class::NamespaceNotFound) }
        end
      end

      context 'when config can not be parsed' do
        before { allow(File).to receive(:read).with(path).and_return(file_contents) }

        include_context 'with psych not parseable file content'

        it { expect { config_loader }.to raise_error(described_class::YAMLConfigInvalid) }
      end
    end

    context 'when path' do
      context 'when valid' do
        let(:expected_path) { valid_path }
        let(:path) { valid_path }

        before { allow(described_class).to receive(:read_config).with(path).and_return(config_contents) }

        include_examples 'returns expected path'

        it { is_expected.to be_a(Struct) }
      end

      context 'when invalid' do
        let(:path) { invalid_path }

        it { expect { config_loader }.to raise_error(described_class::NoConfig) }

        context 'with no definitions found' do
          include_context 'with malformed contents'

          let(:path) { valid_path }

          before { allow(described_class).to receive(:read_config).with(path).and_return(config_contents) }

          include_examples 'raises NoDefinitions error'
        end
      end
    end

    context 'when project' do
      before do
        allow(described_class).to receive_messages(project_path: project_path, config_in_project_path?: true)
        allow(described_class).to receive(:read_config).with(project_path).and_return(config_contents)
      end

      context 'when valid' do
        include_context 'with valid project contents'

        let(:expected_path) { project_path }

        include_examples 'returns expected path'
      end

      context 'when invalid' do
        let(:expected_path) { home_path }

        before do
          allow(described_class).to receive_messages(config_in_project_path?: false, home_path: home_path)
          allow(described_class).to receive(:read_config).with(home_path).and_return(config_contents)
        end

        include_examples 'returns expected path'

        context 'when config contents malformed' do
          before do
            allow(described_class).to receive(:config_in_project_path?).and_return(true)
          end

          include_examples 'raises NoDefinitions error'
        end
      end
    end

    context 'when home dir' do
      let(:expected_path) { home_path }

      before do
        allow(described_class).to receive_messages(read_from_project: false, home_path: home_path)
      end

      context 'when valid' do
        before do
          allow(described_class).to receive(:read_config).with(home_path).and_return(config_contents)
        end

        include_examples 'returns expected path'

        it { is_expected.to be_a(Struct) }
      end

      context 'when invalid' do
        it { expect { config_loader }.to raise_error(described_class::NoConfig) }
      end
    end
  end
end
