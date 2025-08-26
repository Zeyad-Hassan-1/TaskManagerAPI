FactoryBot.define do
  factory :comment do
    content { "MyText" }
    association :user
    association :commentable, factory: :task
  end
end
