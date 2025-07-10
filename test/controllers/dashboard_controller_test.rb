require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:owner_one)
    @tenant = tenants(:one)
  end

  test "should redirect to login when not authenticated" do
    get dashboard_url(subdomain: @tenant.subdomain)
    assert_redirected_to new_user_session_url(subdomain: @tenant.subdomain)
  end

  test "should get index when authenticated" do
    sign_in @user
    get dashboard_url(subdomain: @tenant.subdomain)
    assert_response :success
  end

  test "should show 404 when accessing dashboard without subdomain" do
    sign_in @user
    get "/dashboard"
    assert_response :not_found
  end
end
