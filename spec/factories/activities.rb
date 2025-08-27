FactoryBot.define do
  factory :activity do
    user { nil }
    actor { nil }
    notifiable { nil }
    action { "MyString" }
    read_at { "2025-08-27 18:59:00" }
  end
end
