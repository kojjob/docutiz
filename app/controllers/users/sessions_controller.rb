class Users::SessionsController < Devise::SessionsController
  skip_before_action :authenticate_user!, only: [ :new, :create ]
  before_action :ensure_subdomain_for_login, only: [ :new ]

  def create
    if request.subdomain.present? && request.subdomain != "www"
      # Tenant-specific login
      self.resource = warden.authenticate!(auth_options.merge(subdomain: request.subdomain))
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource), allow_other_host: true
    else
      # Redirect to tenant subdomain for login
      flash[:alert] = "Please use your organization's subdomain to sign in."
      redirect_to root_url, allow_other_host: true
    end
  end

  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    yield if block_given?
    respond_to_on_destroy
  end

  private

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || dashboard_url(subdomain: resource.tenant.subdomain)
  end

  def after_sign_out_path_for(resource_or_scope)
    root_url(subdomain: false)
  end

  def ensure_subdomain_for_login
    # If user is trying to login from root domain but provides a subdomain param,
    # redirect them to the subdomain login page
    if params[:subdomain].present? && (request.subdomain.blank? || request.subdomain == "www")
      redirect_to new_user_session_url(subdomain: params[:subdomain]), allow_other_host: true
    end
  end

  def respond_to_on_destroy
    # We actually need to redirect here instead of just calling respond_to.
    respond_to do |format|
      format.all { redirect_to after_sign_out_path_for(resource_name), allow_other_host: true }
      format.turbo_stream { redirect_to after_sign_out_path_for(resource_name), allow_other_host: true }
    end
  end
end
