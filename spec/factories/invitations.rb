FactoryBot.define do
  factory :invitation do
    inviter { nil }
    invitee { nil }
    team { nil }
    project { nil }
    status { "MyString" }
    role { "MyString" }
  end
end
