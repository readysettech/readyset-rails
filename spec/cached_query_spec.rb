# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Readyset::Query::CachedQuery do
  describe '.all' do
    it 'returns the existing caches' do
      cache = build_and_create_cache(:cached_query)

      caches = Readyset::Query::CachedQuery.all

      expect(caches).to eq([cache])
    end
  end

  describe '.drop_all!' do
    it 'drops all the caches on ReadySet' do
      build_and_create_cache(:cached_query)
      build_and_create_cache(:cached_query_2)

      size_before_drop = Readyset::Query::CachedQuery.all.size
      Readyset::Query::CachedQuery.drop_all!
      size_after_drop = Readyset::Query::CachedQuery.all.size

      expect(size_before_drop).to eq(2)
      expect(size_after_drop).to eq(0)
    end
  end

  describe '.find' do
    context 'when a cached query with the given ID exists' do
      it 'returns the expected cache' do
        expected_cache = build_and_create_cache(:cached_query)

        result = Readyset::Query::CachedQuery.find(expected_cache.id)

        expect(expected_cache).to eq(result)
      end
    end

    context 'when a cached query with the given ID does not exist' do
      it 'raises a Readyset::Query::NotFoundError' do
        cache = build(:cached_query)

        expect { Readyset::Query::CachedQuery.find(cache.id) }.
          to raise_error(Readyset::Query::NotFoundError)
      end
    end
  end

  describe '.new' do
    it "assigns the object's attributes correctly" do
      attrs = attributes_for(:cached_query)
      cache = Readyset::Query::CachedQuery.new(**attrs)

      expect(cache.id).to eq('q_4f3fb9ad8f73bc0c')
      expect(cache.always).to eq(false)

      expected_query =
        <<~SQL.chomp
          SELECT
            "public"."cats"."breed"
          FROM
            "public"."cats"
          WHERE
            ("public"."cats"."name" = $1)
        SQL
      expect(cache.text).to eq(expected_query)

      expect(cache.name).to eq('q_4f3fb9ad8f73bc0c')
      expect(cache.count).to eq(0)
    end
  end

  describe '#always?' do
    context 'when the query supports fallback' do
      it 'returns false' do
        cache = build(:cached_query, always: false)

        result = cache.always?

        expect(result).to eq(false)
      end
    end

    context 'when the query does not support fallback' do
      it 'returns true' do
        cache = build(:cached_query, always: true)

        result = cache.always?

        expect(result).to eq(true)
      end
    end
  end

  describe '#drop!' do
    it 'drops the cache on ReadySet' do
      cache = build_and_create_cache(:cached_query)

      size_before_drop = Readyset::Query::CachedQuery.all.size
      cache.drop!
      size_after_drop = Readyset::Query::CachedQuery.all.size

      expect(size_before_drop).to eq(1)
      expect(size_after_drop).to eq(0)
    end

    it 'returns the newly-proxied query' do
      cache = build_and_create_cache(:cached_query)

      proxied = cache.drop!

      expect(proxied).to eq(build(:proxied_query))
    end
  end
end
