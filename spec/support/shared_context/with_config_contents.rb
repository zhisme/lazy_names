# frozen_string_literal: true

RSpec.shared_context 'with valid namespaced contents' do
  let(:config_contents) { YAML.safe_load("---\nlazy_names:\n  definitions:\n    'User::CreditCard': 'UCC'") }
  let(:already_defined_contents) { YAML.safe_load("---\nlazy_names:\n  definitions:\n    'User::CreditCard': UCC\n    'User::CreditCard': UsCard\n") }
  let(:definitions) { config_contents[namespace]['definitions'] }
  let(:namespace) { 'lazy_names' }
end

RSpec.shared_context 'with valid project contents' do
  let(:config_contents) { YAML.safe_load("---\ndefinitions:\n  'User::CreditCard': 'UCC'") }
  let(:definitions) { config_contents['definitions'] }
end

RSpec.shared_context 'with already defined contents' do
  let(:config_contents) { YAML.safe_load("---\nlazy_names:\n  definitions:\n    'User::CreditCard': UCC\n    'User::CompanyCredit': UCC\n") }
  let(:definitions) { config_contents[namespace]['definitions'] }
  let(:namespace) { 'lazy_names' }
end

RSpec.shared_context 'with malformed contents' do
  let(:config_contents) { YAML.safe_load("---\nlazy_names:\n  'User::CreditCard': UCC\n  'User::CompanyCredit': UCC\n") }
  let(:definitions) { config_contents[namespace]['definitions'] }
  let(:namespace) { 'lazy_names' }
end

RSpec.shared_context 'with psych not parseable file content' do
  let(:file_contents) { "--\nlazy_names:\n invalid" }
end

RSpec.shared_context 'with wrong namespace' do
  let(:config_contents) { YAML.safe_load("---\nlazy_names:\n  definitions:\n    'User::CreditCard': UCC\n    'User::CompanyCredit': UCC\n") }
  let(:definitions) { config_contents[namespace]['definitions'] }
  let(:namespace) { 'never_existed' }
end
