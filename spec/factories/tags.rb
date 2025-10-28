FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "Tag #{n}" }

    trait :with_patterns do
      after(:create) do |tag|
        create_list(:pattern, 2, tags: [tag])
      end
    end

    trait :with_displays do
      after(:create) do |tag|
        create_list(:display, 2, tags: [tag])
      end
    end
  end
end