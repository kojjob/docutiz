class DashboardController < ApplicationController
  layout 'dashboard'
  before_action :require_tenant!

  def index
    @tenant = Current.tenant
    @user = current_user

    # Stats for dashboard
    @stats = {
      documents_count: @tenant.documents.count,
      templates_count: @tenant.extraction_templates.count,
      users_count: @tenant.users.count,
      documents_this_month: @tenant.documents.where(created_at: Time.current.beginning_of_month..).count
    }
  end
  
  def test_theme
    # Test page for theme toggle
  end
end
