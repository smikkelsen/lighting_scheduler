FactoryBot.define do
  factory :zone_set do
    sequence(:name) { |n| "Zone Set #{n}" }
    default_zone_set { false }

    trait :default do
      default_zone_set { true }
    end

    trait :with_zones do
      after(:create) do |zone_set|
        create_list(:zone, 3, zone_set: zone_set)
      end
    end
  end
end