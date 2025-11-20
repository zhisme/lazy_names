# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe 'Ruby configuration integration' do
  around do |example|
    Dir.mktmpdir do |dir|
      @original_dir = Dir.pwd
      Dir.chdir(dir)
      example.run
      Dir.chdir(@original_dir)
    end
  end

  before do
    # Setup test constants
    stub_const('TestApp', Module.new)
    TestApp.const_set(:Models, Module.new)
    TestApp::Models.const_set(:User, Class.new)

    TestApp.const_set(:Services, Module.new)
    TestApp::Services.const_set(:Mailer, Class.new)
  end

  it 'loads and defines constants from .lazy_names.rb' do
    File.write('.lazy_names.rb', <<~RUBY)
      TU = TestApp::Models::User
      TM = TestApp::Services::Mailer
    RUBY

    LazyNames.load_definitions!(binding)

    expect(defined?(TU)).to eq 'constant'
    expect(TU).to eq TestApp::Models::User
    expect(TM).to eq TestApp::Services::Mailer
  end

  it 'handles mixed valid and invalid definitions' do
    File.write('.lazy_names.rb', <<~RUBY)
      # Valid definition
      TU = TestApp::Models::User

      # Invalid constant
      BAD = Nonexistent::Class

      # Another valid definition
      TM = TestApp::Services::Mailer
    RUBY

    # Clear any existing constants
    Object.send(:remove_const, :TU) if defined?(TU)
    Object.send(:remove_const, :TM) if defined?(TM)

    expect(LazyNames::Logger).to receive(:warn).with(/Nonexistent::Class not found/).ordered
    expect(LazyNames::Logger).to receive(:warn).with(/Skipped 1 invalid lines/).ordered

    LazyNames.load_definitions!(binding)

    expect(defined?(TU)).to eq 'constant'
    expect(defined?(BAD)).to be_nil
    expect(defined?(TM)).to eq 'constant'
  end

  it 'handles files with comments and blank lines' do
    File.write('.lazy_names.rb', <<~RUBY)
      # This is a header comment
      # Author: Test

      # User shortcut
      TU = TestApp::Models::User

      # Mailer shortcut
      TM = TestApp::Services::Mailer
    RUBY

    expect { LazyNames.load_definitions!(binding) }.not_to raise_error

    expect(defined?(TU)).to eq 'constant'
    expect(defined?(TM)).to eq 'constant'
  end

  it 'warns when no config file is found' do
    expect(LazyNames::Logger).to receive(:warn).with(/No \.lazy_names\.rb found/)

    LazyNames.load_definitions!
  end

  it 'handles empty config files' do
    File.write('.lazy_names.rb', '')

    expect { LazyNames.load_definitions! }.not_to raise_error
  end

  it 'handles config files with only comments' do
    File.write('.lazy_names.rb', <<~RUBY)
      # Just comments
      # Nothing else
    RUBY

    expect { LazyNames.load_definitions! }.not_to raise_error
  end

  it 'validates constants exist before defining them' do
    File.write('.lazy_names.rb', <<~RUBY)
      FAKE = This::Does::Not::Exist
    RUBY

    expect(LazyNames::Logger).to receive(:warn).with(/Line 1.*This::Does::Not::Exist not found/).ordered
    expect(LazyNames::Logger).to receive(:warn).with(/Skipped 1 invalid lines/).ordered

    LazyNames.load_definitions!(binding)

    expect(defined?(FAKE)).to be_nil
  end

  it 'loads definitions in order' do
    File.write('.lazy_names.rb', <<~RUBY)
      TU = TestApp::Models::User
      TM = TestApp::Services::Mailer
    RUBY

    # Clear any existing constants
    Object.send(:remove_const, :TU) if defined?(TU)
    Object.send(:remove_const, :TM) if defined?(TM)

    loaded_constants = []
    allow_any_instance_of(Binding).to receive(:eval) do |_, line|
      loaded_constants << line.strip
      eval(line)
    end

    LazyNames.load_definitions!

    expect(loaded_constants).to eq([
      'TU = TestApp::Models::User',
      'TM = TestApp::Services::Mailer'
    ])
  end
end
