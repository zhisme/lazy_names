RSpec.shared_examples 'raises NoDefinitions error' do
  it { expect { subject }.to raise_error(described_class::NoDefinitions) }
end
