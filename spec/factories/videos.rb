FactoryBot.define do
  factory :video do
    sequence(:url) { |n| "https://youtu.be/xxxxx#{n}" }
    title { "title" }
    description { "content" }
    sequence(:video_id) { |n| "123#{n}" } 
    association :user
  end
end
