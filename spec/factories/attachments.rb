FactoryBot.define do
  factory :attachment do
    link { "http://example.com/file.pdf" }
    association :user
    association :attachable, factory: :task
  end
end
