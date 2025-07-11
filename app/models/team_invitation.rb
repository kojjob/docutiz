class TeamInvitation < ApplicationRecord
  belongs_to :tenant
  belongs_to :invited_by, class_name: "User"
  belongs_to :user, optional: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :tenant_id, conditions: -> { pending } }
  validates :role, inclusion: { in: %w[member admin] }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where(accepted_at: nil).where("expires_at <= ?", Time.current) }
  scope :accepted, -> { where.not(accepted_at: nil) }

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create
  after_create_commit :trigger_invited_webhook
  after_update_commit :trigger_joined_webhook, if: :just_accepted?

  def pending?
    accepted_at.nil? && !expired?
  end

  def expired?
    expires_at <= Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def accept!(accepting_user)
    return false if accepted? || expired?
    
    transaction do
      # Update the invitation
      self.user = accepting_user
      self.accepted_at = Time.current
      save!
      
      # Add user to tenant if not already a member
      unless accepting_user.tenant == tenant
        accepting_user.update!(tenant: tenant, role: role)
      end
      
      true
    end
  rescue ActiveRecord::RecordInvalid
    false
  end

  def resend!
    return false if accepted?
    
    self.expires_at = 7.days.from_now
    self.token = generate_token_string
    save! && TeamMailer.invitation(self).deliver_later
  end

  private

  def generate_token
    self.token ||= generate_token_string
  end

  def generate_token_string
    SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at ||= 7.days.from_now
  end

  def just_accepted?
    saved_change_to_accepted_at? && accepted?
  end

  def trigger_invited_webhook
    trigger_webhook("user.invited")
  end

  def trigger_joined_webhook
    trigger_webhook("user.joined")
  end

  def trigger_webhook(event)
    payload = {
      event: event,
      timestamp: Time.current.iso8601,
      invitation: {
        id: id,
        email: email,
        name: name,
        role: role,
        invited_by: {
          id: invited_by.id,
          name: invited_by.name,
          email: invited_by.email
        },
        accepted_at: accepted_at&.iso8601,
        expires_at: expires_at.iso8601
      },
      tenant: {
        id: tenant.id,
        name: tenant.name,
        subdomain: tenant.subdomain
      }
    }

    # Add user info if joined
    if event == "user.joined" && user
      payload[:user] = {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    end

    # Find all active webhooks for this event
    tenant.webhooks.for_event(event).each do |webhook|
      webhook.trigger(event, payload)
    end
  end
end