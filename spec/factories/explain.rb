FactoryBot.define do
  factory :explain, class: 'Readyset::Explain' do
    id { 'q_4f3fb9ad8f73bc0c' }
    text { 'SELECT "cats"."breed" FROM "cats" WHERE ("cats"."name" = $1)' }
    supported { :yes }

    initialize_with { new(**attributes) }
  end
end
