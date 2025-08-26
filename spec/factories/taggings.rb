FactoryBot.define do
  factory :tagging do
    association :tag
    association :taggable, factory: :task
  end
end
