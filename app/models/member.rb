# frozen_string_literal: true

class Member < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :omniauthable, omniauth_providers: %i[facebook google_oauth2]
  # :async,

  after_create :add_member_to_mailchimp_list

  has_many :subscriptions, ->(_sub) { where.not(stripe_id: nil) }, class_name: 'Payola::Subscription', foreign_key: :owner_id
  has_many :member_downloads
  has_many :converted_videos, through: :member_downloads

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |member|
      member.email = auth.info.email
      member.password = Devise.friendly_token[0, 20]
      # member.name = auth.info.name   # assumes the member model has a name
      member.image = auth.info.image # assumes the member model has an image
      # If you are using confirmable and the provider(s) you use validate emails,
      # uncomment the line below to skip the confirmation emails.
      member.skip_confirmation!
    end
  end

  def self.new_with_session(params, session)
    super.tap do |member|
      if data = session['devise.facebook_data'] && session['devise.facebook_data']['extra']['raw_info']
        member.email = data['email'] if member.email.blank?
      end
    end
  end

  def self.change_mailchimp_member_tag(member_email, tag_name)
    gibbon = Gibbon::Request.new(api_key: Rails.application.credentials[Rails.env.to_sym][:MAILCHIMP_API_KEY])

    # inactive 'Member' or 'Former member' previous tags
    member = gibbon.lists(Rails.application.credentials[Rails.env.to_sym][:MAILCHIMP_LIST_ID]).members(Digest::MD5.hexdigest(member_email)).retrieve.body
    inactive_old_tags = member['tags'].map { |t| { name: t['name'], status: 'inactive' } }

    # retrieve active 'Member' or 'Former member' tag
    tags = gibbon.lists(Rails.application.credentials[Rails.env.to_sym][:MAILCHIMP_LIST_ID]).segments.retrieve.body
    member_tag = { "status": 'active' }
    tags['segments'].map { |e| member_tag['name'] = e['name'] if e['name'] == tag_name && e['type'] == 'static' }
    update_tags = inactive_old_tags << member_tag

    # Update "Guest/Member/Former member" tag
    gibbon.lists(Rails.application.credentials[Rails.env.to_sym][:MAILCHIMP_LIST_ID]).members(Digest::MD5.hexdigest(member_email)).tags.create(body: { tags: update_tags }) if update_tags.present?

    # verify the member "Guest/Member/Former member" updated
    response = gibbon.lists(Rails.application.credentials[Rails.env.to_sym][:MAILCHIMP_LIST_ID]).members(Digest::MD5.hexdigest(member_email)).retrieve.body
    Rails.logger.info("Changed #{member_email} to #{response['tags'][0]['name']} tag in Mailchimp") if response
  end

  private

  def add_member_to_mailchimp_list
    gibbon = Gibbon::Request.new(api_key: Rails.application.credentials[Rails.env.to_sym][:MAILCHIMP_API_KEY])
    list_id = Rails.application.credentials[Rails.env.to_sym][:MAILCHIMP_LIST_ID]

    begin
      # retrieve "Guest" tag
      tags = gibbon.lists(list_id).segments.retrieve.body
      guest_tag = { "status": 'active' }
      tags['segments'].map { |e| guest_tag['name'] = e['name'] if e['name'] == 'Guest' && e['type'] == 'static' }

      # 'upsert' lets you update a record, if it exists, or insert it otherwise where supported by MailChimp's API.
      # add member to mailchimp list
      gibbon.lists(list_id).members(Digest::MD5.hexdigest(email)).upsert(body: { email_address: email, status: 'subscribed' })

      # add "Guest" tag to member
      gibbon.lists(list_id).members(Digest::MD5.hexdigest(email)).tags.create(body: { tags: [guest_tag] }) if guest_tag['name'].present?

      # verify tag added to member
      response = gibbon.lists(list_id).members(Digest::MD5.hexdigest(email)).retrieve.body
      # puts "#{response.inspect}"
      Rails.logger.info("Subscribed #{email} to Mailchimp list with 'Guest' tag") if response
    rescue Gibbon::MailChimpError => e
      puts e.message
    end
  end
end
