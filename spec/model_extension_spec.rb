# spec/model_extension_spec.rb

RSpec.describe Readyset::ModelExtension do
  describe '.readyset_query' do
    subject { Cat.readyset_query(name, body) }

    context 'when the body is not callable' do
      let(:body) { 'I am not callable' }
      let(:name) { :find_by_name_cached }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context "when the query's name would overwrite a predefined class method" do
      let(:body) { ->(name) { Cat.where(name: name) } }
      let(:name) { :all }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context "when the query's name would overwrite a predefined ActiveRecord::Relation method" do
      let(:body) { ->(name) { Cat.where(name: name) } }
      let(:name) { :load }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'when the body is callable and the name is valid' do
      let(:name) { :find_by_name_cached }
      let(:body) { ->(name) { Cat.where(name: name) } }

      before do
        # Add a few records to the database that is acting as our fake ReadySet instance
        Readyset.route(prevent_writes: false) do
          Cat.create!(name: 'whiskers')
          Cat.create!(name: 'fluffy')
          Cat.create!(name: 'tails')
        end

        subject
      end

      it "defines a method on the model's class" do
        expect(Cat).to respond_to(name)
      end

      it 'defines a method that returns query results from ReadySet' do
        results = Cat.find_by_name_cached('whiskers')
        expect(results.size).to eq(1)
        expect(results.first.name).to eq('whiskers')
      end
    end
  end
end
