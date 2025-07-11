class ApiKeysController < ApplicationController
  layout 'dashboard'
  before_action :authenticate_user!
  
  def show
    @user = current_user
  end
  
  def regenerate
    @new_token = current_user.regenerate_api_token!
    flash[:api_token] = @new_token # Store temporarily in flash for one-time display
    redirect_to api_key_path, notice: 'API key regenerated successfully. Make sure to save it - it will not be shown again.'
  end
end