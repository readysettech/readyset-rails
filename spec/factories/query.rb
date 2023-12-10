FactoryBot.define do
  factory :query, class: 'Readyset::Query' do
    add_attribute(:'query id') { 'q_eafb620c78f5b9ac' }
    count { '5' }

    factory :cached_query do
      add_attribute(:'query text') { 'SELECT * FROM "t" WHERE ("x" = $1)' }
      add_attribute(:'cache name') { 'q_eafb620c78f5b9ac' }
      add_attribute(:'fallback behavior') { 'fallback allowed' }
    end

    factory :seen_but_not_cached_query do
      add_attribute(:'proxied query') { 'SELECT * FROM "t" WHERE ("x" = $1)' }
      add_attribute(:'readyset supported') { 'yes' }

      factory :pending_query do
        add_attribute(:'readyset supported') { 'pending' }
      end
    end

    factory :unsupported_query do
      add_attribute(:'query id') { 'q_f9bfc11a043b2f75' }
      add_attribute(:'proxied query') { 'SHOW TIME ZONE' }
      add_attribute(:'readyset supported') { 'unsupported' }
    end

    initialize_with { new(attributes) }
  end
end
