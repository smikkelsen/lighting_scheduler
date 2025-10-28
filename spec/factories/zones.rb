FactoryBot.define do
  factory :zone do
    sequence(:name) { |n| "Zone #{n}" }
    pixel_count { 100 }
    port_map { [1, 2, 3] }
    uuid { SecureRandom.uuid }
    zone_set { nil }

    trait :in_set do
      association :zone_set
    end

    trait :current do
      zone_set_id { nil }
    end
  end
end