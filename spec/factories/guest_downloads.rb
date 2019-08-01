# frozen_string_literal: true

FactoryBot.define do
  factory :guest_download do
    remote_ip_address { '24.29.18.175' }
    trait :one do
      download_count { 1 }
    end
    trait :two do
      download_count { 2 }
    end
    trait :three do
      download_count { 3 }
    end
    evercookie_id { Faker::Crypto.sha1 }
  end
end
