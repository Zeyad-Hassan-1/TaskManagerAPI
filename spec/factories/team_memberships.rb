FactoryBot.define do
  factory :team_membership do
    user
    team
    role { :member }
  end
end
