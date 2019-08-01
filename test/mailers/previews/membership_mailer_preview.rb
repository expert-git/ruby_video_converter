# Preview all emails at http://localhost:3000/rails/mailers/membership_mailer
class MembershipMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/membership_mailer/payment_succeeded_email
  def payment_succeeded_email(subscription_id)
    MembershipMailer.payment_succeeded_email
  end

  # Preview this email at http://localhost:3000/rails/mailers/membership_mailer/payment_failed_email
  def payment_failed_email(subscription_id)
    MembershipMailer.payment_failed_email
  end

  # Preview this email at http://localhost:3000/rails/mailers/membership_mailer/cancel_membership_email
  def cancel_membership_email(subscription_id)
    MembershipMailer.cancel_membership_email
  end

  # Preview this email at http://localhost:3000/rails/mailers/membership_mailer/upgrade_membership_email
  def upgrade_membership_email(subscription_id)
    MembershipMailer.upgrade_membership_email
  end

end
