FactoryBot.define do
  factory :explain, class: 'Readyset::Explain' do
    id { 'q_eafb620c78f5b9ac' }
    text { 'SELECT * FROM "t" WHERE ("x" = $1)' }
    supported { :yes }

    initialize_with { new(**attributes) }
  end
end
