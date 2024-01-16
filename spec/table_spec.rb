# frozen_string_literal: true

RSpec.describe Readyset::Table do
  describe '.all' do
    it 'returns the tables that exist on ReadySet' do
      tables = Readyset::Table.all

      expect(tables).to include(build(:table, description: ''))
    end
  end

  describe '.new' do
    it "assigns the object's attributes correctly" do
      status = Readyset::Table.new(**attributes_for(:table))

      expect(status.name).to eq('"public"."cats"')
      expect(status.status).to eq(:snapshotted)
      expect(status.description).to eq('Test description')
    end
  end
end
