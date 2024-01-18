FactoryBot.define do
  factory :proxied_query, class: 'Readyset::Query::ProxiedQuery' do
    id { 'q_4f3fb9ad8f73bc0c' }
    count { 0 }
    text do
      <<~SQL.chomp
        SELECT
          "cats"."breed"
        FROM
          "cats"
        WHERE
          ("cats"."name" = $1)
      SQL
    end
    supported { :yes }

    factory :proxied_query_2 do
      id { 'q_803a0358269d346d' }
      text do
        <<~SQL.chomp
          SELECT
            "cats"."name"
          FROM
            "cats"
          WHERE
            ("cats"."breed" = $1)
        SQL
      end
    end

    factory :proxied_query_3 do
      id { 'q_803a0358269d346d' }
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

    factory :unsupported_proxied_query do
      id { 'q_f9bfc11a043b2f75' }
      text { 'SHOW TIME ZONE' }
      supported { :unsupported }
    end

    initialize_with { new(**attributes) }
  end
end
