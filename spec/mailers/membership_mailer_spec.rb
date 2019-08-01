# frozen_string_literal: true

describe MembershipMailer, type: :mailer do
  before { StripeMock.start }
  after { StripeMock.stop }

  describe 'new membership email' do
    let(:mail) do
      subscription, member = create_subscription
      MembershipMailer.new_membership_email(subscription.id).deliver
    end

    it 'renders the email' do
      subscription, member = create_subscription
      membership = Membership.where(stripe_id: 'monthly').last
      subscription.update_attributes(plan_id: membership.id)
      expect(mail.subject).to eq('New membership created for GetAudioFromVideo.com')
      expect(mail.to).to eq([member.email])
    end
  end

  describe 'update membership email' do
    let(:mail) do
      subscription, member = create_subscription
      MembershipMailer.upgrade_membership_email(1000, subscription.id).deliver
    end

    it 'renders the email' do
      subscription, member = create_subscription
      membership = Membership.where(stripe_id: 'monthly').last
      subscription.update_attributes(plan_id: membership.id)
      expect(mail.subject).to eq('Membership upgraded for GetAudioFromVideo.com')
      expect(mail.to).to eq([member.email])
    end
  end

  describe 'cancel membership email' do
    let(:mail) do
      subscription, member = create_subscription
      MembershipMailer.cancel_membership_email(subscription.id).deliver
    end

    it 'renders the email' do
      subscription, member = create_subscription
      membership = Membership.where(stripe_id: 'monthly').last
      subscription.update_attributes(plan_id: membership.id)
      expect(mail.subject).to eq('Membership canceled for GetAudioFromVideo.com')
      expect(mail.to).to eq([member.email])
    end
  end
end
