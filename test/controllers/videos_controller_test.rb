require 'test_helper'

class VideosControllerTest < ActionDispatch::IntegrationTest
  test "should get search" do
    get videos_search_url
    assert_response :success
  end

end
