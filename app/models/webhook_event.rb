class WebhookEvent < ApplicationRecord
  belongs_to :webhook

  STATUSES = %w[pending delivering delivered failed].freeze

  validates :event_type, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :payload, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :pending, -> { where(status: 'pending') }
  scope :failed, -> { where(status: 'failed') }
  scope :delivered, -> { where(status: 'delivered') }
  scope :retryable, -> { failed.where("attempt_count < ?", 3).where("next_retry_at <= ?", Time.current) }

  def deliver!
    return false unless can_deliver?

    update!(status: 'delivering', attempt_count: attempt_count + 1)
    
    begin
      response = deliver_webhook
      handle_success(response)
      true
    rescue => e
      handle_failure(e)
      false
    end
  end

  def can_deliver?
    status.in?(%w[pending failed]) && attempt_count < webhook.retry_count
  end

  def should_retry?
    status == 'failed' && attempt_count < webhook.retry_count
  end

  def schedule_retry!
    return unless should_retry?

    delay = retry_delay_seconds
    update!(
      next_retry_at: Time.current + delay.seconds,
      status: 'pending'
    )
    
    WebhookDeliveryJob.set(wait: delay.seconds).perform_later(webhook, event_type, payload, id)
  end

  def success?
    status == 'delivered'
  end

  def failed?
    status == 'failed'
  end

  private

  def deliver_webhook
    uri = URI.parse(webhook.url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.read_timeout = webhook.timeout_seconds
    http.open_timeout = webhook.timeout_seconds

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    request['X-Webhook-Event'] = event_type
    request['X-Webhook-Signature'] = webhook.sign_payload(payload)
    request['X-Webhook-Timestamp'] = Time.current.to_i.to_s
    request['X-Webhook-ID'] = id.to_s

    # Add custom headers
    webhook.headers.each do |key, value|
      request[key] = value
    end

    request.body = payload.to_json

    start_time = Time.current
    response = http.request(request)
    response_time = Time.current - start_time

    {
      code: response.code.to_i,
      headers: response.each_header.to_h,
      body: response.body,
      time: response_time
    }
  end

  def handle_success(response)
    update!(
      status: 'delivered',
      delivered_at: Time.current,
      response_code: response[:code],
      response_headers: response[:headers],
      response_body: truncate_response_body(response[:body]),
      response_time: response[:time],
      error_message: nil
    )
    
    webhook.increment_delivery_count!(success: true)
  end

  def handle_failure(error)
    update!(
      status: 'failed',
      error_message: error.message,
      response_code: error.respond_to?(:response_code) ? error.response_code : nil
    )
    
    webhook.increment_delivery_count!(success: false)
    schedule_retry! if should_retry?
  end

  def retry_delay_seconds
    # Exponential backoff: 30s, 60s, 120s
    base_delay = 30
    base_delay * (2 ** (attempt_count - 1))
  end

  def truncate_response_body(body)
    return nil if body.blank?
    # Limit response body to 10KB to avoid bloating the database
    body.truncate(10_240)
  end
end