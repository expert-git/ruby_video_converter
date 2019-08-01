FactoryBot.define do
  factory :member_download do
    member_id { Faker::Number.digit }
    converted_video_id { Faker::Number.digit }
    evercookie_id { Faker::Crypto.sha1 }
  end
end