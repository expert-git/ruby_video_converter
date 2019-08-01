# frozen_string_literal: true

describe ConvertedVideoPolicy do
  subject { described_class }
  let(:guest_skip_signup_required_modal_limit) do
    Rails.application.credentials[Rails.env.to_sym][:GUEST_SKIP_SIGNUP_REQUIRED_MODAL_LIMIT].to_i
  end

  permissions :allow_download? do
    it 'grants access for authorized member' do
      member = create(:member)
      converted_video = create(:converted_video)
      expect(subject).to permit(member, converted_video)
    end

    it 'grants access for guest users if guest download limit not exceeded (with empty guest downloads)' do
      member = nil
      converted_video = create(:converted_video)
      expect(subject).to permit(member, converted_video)
    end

    it 'grants access for guest users if guest download limit not exceeded (with allowed guest downloads)' do
      member = nil
      converted_video = create(:converted_video)
      create(:guest_download, download_count: guest_skip_signup_required_modal_limit - 1)
      expect(subject).to permit(member, converted_video)
    end

    it 'denies access for guest users if guest download limit exceeded' do
      member = nil
      converted_video = create(:converted_video)
      create(:guest_download, download_count: guest_skip_signup_required_modal_limit)
      expect(subject).not_to permit(member, converted_video)
    end
  end
end
