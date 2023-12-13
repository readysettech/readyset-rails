# spec/relation_extension_spec.rb

RSpec.describe Readyset::RelationExtension do
  describe '#create_readyset_cache!' do
    subject { query.create_readyset_cache! }

    let(:query_string) { query.to_sql }
    let(:query) { Cat.where(id: 1) }

    before do
      allow(Readyset).to receive(:create_cache!).with(sql: query_string)
      subject
    end

    it "invokes `Readyset.create_cache!` with the relation's query string" do
      expect(Readyset).to have_received(:create_cache!).with(sql: query_string)
    end
  end

  describe '#drop_readyset_cache!' do
    subject { query.drop_readyset_cache! }

    let(:query_string) { query.to_sql }
    let(:query) { Cat.where(id: 1) }

    before do
      allow(Readyset).to receive(:drop_cache!).with(sql: query_string)
      subject
    end

    it "invokes `Readyset.drop_cache!` with the relation's query string" do
      expect(Readyset).to have_received(:drop_cache!).with(sql: query_string)
    end
  end

  describe '#readyset_explain' do
    it "invokes `Readyset.readyset_explain` with the relation's query string" do
      query = Cat.where(id: 1)
      query_string = query.to_sql
      allow(Readyset).to receive(:explain).with(query_string).
        and_return(instance_double(Readyset::Explain))

      query.readyset_explain

      expect(Readyset).to have_received(:explain).with(query_string)
    end

    it 'returns the expected explain information' do
      query = Cat.where(id: 1)
      query_string = query.to_sql
      explain = Readyset::Explain.new(id: 'q_0000000000000000',
                                      text: 'SELECT * FROM "cats" WHERE ("id" = $1)',
                                      supported: :yes)
      allow(Readyset).to receive(:explain).with(query_string).and_return(explain)

      output = query.readyset_explain

      expect(output).to eq(explain)
    end
  end
end
