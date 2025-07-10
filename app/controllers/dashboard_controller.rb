class DashboardController < ApplicationController
  before_action :require_tenant!

  def index
    @tenant = Current.tenant
    @user = current_user

    # Stats for dashboard (will be populated later)
    @stats = {
      documents_count: 0, # @tenant.documents.count
      templates_count: 0, # @tenant.templates.count
      users_count: @tenant.users.count,
      documents_this_month: 0 # @tenant.documents_this_month
    }
  end
end
