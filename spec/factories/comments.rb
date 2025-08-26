FactoryBot.define do
  factory :comment do
    sequence(:content) { |n| "This is comment content #{n}" }
    association :user
    association :commentable, factory: :task
  end
end
