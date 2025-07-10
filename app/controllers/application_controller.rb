class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Devise configuration
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_current_tenant
  before_action :authenticate_user!, unless: :devise_controller?

  # Security
  protect_from_forgery with: :exception, prepend: true

  # Ensure default_url_options includes subdomain for proper URL generation
  def default_url_options
    if request.subdomain.present? && request.subdomain != "www"
      { subdomain: request.subdomain }
    else
      {}
    end
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :subdomain ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  def set_current_tenant
    if user_signed_in?
      Current.tenant = current_user.tenant
      Current.user = current_user
    elsif request.subdomain.present? && request.subdomain != "www"
      Current.tenant = Tenant.find_by(subdomain: request.subdomain)
    else
      Current.tenant = nil
    end
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || dashboard_url(subdomain: resource.tenant.subdomain)
  end

  def after_sign_out_path_for(resource_or_scope)
    root_url(subdomain: false)
  end

  def require_tenant!
    redirect_to root_url(subdomain: false), allow_other_host: true unless Current.tenant
  end

  def require_admin!
    redirect_to dashboard_path, alert: "Not authorized" unless current_user&.can_manage_users?
  end

  def require_owner!
    redirect_to dashboard_path, alert: "Not authorized" unless current_user&.owner?
  end
end
