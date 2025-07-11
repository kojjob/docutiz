class SettingsController < ApplicationController
  layout 'dashboard'
  
  before_action :authenticate_user!
  before_action :require_owner!, only: [:billing, :tenant, :update_tenant, :security, :update_security]

  def index
    # Redirect to profile settings by default
    redirect_to profile_settings_path
  end

  def profile
    @user = current_user
  end

  def update_profile
    @user = current_user
    
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end
    
    if @user.update_with_password(profile_params)
      bypass_sign_in(@user) if params[:user][:password].present?
      redirect_to profile_settings_path, notice: "Profile updated successfully."
    else
      render :profile, status: :unprocessable_entity
    end
  end

  def notifications
    @user = current_user
    @notification_settings = @user.settings&.dig("notifications") || default_notification_settings
  end

  def update_notifications
    @user = current_user
    settings = @user.settings || {}
    settings["notifications"] = notification_params
    
    if @user.update(settings: settings)
      redirect_to notifications_settings_path, notice: "Notification preferences updated."
    else
      @notification_settings = notification_params
      render :notifications, status: :unprocessable_entity
    end
  end

  def collaboration
    @user = current_user
    @collaboration_settings = @user.settings&.dig("collaboration") || default_collaboration_settings
  end

  def update_collaboration
    @user = current_user
    settings = @user.settings || {}
    settings["collaboration"] = collaboration_params
    
    if @user.update(settings: settings)
      redirect_to collaboration_settings_path, notice: "Collaboration preferences updated."
    else
      @collaboration_settings = collaboration_params
      render :collaboration, status: :unprocessable_entity
    end
  end

  def api
    @user = current_user
    @api_usage = {
      requests_today: @user.activities.where(action: 'api_request').today.count,
      requests_this_month: @user.activities.where(action: 'api_request').where(created_at: Time.current.beginning_of_month..).count,
      last_used: @user.api_token_last_used_at
    }
  end

  def regenerate_api_token
    token = current_user.regenerate_api_token!
    flash[:api_token] = token # Store temporarily in flash for one-time display
    Activity.track(current_user, :settings_updated, current_user, { setting: "api_token_regenerated" })
    redirect_to api_settings_path, notice: "API token regenerated successfully. Make sure to save it - it will not be shown again."
  end

  def tenant
    @tenant = Current.tenant
    @tenant_stats = {
      total_users: @tenant.users.count,
      total_documents: @tenant.documents.count,
      total_templates: @tenant.extraction_templates.count,
      storage_used: calculate_storage_used
    }
  end

  def update_tenant
    @tenant = Current.tenant
    
    if @tenant.update(tenant_params)
      Activity.track(current_user, :settings_updated, @tenant, { 
        setting: "tenant_info",
        changes: tenant_params.keys 
      })
      redirect_to tenant_settings_path, notice: "Organization settings updated successfully."
    else
      render :tenant, status: :unprocessable_entity
    end
  end

  def billing
    @tenant = Current.tenant
    @subscription = {
      plan: @tenant.plan,
      trial_ends_at: @tenant.trial_ends_at,
      documents_used: @tenant.documents.where(created_at: Time.current.beginning_of_month..).count,
      documents_limit: @tenant.settings["max_documents_per_month"]
    }
  end

  def integrations
    @integrations = {
      slack: current_user.settings&.dig("integrations", "slack") || {},
      zapier: current_user.settings&.dig("integrations", "zapier") || {},
      webhook: current_user.settings&.dig("integrations", "webhook") || {}
    }
  end

  def update_integrations
    settings = current_user.settings || {}
    settings["integrations"] = integration_params
    
    if current_user.update(settings: settings)
      Activity.track(current_user, :settings_updated, current_user, { 
        setting: "integrations",
        integrations: integration_params.keys 
      })
      redirect_to integrations_settings_path, notice: "Integrations updated successfully."
    else
      render :integrations, status: :unprocessable_entity
    end
  end

  def security
    @tenant = Current.tenant
    @security_settings = @tenant.settings&.dig("security") || default_security_settings
    @recent_activities = Activity.where(tenant: @tenant)
                                .where(action: ['user_login', 'user_logout', 'password_changed', 'api_token_regenerated'])
                                .recent
                                .limit(20)
  end

  def update_security
    @tenant = Current.tenant
    settings = @tenant.settings || {}
    settings["security"] = security_params
    
    if @tenant.update(settings: settings)
      Activity.track(current_user, :settings_updated, @tenant, { 
        setting: "security",
        changes: security_params.keys 
      })
      redirect_to security_settings_path, notice: "Security settings updated successfully."
    else
      @security_settings = security_params
      render :security, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :current_password)
  end

  def notification_params
    params.require(:notifications).permit(
      :email_on_extraction_complete,
      :email_on_extraction_failed,
      :email_on_review_required,
      :email_on_comment,
      :email_on_mention,
      :email_weekly_summary,
      :browser_notifications
    ).to_h
  end

  def collaboration_params
    params.require(:collaboration).permit(
      :show_activity_feed,
      :allow_comments,
      :notify_on_comments,
      :notify_on_document_changes,
      :default_document_visibility
    ).to_h
  end

  def tenant_params
    params.require(:tenant).permit(:name)
  end

  def integration_params
    params.permit(
      slack: [:enabled, :webhook_url, :channel],
      zapier: [:enabled, :api_key],
      webhook: [:enabled, :url, :secret]
    ).to_h
  end

  def security_params
    params.require(:security).permit(
      :require_2fa,
      :session_timeout,
      :ip_whitelist,
      :password_expiry_days
    ).to_h
  end

  def require_owner!
    unless current_user.owner?
      redirect_to settings_path, alert: "You don't have permission to access this section."
    end
  end

  def default_notification_settings
    {
      "email_on_extraction_complete" => true,
      "email_on_extraction_failed" => true,
      "email_on_review_required" => true,
      "email_on_comment" => true,
      "email_on_mention" => true,
      "email_weekly_summary" => false,
      "browser_notifications" => true
    }
  end

  def default_collaboration_settings
    {
      "show_activity_feed" => true,
      "allow_comments" => true,
      "notify_on_comments" => true,
      "notify_on_document_changes" => true,
      "default_document_visibility" => "team"
    }
  end

  def default_security_settings
    {
      "require_2fa" => false,
      "session_timeout" => 720, # 12 hours in minutes
      "ip_whitelist" => "",
      "password_expiry_days" => 0 # 0 means no expiry
    }
  end

  def calculate_storage_used
    # Calculate total storage used by all documents
    @tenant.documents.sum(:file_size)
  end
end