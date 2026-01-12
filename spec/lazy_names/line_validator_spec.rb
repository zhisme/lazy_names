# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LazyNames::LineValidator do
  # Setup test constants
  before do
    stub_const('TestModule', Module.new)
    TestModule.const_set(:TestClass, Class.new)
  end

  describe '.validate' do
    context 'with valid assignment' do
      it 'validates when constant exists' do
        result = described_class.validate('TC = TestModule::TestClass')

        expect(result.valid?).to be true
        expect(result.short_name).to eq 'TC'
        expect(result.full_constant).to eq 'TestModule::TestClass'
        expect(result.error).to be_nil
      end

      it 'accepts underscores in constant names' do
        result = described_class.validate('TEST_CONST = TestModule::TestClass')

        expect(result.valid?).to be true
        expect(result.short_name).to eq 'TEST_CONST'
      end

      it 'accepts numbers in constant names' do
        result = described_class.validate('TC2 = TestModule::TestClass')

        expect(result.valid?).to be true
        expect(result.short_name).to eq 'TC2'
      end

      it 'handles extra whitespace' do
        result = described_class.validate('  TC   =   TestModule::TestClass  ')

        expect(result.valid?).to be true
        expect(result.short_name).to eq 'TC'
        expect(result.full_constant).to eq 'TestModule::TestClass'
      end
    end

    context 'with invalid constant' do
      it 'rejects when constant does not exist' do
        result = described_class.validate('BAD = Nonexistent::Constant')

        expect(result.valid?).to be false
        expect(result.error).to include('Constant Nonexistent::Constant not found')
      end
    end

    context 'with invalid syntax' do
      it 'rejects lowercase short name' do
        result = described_class.validate('tc = TestModule::TestClass')

        expect(result.valid?).to be false
        expect(result.error).to eq 'Invalid syntax'
      end

      it 'rejects method calls' do
        result = described_class.validate('TC = User.find(1)')

        expect(result.valid?).to be false
        expect(result.error).to eq 'Invalid syntax'
      end

      it 'rejects string literals' do
        result = described_class.validate('TC = "string"')

        expect(result.valid?).to be false
        expect(result.error).to eq 'Invalid syntax'
      end

      it 'rejects arbitrary code' do
        result = described_class.validate('puts "hello"')

        expect(result.valid?).to be false
        expect(result.error).to eq 'Invalid syntax'
      end

      it 'rejects assignments without constant path' do
        result = described_class.validate('TC = some_variable')

        expect(result.valid?).to be false
        expect(result.error).to eq 'Invalid syntax'
      end
    end

    context 'with comments and blank lines' do
      it 'skips blank lines' do
        result = described_class.validate('   ')

        expect(result.valid?).to be false
        expect(result.error).to be_nil
      end

      it 'skips empty lines' do
        result = described_class.validate('')

        expect(result.valid?).to be false
        expect(result.error).to be_nil
      end

      it 'skips comments' do
        result = described_class.validate('# This is a comment')

        expect(result.valid?).to be false
        expect(result.error).to be_nil
      end

      it 'skips comments with leading whitespace' do
        result = described_class.validate('  # This is a comment')

        expect(result.valid?).to be false
        expect(result.error).to be_nil
      end
    end
  end

  describe '.skip_line?' do
    it 'returns true for blank lines' do
      expect(described_class.send(:skip_line?, '   ')).to be true
    end

    it 'returns true for comments' do
      expect(described_class.send(:skip_line?, '# comment')).to be true
    end

    it 'returns false for code lines' do
      expect(described_class.send(:skip_line?, 'TC = TestModule::TestClass')).to be false
    end
  end

  describe '.constant_exists?' do
    it 'returns true for existing constants' do
      expect(described_class.send(:constant_exists?, 'String')).to be true
    end

    it 'returns false for non-existing constants' do
      expect(described_class.send(:constant_exists?, 'NonExistent')).to be false
    end

    it 'returns true for nested constants' do
      expect(described_class.send(:constant_exists?, 'TestModule::TestClass')).to be true
    end
  end

  describe 'ValidationResult' do
    it 'creates a valid result' do
      result = LazyNames::LineValidator::ValidationResult.new(
        valid: true,
        short_name: 'TC',
        full_constant: 'TestModule::TestClass'
      )

      expect(result.valid?).to be true
      expect(result.short_name).to eq 'TC'
      expect(result.full_constant).to eq 'TestModule::TestClass'
      expect(result.error).to be_nil
    end

    it 'creates an invalid result with error' do
      result = LazyNames::LineValidator::ValidationResult.new(
        valid: false,
        error: 'Some error'
      )

      expect(result.valid?).to be false
      expect(result.error).to eq 'Some error'
      expect(result.short_name).to be_nil
      expect(result.full_constant).to be_nil
    end
  end
end
