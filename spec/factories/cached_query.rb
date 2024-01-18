FactoryBot.define do
  factory :cached_query, class: 'Readyset::Query::CachedQuery' do
    id { 'q_4f3fb9ad8f73bc0c' }
    always { false }
    count { 0 }
    text do
      <<~SQL.chomp
        SELECT
          "public"."cats"."breed"
        FROM
          "public"."cats"
        WHERE
          ("public"."cats"."name" = $1)
      SQL
    end
    name { 'q_4f3fb9ad8f73bc0c' }

    factory :cached_query_2 do
      id { 'q_803a0358269d346d' }
      name { 'q_803a0358269d346d' }
      text do
        <<~SQL.chomp
          SELECT
            "public"."cats"."name"
          FROM
            "public"."cats"
          WHERE
            ("public"."cats"."breed" = $1)
        SQL
      end
      always { true }
    end

    factory :cached_query_3 do
      id { 'q_699461ae91ebc79b' }
      name { 'q_699461ae91ebc79b' }
      text do
        <<~SQL.chomp
          SELECT
            COUNT(*)
          FROM
            "cats"
          WHERE
            ("cats"."breed" = $1)
        SQL
      end
    end

    initialize_with { new(**attributes) }
  end
end
