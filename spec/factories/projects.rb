FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    sequence(:description) { |n| "Description for project #{n}" }
    team

    transient do
      owner { nil }
    end

    after(:create) do |project, evaluator|
      if evaluator.owner
        create(:project_membership, project: project, user: evaluator.owner, role: :owner)
      end
    end
  end
end
