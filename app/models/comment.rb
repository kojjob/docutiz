class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true

  validates :content, presence: true, length: { maximum: 1000 }

  scope :recent, -> { order(created_at: :desc) }

  after_create :create_activity

  def edited?
    edited_at.present?
  end

  def edit!(new_content)
    update!(content: new_content, edited_at: Time.current)
  end

  private

  def create_activity
    Activity.create!(
      tenant: user.tenant,
      user: user,
      action: "commented",
      trackable: commentable,
      metadata: {
        comment_id: id,
        comment_preview: content.truncate(100)
      }
    )
  end
end