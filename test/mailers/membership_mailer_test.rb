# frozen_string_literal: true

require 'test_helper'

class MembershipMailerTest < ActionMailer::TestCase
  test 'payment_succeeded_email' do
    mail = MembershipMailer.payment_succeeded_email
    assert_equal 'Membership payment for GetAudioFromVideo.com', mail.subject
    assert_equal ['to@example.org'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match 'Hi', mail.body.encoded
  end

  test 'payment_failed_email' do
    mail = MembershipMailer.payment_failed_email
    assert_equal 'Failed payment for GetAudioFromVideo.com', mail.subject
  end

  test 'cancel_membership_email' do
    mail = MembershipMailer.cancel_membership_email
    assert_equal 'Membership canceled for GetAudioFromVideo.com', mail.subject
  end

  test 'upgrade_membership_email' do
    mail = MembershipMailer.upgrade_membership_email
    assert_equal 'Membership upgraded for GetAudioFromVideo.com', mail.subject
  end
end
