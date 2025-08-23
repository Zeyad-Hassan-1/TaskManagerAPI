FactoryBot.define do
  factory :team do
    sequence(:name) { |n| "Team #{n}" }
    sequence(:discription) { |n| "Description for team #{n}" }
  end
end
