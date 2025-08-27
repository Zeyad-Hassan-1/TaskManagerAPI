FactoryBot.define do
  factory :activity do
    association :user
    association :actor, factory: :user
    association :notifiable, factory: :team
    action { "invited" }
    read_at { nil }

    trait :read do
      read_at { Time.current }
    end
  end
end
