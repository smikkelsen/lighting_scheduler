FactoryBot.define do
  factory :pattern_tag do
    association :pattern
    association :tag
  end
end
