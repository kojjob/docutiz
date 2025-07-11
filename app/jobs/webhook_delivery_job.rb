class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks

  retry_on Net::ReadTimeout, Net::OpenTimeout, wait: :exponentially_longer, attempts: 3
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(webhook, event_type, payload, webhook_event_id = nil)
    # Create or find the webhook event record
    webhook_event = if webhook_event_id
      WebhookEvent.find(webhook_event_id)
    else
      webhook.webhook_events.create!(
        event_type: event_type,
        payload: payload,
        status: 'pending'
      )
    end

    # Deliver the webhook
    webhook_event.deliver!

    # Log the delivery
    Rails.logger.info "Webhook delivered: #{webhook.name} - #{event_type} - Status: #{webhook_event.status}"
    
    # Track activity
    Activity.track(
      webhook.user,
      :webhook_delivered,
      webhook,
      {
        event_type: event_type,
        status: webhook_event.status,
        response_code: webhook_event.response_code,
        url: webhook.redacted_url
      }
    )
  rescue => e
    Rails.logger.error "Webhook delivery failed: #{webhook.name} - #{event_type} - Error: #{e.message}"
    raise # Re-raise to trigger retry
  end
end