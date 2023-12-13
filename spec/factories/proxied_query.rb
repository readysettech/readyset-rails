FactoryBot.define do
  factory :proxied_query, class: 'Readyset::Query::ProxiedQuery' do
    id { 'q_eafb620c78f5b9ac' }
    count { 5 }

    text { 'SELECT * FROM "t" WHERE ("x" = $1)' }
    supported { :yes }

    factory :pending_query do
      supported { :pending }
    end

    factory :unsupported_query do
      id { 'q_f9bfc11a043b2f75' }
      text { 'SHOW TIME ZONE' }
      supported { :unsupported }
    end

    initialize_with { new(**attributes) }
  end
end
