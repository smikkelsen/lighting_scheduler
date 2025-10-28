FactoryBot.define do
  factory :display_pattern do
    association :display
    association :pattern
    zones { ['Zone 1', 'Zone 2'] }
  end
end