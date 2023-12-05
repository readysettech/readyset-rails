# spec/relation_extension_spec.rb

RSpec.describe Readyset::RelationExtension do
  describe '#create_readyset_cache!' do
    subject { Cat.where(id: 1).create_readyset_cache! }

    let(:expected_query) { 'SELECT "cats".* FROM "cats" WHERE "cats"."id" = ?' }

    before do
      allow(Readyset).to receive(:create_cache!).with(sql: expected_query)
      subject
    end

    it 'invokes `Readyset.create_cache!` with the parameterized query string that the ' \
        'relation represents' do
      expect(Readyset).to have_received(:create_cache!).with(sql: expected_query)
    end
  end

  describe '#drop_readyset_cache!' do
    subject { Cat.where(id: 1).drop_readyset_cache! }

    let(:expected_query) { 'SELECT "cats".* FROM "cats" WHERE "cats"."id" = ?' }

    before do
      allow(Readyset).to receive(:drop_cache!).with(sql: expected_query)
      subject
    end

    it 'invokes `Readyset.drop_cache!` with the parameterized query string that the relation ' \
        'represents' do
      expect(Readyset).to have_received(:drop_cache!).with(sql: expected_query)
    end
  end
end
