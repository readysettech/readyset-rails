RSpec.shared_examples 'a wrapper around a ReadySet SQL extension' do |sql_command|
  let(:args) { [] }
  let(:expected_output) { nil }
  let(:raw_query_result) { [] }

  it 'returns the expected result' do
    expect(subject).to eq(expected_output)
  end
end
