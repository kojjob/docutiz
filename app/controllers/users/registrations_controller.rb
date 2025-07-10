class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :authenticate_user!, only: [ :new, :create ]
  skip_before_action :set_current_tenant, only: [ :new, :create ]

  def new
    @tenant = Tenant.new
    super
  end

  def create
    # Build tenant and user together
    @tenant = Tenant.new(tenant_params)

    build_resource(sign_up_params)
    resource.tenant = @tenant
    resource.role = :owner

    ActiveRecord::Base.transaction do
      if @tenant.save && resource.save
        yield resource if block_given?
        if resource.persisted?
          if resource.active_for_authentication?
            set_flash_message! :notice, :signed_up
            sign_up(resource_name, resource)
            redirect_to after_sign_up_path_for(resource), allow_other_host: true
          else
            set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
            expire_data_after_sign_in!
            respond_with resource, location: after_inactive_sign_up_path_for(resource), allow_other_host: true
          end
        else
          clean_up_passwords resource
          set_minimum_password_length
          respond_with resource
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        resource.errors.add(:base, @tenant.errors.full_messages.join(", ")) if @tenant.errors.any?
        respond_with resource
      end
    end
  end

  private

  def tenant_params
    params.require(:tenant).permit(:name, :subdomain)
  end

  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def after_sign_up_path_for(resource)
    root_url(subdomain: resource.tenant.subdomain)
  end

  def after_inactive_sign_up_path_for(resource)
    root_url(subdomain: resource.tenant.subdomain)
  end
end
