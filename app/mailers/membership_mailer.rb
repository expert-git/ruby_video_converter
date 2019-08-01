class MembershipMailer < ApplicationMailer
  helper MembershipsHelper
  
  def payment_succeeded_email(amount, date, subscription_id)
    set_amount_and_date(amount, date)
    set_subscription_and_member(subscription_id)
    mail(to: @member.email, subject: "Membership payment for GetAudioFromVideo.com")
  end

  def payment_failed_email(amount, date, subscription_id)
    set_amount_and_date(amount, date)
    set_subscription_and_member(subscription_id)
    mail(to: @member.email, subject: "Failed payment for GetAudioFromVideo.com")
  end

  def new_membership_email(subscription_id)
    set_subscription_and_member(subscription_id)
    mail(to: @member.email, subject: "New membership created for GetAudioFromVideo.com")
  end

  def cancel_membership_email(subscription_id)
    set_subscription_and_member(subscription_id)
    mail(to: @member.email, subject: "Membership canceled for GetAudioFromVideo.com")
  end

  def upgrade_membership_email(old_amount, subscription_id)
    set_subscription_and_member(subscription_id)
    @difference = (@subscription.amount- old_amount)
    mail(to: @member.email, subject: "Membership upgraded for GetAudioFromVideo.com")
  end

  private

  def set_amount_and_date(amount, date)
    @amount = amount
    @date = date
  end

  def set_subscription_and_member(subscription_id)
    @subscription = Payola::Subscription.find_by(id: subscription_id)
    @member = Member.find_by(id: @subscription.owner_id)
  end


end
