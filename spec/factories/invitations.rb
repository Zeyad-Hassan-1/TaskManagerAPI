FactoryBot.define do
  factory :invitation do
    association :inviter, factory: :user
    association :invitee, factory: :user
    association :invitable, factory: :team
    status { "pending" }
    role { "member" }

    trait :for_team do
      association :invitable, factory: :team
    end

    trait :for_project do
      association :invitable, factory: :project
    end

    trait :accepted do
      status { "accepted" }
    end

    trait :declined do
      status { "declined" }
    end
  end
end
