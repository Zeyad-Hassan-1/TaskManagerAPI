FactoryBot.define do
  factory :team do
    sequence(:name) { |n| "Team #{n}" }
    sequence(:description) { |n| "Description for team #{n}" }
  end
end
