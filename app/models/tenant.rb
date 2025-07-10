class Tenant < ApplicationRecord
  # Associations
  has_many :users, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9]+\z/, message: "only lowercase letters and numbers allowed" }

  # Callbacks
  before_validation :generate_subdomain, on: :create
  after_create :create_default_admin

  # Default settings
  after_initialize do
    self.settings ||= {
      max_users: 3,
      max_documents_per_month: 1000,
      features: [ "basic_extraction" ]
    }
  end

  # Scopes
  scope :active, -> { where("trial_ends_at > ? OR plan != ?", Time.current, "trial") }
  scope :trial, -> { where(plan: "trial") }

  # Instance methods
  def trial?
    plan == "trial" && trial_ends_at.present? && trial_ends_at > Time.current
  end

  def trial_days_remaining
    return 0 unless trial?
    ((trial_ends_at - Time.current) / 1.day).ceil
  end

  def can_add_user?
    users.count < (settings["max_users"] || 3)
  end

  def documents_this_month
    # Will be implemented when we have Document model
    0
  end

  def at_document_limit?
    documents_this_month >= (settings["max_documents_per_month"] || 1000)
  end

  private

  def generate_subdomain
    return if subdomain.present?

    base = name.to_s.parameterize
    self.subdomain = base

    # Ensure uniqueness
    counter = 1
    while Tenant.exists?(subdomain: subdomain)
      self.subdomain = "#{base}#{counter}"
      counter += 1
    end
  end

  def create_default_admin
    # Created by the registration process
  end
end
