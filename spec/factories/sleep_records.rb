FactoryBot.define do
  factory :sleep_record do
    association :user
    clock_in_at { Time.current }

    trait :completed do
      clock_out_at { 8.hours.after(clock_in_at) }
    end

    trait :active do
      clock_out_at { nil }
    end

    trait :short_sleep do
      clock_out_at { 6.hours.after(clock_in_at) }
    end

    trait :long_sleep do
      clock_out_at { 10.hours.after(clock_in_at) }
    end
  end
end
