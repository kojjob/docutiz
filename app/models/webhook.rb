class Webhook < ApplicationRecord
  belongs_to :tenant
  belongs_to :user
  has_many :webhook_events, dependent: :destroy

  AVAILABLE_EVENTS = %w[
    document.created
    document.processed
    document.approved
    document.rejected
    extraction.completed
    extraction.failed
    extraction.reviewed
    template.created
    template.updated
    user.invited
    user.joined
  ].freeze

  validates :name, presence: true
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :events, presence: true
  validate :events_are_valid
  validates :retry_count, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }
  validates :timeout_seconds, numericality: { greater_than_or_equal_to: 5, less_than_or_equal_to: 300 }

  scope :active, -> { where(active: true) }
  scope :for_event, ->(event) { active.where("? = ANY(events)", event) }

  before_create :generate_secret_key

  def trigger(event, payload)
    return unless should_trigger?(event)

    WebhookDeliveryJob.perform_later(self, event, payload)
    touch(:last_triggered_at)
  end

  def increment_delivery_count!(success:)
    if success
      increment!(:successful_deliveries)
    else
      increment!(:failed_deliveries)
    end
    increment!(:total_deliveries)
  end

  def success_rate
    return 0.0 if total_deliveries.zero?
    (successful_deliveries.to_f / total_deliveries * 100).round(2)
  end

  def sign_payload(payload)
    OpenSSL::HMAC.hexdigest("SHA256", secret_key, payload.to_json)
  end

  def verify_signature(payload, signature)
    expected_signature = sign_payload(payload)
    ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
  end

  def redacted_url
    uri = URI.parse(url)
    "#{uri.scheme}://#{uri.host}#{uri.path}"
  rescue URI::InvalidURIError
    url
  end

  private

  def should_trigger?(event)
    active? && events.include?(event.to_s)
  end

  def generate_secret_key
    self.secret_key ||= SecureRandom.hex(32)
  end

  def events_are_valid
    invalid_events = events - AVAILABLE_EVENTS
    if invalid_events.any?
      errors.add(:events, "contains invalid events: #{invalid_events.join(', ')}")
    end
  end
end