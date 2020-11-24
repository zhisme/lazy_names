RSpec.shared_context 'with valid contents' do
  let(:config_contents) { YAML.safe_load("---\nlazy_names:\n  definitions:\n    'User::CreditCard': 'UCC'") }
  let(:already_defined_contents) { YAML.safe_load("---\nlazy_names:\n  definitions:\n    'User::CreditCard': UCC\n    'User::CreditCard': UsCard\n") }
  let(:definitions) { config_contents[namespace]['definitions'] }
  let(:namespace) { 'lazy_names' }
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

RSpec.shared_context 'with wrong namespace' do
  let(:config_contents) { YAML.safe_load("---\nlazy_names:\n  definitions:\n    'User::CreditCard': UCC\n    'User::CompanyCredit': UCC\n") }
  let(:definitions) { config_contents[namespace]['definitions'] }
  let(:namespace) { 'never_existed' }
end
