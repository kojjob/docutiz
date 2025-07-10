class Current < ActiveSupport::CurrentAttributes
  attribute :tenant, :user

  def tenant=(tenant)
    super
    # Set database connection if using separate databases per tenant
    # ActiveRecord::Base.connected_to(shard: tenant.shard_name.to_sym) if tenant
  end

  def tenant_id
    tenant&.id
  end

  def user_id
    user&.id
  end
end
