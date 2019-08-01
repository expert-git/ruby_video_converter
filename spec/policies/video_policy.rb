# frozen_string_literal: true

describe VideoPolicy do
  subject { described_class }
  let(:guest_video_conversion_limit) do
    Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_CONVERSION_LIMIT].to_i
  end
  let(:guest_skip_delay_countdown_limit) do
    Rails.application.credentials[Rails.env.to_sym][:GUEST_SKIP_DELAY_COUNTDOWN_LIMIT].to_i
  end

  describe 'show_guest_delay?' do
    describe 'Authorized member' do
      it 'Show guest delay: authorized member, ever_cookie not exists' do
        member = create(:member)
        expect(VideoPolicy.new(member, Video).show_guest_delay?(false)).to be_falsey
      end

      it 'Show guest delay: authorized member, ever_cookie exists' do
        member = create(:member)
        expect(VideoPolicy.new(member, Video).show_guest_delay?(true)).to be_truthy
      end
    end
    describe 'Guest user' do
      it 'Show guest delay: authorized member, ever_cookie not exists' do
        member = nil
        expect(VideoPolicy.new(member, Video).show_guest_delay?(false)).to be_falsey
      end

      it 'Show guest delay: authorized member, ever_cookie exists' do
        member = nil
        expect(VideoPolicy.new(member, Video).show_guest_delay?(true)).to be_truthy
      end
    end
    describe 'Authorized member, limit reached' do
      it 'Show guest delay: authorized member, ever_cookie not exists' do
        member = create(:member)
        create(:guest_download, download_count: guest_skip_delay_countdown_limit)
        expect(VideoPolicy.new(member, Video).show_guest_delay?(false)).to be_truthy
      end

      it 'Show guest delay: authorized member, ever_cookie exists' do
        member = create(:member)
        create(:guest_download, download_count: guest_skip_delay_countdown_limit)
        expect(VideoPolicy.new(member, Video).show_guest_delay?(true)).to be_truthy
      end
    end
    describe 'Guest user, limit reached' do
      it 'Show guest delay: authorized member, ever_cookie not exists' do
        member = nil
        create(:guest_download, download_count: guest_skip_delay_countdown_limit)
        expect(VideoPolicy.new(member, Video).show_guest_delay?(false)).to be_truthy
      end

      it 'Show guest delay: authorized member, ever_cookie exists' do
        member = nil
        create(:guest_download, download_count: guest_skip_delay_countdown_limit)
        expect(VideoPolicy.new(member, Video).show_guest_delay?(true)).to be_truthy
      end
    end

    describe 'Authorized member, limit not reached' do
      it 'Show guest delay: authorized member, ever_cookie not exists' do
        member = create(:member)
        create(:guest_download, download_count: guest_skip_delay_countdown_limit - 1)
        expect(VideoPolicy.new(member, Video).show_guest_delay?(false)).to be_falsey
      end

      it 'Show guest delay: authorized member, ever_cookie exists' do
        member = create(:member)
        create(:guest_download, download_count: guest_skip_delay_countdown_limit - 1)
        expect(VideoPolicy.new(member, Video).show_guest_delay?(true)).to be_falsey
      end
    end
    describe 'Guest user, limit not reached' do
      it 'Show guest delay: authorized member, ever_cookie not exists' do
        member = nil
        create(:guest_download, download_count: guest_skip_delay_countdown_limit - 1)
        expect(VideoPolicy.new(member, Video).show_guest_delay?(false)).to be_falsey
      end

      it 'Show guest delay: authorized member, ever_cookie exists' do
        member = nil
        create(:guest_download, download_count: guest_skip_delay_countdown_limit - 1)
        expect(VideoPolicy.new(member, Video).show_guest_delay?(true)).to be_falsey
      end
    end
  end

  describe 'authorized_to_download?' do
    describe 'Without guest downloads' do
      it 'Allow download: authorized member, ever_cookie not exists' do
        member = create(:member)
        expect(VideoPolicy.new(member, Video).authorized_to_download?(false)).to be_truthy
      end

      it 'Deny download: authorized member, ever_cookie exists' do
        member = create(:member)
        expect(VideoPolicy.new(member, Video).authorized_to_download?(true)).to be_falsey
      end

      it 'Allow download: guest user, ever_cookie not exists' do
        member = nil
        expect(VideoPolicy.new(member, Video).authorized_to_download?(false)).to be_truthy
      end

      it 'Deny download: guest user, ever_cookie exists' do
        member = nil
        expect(VideoPolicy.new(member, Video).authorized_to_download?(true)).to be_falsey
      end
    end

    describe 'With guest downloads (guest_video_conversion_limit reached)' do
      it 'deny download: authorized member, ever_cookie not exists, guest_video_conversion_limit reached' do
        member = create(:member)
        create(:guest_download, download_count: guest_video_conversion_limit)
        expect(VideoPolicy.new(member, Video).authorized_to_download?(false)).to be_falsey
      end

      it 'deny download: authorized member, ever_cookie exists, guest_video_conversion_limit reached' do
        member = create(:member)
        create(:guest_download, download_count: guest_video_conversion_limit)
        expect(VideoPolicy.new(member, Video).authorized_to_download?(true)).to be_falsey
      end

      it 'deny download: guest user, ever_cookie not exists, guest_video_conversion_limit reached' do
        member = nil
        create(:guest_download, download_count: guest_video_conversion_limit)
        expect(VideoPolicy.new(member, Video).authorized_to_download?(false)).to be_falsey
      end

      it 'deny download: guest user, ever_cookie exists, guest_video_conversion_limit reached' do
        member = nil
        create(:guest_download, download_count: guest_video_conversion_limit)
        expect(VideoPolicy.new(member, Video).authorized_to_download?(true)).to be_falsey
      end
    end

    describe 'Guest downloads (guest_video_conversion_limit not exceeded)' do
      it 'allow download: authorized member, ever_cookie not exists, guest_video_conversion_limit not exceeded' do
        member = create(:member)
        create(:guest_download, download_count: guest_video_conversion_limit - 1)
        expect(VideoPolicy.new(member, Video).authorized_to_download?(false)).to be_truthy
      end

      it 'allow download: authorized member, ever_cookie exists, guest_video_conversion_limit not exceeded' do
        member = create(:member)
        create(:guest_download, download_count: guest_video_conversion_limit - 1)
        expect(VideoPolicy.new(member, Video).authorized_to_download?(true)).to be_truthy
      end

      it 'allow download: guest user, ever_cookie not exists, guest_video_conversion_limit not exceeded' do
        member = nil
        create(:guest_download, download_count: guest_video_conversion_limit - 1)
        expect(VideoPolicy.new(member, Video).authorized_to_download?(false)).to be_truthy
      end

      it 'allow download: guest user, ever_cookie exists, guest_video_conversion_limit not exceeded' do
        member = nil
        create(:guest_download, download_count: guest_video_conversion_limit - 1)
        expect(VideoPolicy.new(member, Video).authorized_to_download?(true)).to be_truthy
      end
    end
  end
end
