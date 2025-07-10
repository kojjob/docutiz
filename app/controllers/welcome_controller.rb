class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    if user_signed_in? && current_user.tenant
      redirect_to dashboard_url(subdomain: current_user.tenant.subdomain)
    end
  end

  def pricing
  end

  def features
  end

  def about
  end
end
