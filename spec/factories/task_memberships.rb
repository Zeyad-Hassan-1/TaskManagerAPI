FactoryBot.define do
  factory :task_membership do
    user
    task
    role { :assignee }
  end
end
