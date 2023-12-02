RSpec.shared_examples 'a wrapper around a ReadySet SQL extension' do |sql_command|
  let(:args) { [] }
  let(:expected_output) { nil }
  let(:raw_query_result) { nil }

  before do
    allow(Readyset).to receive(:raw_query).with(sql_command, *args).and_return(raw_query_result)

    subject
  end

  it "invokes \"#{sql_command}\" on ReadySet" do
    expect(Readyset).to have_received(:raw_query).with(sql_command, *args)
  end

  it 'returns the expected result' do
    expect(subject).to eq(expected_output)
  end
end 
