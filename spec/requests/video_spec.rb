# frozen_string_literal: true

describe 'Video' do
  before(:each) do
    StripeMock.start
    DownloadHelper.clear_downloads
  end

  after(:each) do
    StripeMock.stop
    DownloadHelper.clear_downloads
  end

  specify 'should able to access home page' do
    visit root_path
    expect(current_path).to eq '/'
    expect(page).to have_content 'Convert Youtube videos to MP3'
  end

  specify 'should able to search the videos from home page' do
    visit root_path
    fill_in 'terms', with: 'nope.avi'
    click_on 'Search'
    expect(current_path).to eq '/videos/search'
    expect(page).to have_content 'Search results'
    expect(page).to have_content 'nope.avi'
  end

  specify 'should able to access video page' do
    visit root_path
    fill_in 'terms', with: 'nope.avi'
    click_on 'Search'
    first('.card-title a').click
    expect(page).to have_content 'Format'
  end

  specify 'should able to search the videos from membership new page before login' do
    visit new_membership_path
    fill_in 'terms', with: 'nope.avi'
    click_on 'Search'
    expect(current_path).to eq '/videos/search'
    expect(page).to have_content 'Search results'
    expect(page).to have_content 'nope.avi'
  end

  specify 'should able to search the videos from membership new page after login' do
    login_as_member
    create_membership
    visit new_membership_path
    fill_in 'terms', with: 'nope.avi'
    click_on 'Search'
    expect(current_path).to eq '/videos/search'
    expect(page).to have_content 'Search results'
    expect(page).to have_content 'nope.avi'
  end

  specify 'should able to select audio format from the drop down options of Format on video page' do
    navigate_to_video_page
    select 'MP3', from: 'video_format'
    expect(page).to have_select('video_format', selected: 'MP3')
  end

  specify 'should able to select video format from the drop down options of Format on video page' do
    navigate_to_video_page
    select 'MP4', from: 'video_format'
    expect(page).to have_select('video_format', selected: 'MP4')
  end

  specify 'should able to change the start time in the start field on video page' do
    navigate_to_video_page
    fill_in 'start_time', with: '00:02'
    expect(page).to have_field('start_time', with: '00:02')
  end

  specify 'should able to change the end time in the end field on video page' do
    navigate_to_video_page
    fill_in 'end_time', with: '00:05'
    expect(page).to have_field('end_time', with: '00:05')
  end

  specify 'should auto format the start time on video page', js: true do
    navigate_to_video_page
    start_time = find('#start-time')['value']
    format_length = start_time.split(':').count
    input_start_time, compare_time = get_input_time(format_length)
    fill_in 'start_time', with: input_start_time
    page.find('body').click
    sleep(5)
    expect(page).to have_field('start_time', with: compare_time)
  end

  specify 'should auto format the end time on video page', js: true do
    navigate_to_video_page
    end_time = find('#end-time')['value']
    format_length = end_time.split(':').count
    input_end_time, compare_time = get_input_time(format_length, false)
    fill_in 'end_time', with: input_end_time
    page.find('body').click
    sleep(5)
    expect(page).to have_field('end_time', with: compare_time)
  end

  specify 'should not allow start time and end time to be same', js: true do
    navigate_to_video_page
    input_start_time = find('#start-time')['value']
    sleep(1)
    input_end_time = find('#end-time')['value']
    sleep(1)
    format_length = input_start_time.split(':').count
    start_time, end_time = start_end_times(format_length)
    fill_in 'start_time', with: start_time
    page.find('body').click
    sleep(1)
    fill_in 'end_time', with: end_time
    page.find('body').click
    sleep(1)
    expect(page).to have_field('start_time', with: start_time)
    expect(page).to have_field('end_time', with: input_end_time)
  end

  specify 'should not allow start time to be greater than end time', js: true do
    navigate_to_video_page
    input_start_time = find('#start-time')['value']
    sleep(1)
    input_end_time = find('#end-time')['value']
    sleep(1)
    format_length = input_start_time.split(':').count
    start_time, end_time = start_end_times(format_length, true)
    fill_in 'start_time', with: start_time
    page.find('body').click
    fill_in 'end_time', with: end_time
    page.find('body').click
    sleep(1)
    expect(page).to have_field('start_time', with: input_start_time)
    expect(page).to have_field('end_time', with: input_end_time)
  end

  specify "for guest user should not allow video conversion to MP3 format if video duration is greater than #{Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_DURATION_LIMIT_MINUTES]} minutes", js: true do
    navigate_to_video_page_longer_than_6_minutes(true)
    select('MP3', from: 'Format')
    click_button 'Start conversion'
    expect(page).to have_content "Guests cannot convert videos longer than #{Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_DURATION_LIMIT_MINUTES]} minutes."
  end

  specify "member without active subscription should not allow video conversion to MP3 format if video duration is greater than #{Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_DURATION_LIMIT_MINUTES]} minutes", js: true do
    login_as_member
    navigate_to_video_page_longer_than_6_minutes(true)
    select('MP3', from: 'Format')
    click_button 'Start conversion'
    expect(page).to have_content "Guests cannot convert videos longer than #{Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_DURATION_LIMIT_MINUTES]} minutes."
  end

  specify 'should perform video conversion to MP3 format' do
    navigate_to_video_page(true)
    video_id = find('#id', visible: false).value
    select('MP3', from: 'Format')
    click_button 'Start conversion'
    wait_to_download(video_id)
    video = Video.find_by_ytid(video_id)
    video = elapse_sleep_time(video)
    expect(video.title).to eql(first('.col-md-7 h5').text)
    expect(video.video_file.file).to exist
    expect(video.format).to eql 'mp4'
    converted_video = video.converted_videos.where('format = ?', 'mp3').last
    converted_video, record_from = elapse_sleep_time(converted_video, video, 'mp3')
    expect(converted_video.format).to eql 'mp3'
    expect(converted_video.video_file.file).to exist
    expect(converted_video.from).to eql('youtube_dl')
  end

  specify 'should perform video conversion to M4A format' do
    navigate_to_video_page(true)
    video_id = find('#id', visible: false).value
    select 'M4A', from: 'video_format'
    click_button 'Start conversion'
    wait_to_download(video_id)
    video = Video.find_by_ytid(video_id)
    video = elapse_sleep_time(video)
    expect(video.title).to eql(first('.col-md-7 h5').text)
    expect(video.video_file.file).to exist
    expect(video.format).to eql 'mp4'
    converted_videos = video.converted_videos
    record_from = converted_videos.count == 1 ? 'youtube_dl' : 'master_file'
    converted_video = converted_videos.where('format = ?', 'm4a').last
    converted_video, record_from = elapse_sleep_time(converted_video, video, 'm4a', record_from)
    expect(converted_video.format).to eql 'm4a'
    expect(converted_video.video_file.file).to exist
    expect(converted_video.from).to eql(record_from)
  end

  specify 'should perform video conversion to FLV format' do
    navigate_to_video_page(true)
    video_id = find('#id', visible: false).value
    select 'FLV', from: 'video_format'
    click_button 'Start conversion'
    wait_to_download(video_id)
    video = Video.find_by_ytid(video_id)
    video = elapse_sleep_time(video)
    expect(video.title).to eql(first('.col-md-7 h5').text)
    expect(video.video_file.file).to exist
    expect(video.format).to eql 'mp4'
    converted_videos = video.converted_videos
    record_from = converted_videos.count == 1 ? 'youtube_dl' : 'master_file'
    converted_video = converted_videos.where('format = ?', 'flv').last
    converted_video, record_from = elapse_sleep_time(converted_video, video, 'flv', record_from)
    expect(converted_video.format).to eql 'flv'
    expect(converted_video.video_file.file).to exist
    expect(converted_video.from).to eql(record_from)
  end

  specify "should allow video conversion to MP3 format if video duration is greater than #{Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_DURATION_LIMIT_MINUTES]} minutes" do
    subscription, member = create_subscription
    sign_in member
    navigate_to_video_page
    video_id = find('#id', visible: false).value
    select 'MP3', from: 'video_format'
    click_button 'Start conversion'
    wait_to_download(video_id)
    video = Video.find_by_ytid(video_id)
    video = elapse_sleep_time(video)
    expect(video.title).to eql(first('.col-md-7 h5').text)
    expect(video.video_file.file).to exist
    expect(video.format).to eql 'mp4'
    converted_videos = video.converted_videos
    record_from = converted_videos.count == 1 ? 'youtube_dl' : 'master_file'
    converted_video = converted_videos.where('format = ?', 'mp3').last
    converted_video, record_from = elapse_sleep_time(converted_video, video, 'mp3', record_from)
    expect(converted_video.format).to eql 'mp3'
    expect(converted_video.video_file.file).to exist
    expect(converted_video.from).to eql(record_from)
  end

  specify 'guest user should view delay timer when clicked on start conversion button' do
    guest_download = FactoryBot.create(:guest_download, :one)
    navigate_to_video_page(true)
    click_button 'Start conversion'
    sleep(1)
    expect(page).to have_content 'Please wait:'
  end

  specify 'guest user should not able to perform video conversion after reaching conversion limit', js: true do
    guest_download = FactoryBot.create(:guest_download, download_count: Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_CONVERSION_LIMIT].to_i)
    navigate_to_video_page(true)
    click_button 'Start conversion'
    sleep(Rails.application.credentials[Rails.env.to_sym][:GUEST_SKIP_DELAY_COUNTDOWN_LIMIT].to_i)
    sleep(10)
    expect(page).to have_content "Download limit of #{Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_CONVERSION_LIMIT]} videos reached. Join as member for unlimited downloads!"
  end

  specify 'member without active subscription should view delay timer when clicked on start conversion button' do
    login_as_member
    guest_download = FactoryBot.create(:guest_download, :one)
    navigate_to_video_page(true)
    click_button 'Start conversion'
    sleep(1)
    expect(page).to have_content 'Please wait:'
  end

  specify 'member without active subscription should not able to perform video conversion after reaching conversion limit', js: true do
    login_as_member
    guest_download = FactoryBot.create(:guest_download, download_count: Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_CONVERSION_LIMIT].to_i)
    navigate_to_video_page(true)
    click_button 'Start conversion'
    sleep(Rails.application.credentials[Rails.env.to_sym][:GUEST_SKIP_DELAY_COUNTDOWN_LIMIT].to_i)
    sleep(10)
    expect(page).to have_content "Download limit of #{Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_CONVERSION_LIMIT]} videos reached. Join as member for unlimited downloads!"
  end

  specify 'member with active subscription should not view delay timer when clicked on start conversion button', js: true do
    subscription, member = create_subscription
    sign_in member
    guest_download = FactoryBot.create(:guest_download, :one)
    navigate_to_video_page
    click_button 'Start conversion'
    sleep(Rails.application.credentials[Rails.env.to_sym][:GUEST_SKIP_DELAY_COUNTDOWN_LIMIT].to_i)
    expect(page).not_to have_content 'Please wait:'
  end

  specify 'guest conversion limit should not be applicable for member with active subscription' do
    subscription, member = create_subscription
    sign_in member
    guest_download = FactoryBot.create(:guest_download, download_count: Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_CONVERSION_LIMIT].to_i)
    navigate_to_video_page
    click_button 'Start conversion'
    sleep(Rails.application.credentials[Rails.env.to_sym][:GUEST_SKIP_DELAY_COUNTDOWN_LIMIT].to_i)
    expect(page).not_to have_content "Download limit of #{Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_CONVERSION_LIMIT]} videos reached. Join as member for unlimited downloads!"
  end

  specify 'guest user should able to download the converted video' do
    navigate_to_video_page(true)
    video_id = find('#id', visible: false).value
    select 'MP4', from: 'video_format'
    click_button 'Start conversion'
    wait_to_download(video_id)
    video = Video.find_by_ytid(video_id)
    video = elapse_sleep_time(video)
    converted_video = video.converted_videos.where('format = ?', 'mp4').last
    converted_video, record_from = elapse_sleep_time(converted_video, video, 'mp4')
    visit dispatch_download_file_path(converted_video_id: converted_video)
    sleep(1)
    expect(page.response_headers['Content-Type']).to eql 'application/mp4'
    header = page.response_headers['Content-Disposition']
    expect(header).to match /^attachment/
    expect(header).to match /filename=\"#{converted_video.filename}\"$/
  end

  specify 'member without active subscription should able to download the converted video' do
    login_as_member
    navigate_to_video_page(true)
    video_id = find('#id', visible: false).value
    select 'MP4', from: 'video_format'
    click_button 'Start conversion'
    wait_to_download(video_id)
    video = Video.find_by_ytid(video_id)
    video = elapse_sleep_time(video)
    converted_video = video.converted_videos.where('format = ?', 'mp4').last
    converted_video, record_from = elapse_sleep_time(converted_video, video, 'mp4')
    visit dispatch_download_file_path(converted_video_id: converted_video)
    expect(page.response_headers['Content-Type']).to eql 'application/mp4'
    header = page.response_headers['Content-Disposition']
    expect(header).to match /^attachment/
    expect(header).to match /filename=\"#{converted_video.filename}\"$/
  end

  specify 'member with active subscription should able to download the converted video' do
    subscription, member = create_subscription
    sign_in member
    navigate_to_video_page(true)
    video_id = find('#id', visible: false).value
    select 'MP4', from: 'video_format'
    click_button 'Start conversion'
    wait_to_download(video_id)
    video = Video.find_by_ytid(video_id)
    converted_videos = video.converted_videos.where('format = ?', 'mp4').last
    converted_video, record_from = elapse_sleep_time(converted_video, video, 'mp4')
    visit dispatch_download_file_path(converted_video_id: converted_video)
    expect(page.response_headers['Content-Type']).to eql 'application/mp4'
    header = page.response_headers['Content-Disposition']
    expect(header).to match /^attachment/
    expect(header).to match /filename=\"#{converted_video.filename}\"$/
  end

  specify 'member without active subscription should able to view downloaded video file on download history page', js: true do
    login_as_member
    navigate_to_video_page(true)
    video_id = find('#id', visible: false).value
    select 'MP4', from: 'video_format'
    click_button 'Start conversion'
    wait_to_download(video_id)
    video = Video.find_by_ytid(video_id)
    video = elapse_sleep_time(video)
    converted_video = video.converted_videos.where('format = ?', 'mp4').last
    converted_video, record_from = elapse_sleep_time(converted_video, video, 'mp4')
    find('#download-file-button').click
    sleep(1)
    visit download_history_path
    expect(page).to have_content video.title
    expect(page).to have_content converted_video.format.upcase
  end

  specify 'member active subscription should able to view downloaded video file on download history page', js: true do
    subscription, member = create_subscription
    sign_in member
    navigate_to_video_page(true)
    video_id = find('#id', visible: false).value
    select 'MP4', from: 'video_format'
    click_button 'Start conversion'
    wait_to_download(video_id)
    video = Video.find_by_ytid(video_id)
    video = elapse_sleep_time(video)
    converted_video = video.converted_videos.where('format = ?', 'mp4').last
    converted_video, record_from = elapse_sleep_time(converted_video, video, 'mp4')
    find('#download-file-button').click
    sleep(1)
    visit download_history_path
    expect(page).to have_content video.title
    expect(page).to have_content converted_video.format.upcase
  end

  specify 'member without active subscription should able to download video file from download history page', js: true do
    member = create_member
    sign_in member
    navigate_to_video_page(true)
    video_id = find('#id', visible: false).value
    select 'MP4', from: 'video_format'
    click_button 'Start conversion'
    wait_to_download(video_id)
    video = Video.find_by_ytid(video_id)
    video = elapse_sleep_time(video)
    converted_video = video.converted_videos.where('format = ?', 'mp4').last
    converted_video, record_from = elapse_sleep_time(converted_video, video, 'mp4')
    member_download = FactoryBot.create(:member_download, member_id: member.id, converted_video_id: converted_video.id)
    visit download_history_path
    sleep(1)
    click_link 'Download'
    sleep(1)
    expect(MIME::Types.type_for(DownloadHelper.download_path).first.content_type).to eql 'application/mp4'
    expect(File.basename(DownloadHelper.download_path)).to eql converted_video.filename
  end

  specify 'member with active subscription should able to download video file from download history page', js: true do
    subscription, member = create_subscription
    sign_in member
    navigate_to_video_page(true)
    video_id = find('#id', visible: false).value
    select 'MP4', from: 'video_format'
    click_button 'Start conversion'
    wait_to_download(video_id)
    video = Video.find_by_ytid(video_id)
    video = elapse_sleep_time(video)
    converted_video = video.converted_videos.where('format = ?', 'mp4').last
    converted_video, record_from = elapse_sleep_time(converted_video, video, 'mp4')
    member_download = FactoryBot.create(:member_download, member_id: member.id, converted_video_id: converted_video.id)
    visit download_history_path
    sleep(1)
    click_link 'Download'
    sleep(1)
    expect(MIME::Types.type_for(DownloadHelper.download_path).first.content_type).to eql 'application/mp4'
    expect(File.basename(DownloadHelper.download_path)).to eql converted_video.filename
  end
end
