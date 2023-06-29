FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    sequence(:email) { |n| "one#{n}@one.org" }
    password { "passwordexample" }
  end
end
