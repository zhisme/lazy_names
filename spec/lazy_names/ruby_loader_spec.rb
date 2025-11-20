# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe LazyNames::RubyLoader do
  let(:temp_file) { Tempfile.new(['.lazy_names', '.rb']) }

  before do
    # Setup test constants
    stub_const('Models', Module.new)
    Models.const_set(:Users, Module.new)
    Models::Users.const_set(:CreditCard, Class.new)

    stub_const('Services', Module.new)
    Services.const_set(:PaymentProcessor, Class.new)
  end

  after do
    temp_file.close
    temp_file.unlink
  end

  describe '.load!' do
    context 'with valid config file' do
      it 'loads constant definitions' do
        temp_file.write(<<~RUBY)
          MUCC = Models::Users::CreditCard
          SPP = Services::PaymentProcessor
        RUBY
        temp_file.rewind

        loader = described_class.new
        allow(loader).to receive(:find_config_file).and_return(temp_file.path)
        allow(LazyNames::Logger).to receive(:info)

        test_binding = binding
        loader.load!(test_binding)

        expect(test_binding.eval('defined?(MUCC)')).to eq 'constant'
        expect(test_binding.eval('MUCC')).to eq Models::Users::CreditCard
        expect(test_binding.eval('SPP')).to eq Services::PaymentProcessor
      end

      it 'skips comments and blank lines' do
        temp_file.write(<<~RUBY)
          # This is a comment
          MUCC = Models::Users::CreditCard

          # Another comment
          SPP = Services::PaymentProcessor
        RUBY
        temp_file.rewind

        loader = described_class.new
        allow(loader).to receive(:find_config_file).and_return(temp_file.path)
        allow(LazyNames::Logger).to receive(:info)

        expect { loader.load!(binding) }.not_to raise_error
      end

      it 'logs successful loads' do
        temp_file.write(<<~RUBY)
          MUCC = Models::Users::CreditCard
        RUBY
        temp_file.rewind

        loader = described_class.new
        allow(loader).to receive(:find_config_file).and_return(temp_file.path)

        expect(LazyNames::Logger).to receive(:info).with(/Loading definitions from/)
        expect(LazyNames::Logger).to receive(:info).with(/Loaded 1 definitions/)

        loader.load!(binding)
      end
    end

    context 'with invalid constants' do
      it 'warns and skips lines with nonexistent constants' do
        temp_file.write(<<~RUBY)
          MUCC = Models::Users::CreditCard
          BAD = Nonexistent::Constant
          SPP = Services::PaymentProcessor
        RUBY
        temp_file.rewind

        loader = described_class.new
        allow(loader).to receive(:find_config_file).and_return(temp_file.path)
        allow(LazyNames::Logger).to receive(:info)

        expect(LazyNames::Logger).to receive(:warn).with(/Line 2.*Nonexistent::Constant not found/)
        expect(LazyNames::Logger).to receive(:warn).with(/Skipped 1 invalid lines/)

        test_binding = binding
        loader.load!(test_binding)

        expect(test_binding.eval('defined?(MUCC)')).to eq 'constant'
        expect(test_binding.eval('defined?(BAD)')).to be_nil
        expect(test_binding.eval('defined?(SPP)')).to eq 'constant'
      end
    end

    context 'with invalid syntax' do
      it 'warns and skips invalid lines' do
        temp_file.write(<<~RUBY)
          MUCC = Models::Users::CreditCard
          bad_syntax = something
          SPP = Services::PaymentProcessor
        RUBY
        temp_file.rewind

        loader = described_class.new
        allow(loader).to receive(:find_config_file).and_return(temp_file.path)
        allow(LazyNames::Logger).to receive(:info)

        expect(LazyNames::Logger).to receive(:warn).with(/Line 2.*Invalid syntax/).ordered
        expect(LazyNames::Logger).to receive(:warn).with(/Skipped 1 invalid lines/).ordered

        loader.load!(binding)
      end

      it 'handles eval errors gracefully' do
        temp_file.write(<<~RUBY)
          MUCC = Models::Users::CreditCard
          SYNTAX_ERROR = This::Will::Cause::Problems
        RUBY
        temp_file.rewind

        loader = described_class.new
        allow(loader).to receive(:find_config_file).and_return(temp_file.path)
        allow(LazyNames::Logger).to receive(:info)
        allow(LazyNames::Logger).to receive(:warn)

        expect { loader.load!(binding) }.not_to raise_error
      end
    end

    context 'with no config file' do
      it 'warns when no config file found' do
        loader = described_class.new
        allow(loader).to receive(:find_config_file).and_return(nil)

        expect(LazyNames::Logger).to receive(:warn).with(/No \.lazy_names\.rb found/)

        loader.load!(binding)
      end

      it 'does not raise error when no config file found' do
        loader = described_class.new
        allow(loader).to receive(:find_config_file).and_return(nil)
        allow(LazyNames::Logger).to receive(:warn)

        expect { loader.load!(binding) }.not_to raise_error
      end
    end

    context 'file lookup priority' do
      it 'prefers project .lazy_names.rb over home directory' do
        project_file = File.join(Dir.pwd, '.lazy_names.rb')
        home_file = File.join(Dir.home, '.lazy_names.rb')

        allow(File).to receive(:exist?).with(project_file).and_return(true)
        allow(File).to receive(:exist?).with(home_file).and_return(true)

        loader = described_class.new
        config_path = loader.send(:find_config_file)

        expect(config_path).to eq project_file
      end

      it 'uses home directory if project file does not exist' do
        project_file = File.join(Dir.pwd, '.lazy_names.rb')
        home_file = File.join(Dir.home, '.lazy_names.rb')

        allow(File).to receive(:exist?).with(project_file).and_return(false)
        allow(File).to receive(:exist?).with(home_file).and_return(true)

        loader = described_class.new
        config_path = loader.send(:find_config_file)

        expect(config_path).to eq home_file
      end

      it 'returns nil if neither file exists' do
        project_file = File.join(Dir.pwd, '.lazy_names.rb')
        home_file = File.join(Dir.home, '.lazy_names.rb')

        allow(File).to receive(:exist?).with(project_file).and_return(false)
        allow(File).to receive(:exist?).with(home_file).and_return(false)

        loader = described_class.new
        config_path = loader.send(:find_config_file)

        expect(config_path).to be_nil
      end
    end
  end

  describe '#process_line' do
    it 'increments loaded_count for valid lines' do
      loader = described_class.new
      allow(LazyNames::LineValidator).to receive(:validate).and_return(
        LazyNames::LineValidator::ValidationResult.new(valid: true)
      )

      loader.send(:process_line, 'MUCC = Models::Users::CreditCard', 1, binding)

      expect(loader.instance_variable_get(:@loaded_count)).to eq 1
    end

    it 'increments error_count for invalid lines' do
      loader = described_class.new
      allow(LazyNames::LineValidator).to receive(:validate).and_return(
        LazyNames::LineValidator::ValidationResult.new(valid: false, error: 'Some error')
      )
      allow(LazyNames::Logger).to receive(:warn)

      loader.send(:process_line, 'invalid line', 1, binding)

      expect(loader.instance_variable_get(:@error_count)).to eq 1
    end

    it 'increments skipped_count for blank lines' do
      loader = described_class.new
      allow(LazyNames::LineValidator).to receive(:validate).and_return(
        LazyNames::LineValidator::ValidationResult.new(valid: false)
      )

      loader.send(:process_line, '', 1, binding)

      expect(loader.instance_variable_get(:@skipped_count)).to eq 1
    end
  end
end
