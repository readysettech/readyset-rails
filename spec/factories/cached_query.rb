FactoryBot.define do
  factory :cached_query, class: 'Readyset::Query::CachedQuery' do
    id { 'q_eafb620c78f5b9ac' }
    count { 5 }
    text { 'SELECT * FROM "t" WHERE ("x" = $1)' }
    name { 'q_eafb620c78f5b9ac' }
    always { false }

    initialize_with { new(**attributes) }
  end

  factory :cached_query_2, class: 'Readyset::Query::CachedQuery' do
    id { 'q_8892818e62c34ecd' }
    count { 5 }
    text { 'SELECT * FROM "t" WHERE ("y" = $1)' }
    name { 'q_8892818e62c34ecd' }
    always { true }

    initialize_with { new(**attributes) }
  end
end
