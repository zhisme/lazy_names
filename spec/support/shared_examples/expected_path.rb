# frozen_string_literal: true

RSpec.shared_examples 'returns expected path' do
  it do
    expect(subject.path).to eq(expected_path)
  end
end
