require "test_helper"

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index on root domain" do
    get root_url
    assert_response :success
  end

  test "should get index on www subdomain" do
    get root_url(subdomain: "www")
    assert_response :success
  end

  test "should redirect to dashboard on tenant subdomain" do
    tenant = tenants(:one)
    get root_url(subdomain: tenant.subdomain)
    assert_redirected_to new_user_session_url(subdomain: tenant.subdomain)
  end
end
