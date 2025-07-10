class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable

  # Associations
  belongs_to :tenant

  # Enums
  enum :role, { member: 0, admin: 1, owner: 2 }, default: :member

  # Validations
  validates :email, uniqueness: { scope: :tenant_id }
  validates :name, presence: true
  validates :role, presence: true

  # Callbacks
  # Role default is handled by enum

  # Scopes
  scope :active, -> { where(locked_at: nil) }
  scope :admins, -> { where(role: [ :admin, :owner ]) }

  # Override Devise method to scope by tenant
  def self.find_for_authentication(warden_conditions)
    conditions = warden_conditions.dup
    subdomain = conditions.delete(:subdomain)

    return nil unless subdomain

    tenant = Tenant.find_by(subdomain: subdomain)
    return nil unless tenant

    tenant.users.find_by(email: conditions[:email])
  end

  # Instance methods
  def full_name
    name.presence || email.split("@").first
  end

  def can_manage_users?
    admin? || owner?
  end

  def can_manage_billing?
    owner?
  end

  def can_delete_tenant?
    owner?
  end

  private

  # Private methods can be added here
end
