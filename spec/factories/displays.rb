FactoryBot.define do
  factory :display do
    sequence(:name) { |n| "Display #{n}" }
    workflow_state { 'active' }
    description { 'Test display description' }
    association :zone_set

    trait :with_patterns do
      after(:create) do |display|
        create_list(:display_pattern, 2, display: display)
      end
    end

    trait :with_tags do
      after(:create) do |display|
        create_list(:tag, 2, displays: [display])
      end
    end
  end
end