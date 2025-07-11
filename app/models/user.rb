class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable

  # Associations
  belongs_to :tenant
  has_many :documents, dependent: :nullify
  has_many :created_extraction_results, class_name: "ExtractionResult", foreign_key: "created_by_id"
  has_many :comments, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :sent_invitations, class_name: "TeamInvitation", foreign_key: "invited_by_id"

  # Enums
  enum :role, { member: 0, admin: 1, owner: 2 }, default: :member

  # Validations
  validates :email, uniqueness: { scope: :tenant_id }
  validates :name, presence: true
  validates :role, presence: true

  # Callbacks
  # Role default is handled by enum
  before_create :set_initial_api_token

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
  
  # API Token Management
  attr_accessor :plain_api_token
  
  def regenerate_api_token!
    token = generate_api_token
    self.plain_api_token = token
    self.api_token_digest = Digest::SHA256.hexdigest(token)
    save!
    token # Return the plain token for display to user
  end
  
  def record_api_request!
    update_columns(
      api_token_last_used_at: Time.current,
      api_requests_count: api_requests_count + 1
    )
  end
  
  # Find user by API token
  def self.find_by_api_token(token)
    return nil unless token.present?
    digest = Digest::SHA256.hexdigest(token)
    find_by(api_token_digest: digest)
  end

  private

  def generate_api_token
    loop do
      token = "doc_#{SecureRandom.hex(24)}"
      digest = Digest::SHA256.hexdigest(token)
      break token unless User.exists?(api_token_digest: digest)
    end
  end
  
  def set_initial_api_token
    token = generate_api_token
    self.plain_api_token = token
    self.api_token_digest = Digest::SHA256.hexdigest(token)
  end
end
