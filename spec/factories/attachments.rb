FactoryBot.define do
  factory :attachment do
    sequence(:link) { |n| "https://example.com/file-#{n}.pdf" }
    association :user
    association :attachable, factory: :task
  end
end
