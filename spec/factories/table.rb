FactoryBot.define do
  factory :table, class: 'Readyset::Table' do
    name { '"public"."cats"' }
    status { :snapshotted }
    description { 'Test description' }

    initialize_with { new(**attributes) }
  end
end
