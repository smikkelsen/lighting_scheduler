FactoryBot.define do
  factory :pattern do
    sequence(:name) { |n| "Pattern #{n}" }
    folder { 'Test Folder' }
    custom { false }
    data { { 'effect' => 'rainbow', 'speed' => 5 } }

    trait :custom do
      custom { true }
    end

    trait :with_tags do
      after(:create) do |pattern|
        create_list(:tag, 2, patterns: [pattern])
      end
    end
  end
end