FactoryBot.define do
  factory :zone do
    sequence(:name) { |n| "Zone #{n}" }
    pixel_count { 100 }

    # Realistic port_map format matching Jellyfish controller structure
    port_map do
      [
        {
          'ctlrName' => 'JellyFish-CF1D.local',
          'phyEndIdx' => pixel_count - 1,
          'phyPort' => 1,
          'phyStartIdx' => 0,
          'zoneRGBStartIdx' => 0
        }
      ]
    end

    uuid { SecureRandom.uuid }
    zone_set { nil }

    trait :in_set do
      association :zone_set
    end

    trait :current do
      zone_set_id { nil }
    end

    # Trait for multi-segment zones (like Corners Front Left with 2 segments)
    trait :multi_segment do
      pixel_count { 20 }
      port_map do
        [
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 138,
            'phyPort' => 2,
            'phyStartIdx' => 129,
            'zoneRGBStartIdx' => 0
          },
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 134,
            'phyPort' => 4,
            'phyStartIdx' => 143,
            'zoneRGBStartIdx' => 10
          }
        ]
      end
    end

    # Trait for large "All Lights" style zone
    trait :all_lights do
      name { 'All Lights' }
      pixel_count { 512 }
      port_map do
        [
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 511,
            'phyPort' => 1,
            'phyStartIdx' => 0,
            'zoneRGBStartIdx' => 0
          }
        ]
      end
    end
  end
end