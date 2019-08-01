# frozen_string_literal: true

FactoryBot.define do
  factory :member do
    sequence(:email) { |n| "user_#{n}@getaudiofromvideo.com" }
    password { 'secret01' }
    password_confirmation { 'secret01' }
  end
end
