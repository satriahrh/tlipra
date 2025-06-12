FactoryBot.define do
  factory :followership do
    association :follower, factory: :user
    association :followed, factory: :user
    status { 'active' }

    trait :unfollowed do
      status { 'unfollowed' }
      unfollowed_at { 1.hour.ago }
    end
  end
end
