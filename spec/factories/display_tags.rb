FactoryBot.define do
  factory :display_tag do
    association :display
    association :tag
  end
end