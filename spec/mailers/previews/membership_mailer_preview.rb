# Preview all emails at http://localhost:3000/rails/mailers/membership_mailer
class MembershipMailerPreview < ActionMailer::Preview

  def new_membership_email
  	subscription = Payola::Subscription.first
  	MembershipMailer.new_membership_email(subscription.id).deliver
  end
  
  def upgrade_membership_email
  	subscription = Payola::Subscription.last
  	old_amount = 1000
  	MembershipMailer.upgrade_membership_email(old_amount, subscription.id).deliver
  end

  def cancel_membership_email
  	subscription = Payola::Subscription.first
  	MembershipMailer.cancel_membership_email(subscription.id).deliver	
  end	
  
end	