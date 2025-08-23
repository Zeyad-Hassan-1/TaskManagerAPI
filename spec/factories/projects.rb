FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    sequence(:discription) { |n| "Description for project #{n}" }
    team
  end
end
