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

    it 'invokes `Readyset.create_cache!` with the parameterized query string that the ' \
        'relation represents' do
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

    it 'invokes `Readyset.drop_cache!` with the parameterized query string that the relation ' \
        'represents' do
      expect(Readyset).to have_received(:drop_cache!).with(sql: query_string)
    end
  end
end
