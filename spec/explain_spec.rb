# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Readyset::Explain do
  describe '.call' do
    it 'retrieves the explain information from ReadySet' do
      explain = build(:explain)

      result = Readyset::Explain.call(explain.text)

      expect(result).to eq(explain)
    end
  end

  describe '.new' do
    it 'creates a new `Explain` with the given attributes' do
      attributes = attributes_for(:explain)

      explain = Readyset::Explain.new(**attributes)

      expect(explain).to eq(build(:explain))
    end
  end

  describe '#==' do
    context "when the other `Explain` has an attribute that doesn't match self's" do
      it 'returns false' do
        explain = build(:explain)
        other = build(:explain, supported: :pending)

        result = explain == other

        expect(result).to eq(false)
      end
    end

    context 'when the attributes of the other `Explain` match those of `self`' do
      it 'returns true' do
        explain = build(:explain)
        other = build(:explain)

        result = explain == other

        expect(result).to eq(true)
      end
    end
  end

  describe '#unsupported?' do
    context 'when the `Explain` indicates that the query is supported' do
      it 'returns false' do
        explain = build(:explain)

        result = explain.unsupported?

        expect(result).to eq(false)
      end
    end

    context 'when the `Explain` indicates that the query is unsupported' do
      it 'returns false' do
        explain = build(:explain, supported: :unsupported)

        result = explain.unsupported?

        expect(result).to eq(true)
      end
    end
  end
end
