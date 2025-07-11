class WebhooksController < ApplicationController
  layout 'dashboard'
  
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_webhook, only: [:show, :edit, :update, :destroy, :test, :events]

  def index
    @webhooks = Current.tenant.webhooks.includes(:user).order(created_at: :desc)
  end

  def show
    @recent_events = @webhook.webhook_events.recent.limit(20)
    @stats = {
      total_events: @webhook.webhook_events.count,
      delivered: @webhook.webhook_events.delivered.count,
      failed: @webhook.webhook_events.failed.count,
      pending: @webhook.webhook_events.pending.count,
      success_rate: @webhook.success_rate
    }
  end

  def new
    @webhook = Current.tenant.webhooks.build
  end

  def create
    @webhook = Current.tenant.webhooks.build(webhook_params)
    @webhook.user = current_user

    if @webhook.save
      Activity.track(current_user, :webhook_created, @webhook, { 
        name: @webhook.name,
        url: @webhook.redacted_url 
      })
      redirect_to webhooks_path, notice: "Webhook created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @webhook.update(webhook_params)
      Activity.track(current_user, :webhook_updated, @webhook, { 
        name: @webhook.name,
        changes: @webhook.previous_changes.keys 
      })
      redirect_to webhook_path(@webhook), notice: "Webhook updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    webhook_name = @webhook.name
    @webhook.destroy
    Activity.track(current_user, :webhook_deleted, Current.tenant, { 
      webhook_name: webhook_name 
    })
    redirect_to webhooks_path, notice: "Webhook deleted successfully."
  end

  def test
    # Create a test payload
    test_payload = {
      event: "webhook.test",
      timestamp: Time.current.iso8601,
      data: {
        message: "This is a test webhook from Docutiz",
        webhook_id: @webhook.id,
        webhook_name: @webhook.name
      }
    }

    # Trigger the webhook
    @webhook.trigger("webhook.test", test_payload)

    respond_to do |format|
      format.html { redirect_to webhook_path(@webhook), notice: "Test webhook sent. Check the events tab for results." }
      format.json { render json: { status: "sent", message: "Test webhook queued for delivery" } }
    end
  end

  def events
    @events = @webhook.webhook_events.includes(:webhook)
    
    # Apply filters
    @events = @events.where(status: params[:status]) if params[:status].present?
    @events = @events.where(event_type: params[:event_type]) if params[:event_type].present?
    
    # Date range filter
    if params[:date_from].present?
      @events = @events.where("created_at >= ?", Date.parse(params[:date_from]).beginning_of_day)
    end
    if params[:date_to].present?
      @events = @events.where("created_at <= ?", Date.parse(params[:date_to]).end_of_day)
    end
    
    @events = @events.page(params[:page]).per(20)
    
    respond_to do |format|
      format.html
      format.json { render json: @events }
    end
  end

  private

  def set_webhook
    @webhook = Current.tenant.webhooks.find(params[:id])
  end

  def webhook_params
    params.require(:webhook).permit(
      :name, 
      :url, 
      :active,
      :retry_count,
      :timeout_seconds,
      events: [],
      headers: {}
    )
  end

  def require_admin!
    unless current_user.can_manage_users?
      redirect_to dashboard_path, alert: "You don't have permission to manage webhooks."
    end
  end
end