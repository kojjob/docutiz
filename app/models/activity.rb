class Activity < ApplicationRecord
  belongs_to :tenant
  belongs_to :user
  belongs_to :trackable, polymorphic: true

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where(created_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :this_week, -> { where(created_at: Time.current.beginning_of_week..Time.current.end_of_week) }

  # Common actions
  ACTIONS = {
    # Document actions
    document_uploaded: "uploaded a document",
    document_processed: "processed a document",
    document_approved: "approved a document",
    document_rejected: "rejected a document",
    document_commented: "commented on a document",
    
    # Template actions
    template_created: "created a template",
    template_updated: "updated a template",
    template_deleted: "deleted a template",
    
    # Team actions
    user_invited: "invited a team member",
    user_joined: "joined the team",
    user_removed: "removed from team",
    user_role_changed: "role changed",
    
    # Other actions
    commented: "added a comment",
    settings_updated: "updated settings"
  }.freeze

  def description
    ACTIONS[action.to_sym] || action.humanize.downcase
  end

  def icon
    case action
    when /document/
      "document"
    when /template/
      "template"
    when /user/, /team/
      "users"
    when "commented"
      "chat"
    else
      "activity"
    end
  end

  # Helper method to create activities
  def self.track(user, action, trackable, metadata = {})
    create!(
      tenant: user.tenant,
      user: user,
      action: action.to_s,
      trackable: trackable,
      metadata: metadata
    )
  end
end