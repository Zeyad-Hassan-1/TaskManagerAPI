FactoryBot.define do
  factory :task do
    sequence(:name) { |n| "Task #{n}" }
    sequence(:description) { |n| "Description for task #{n}" }
    priority { 0 }
    due_date { 2.days.from_now }
    project
  end
end
