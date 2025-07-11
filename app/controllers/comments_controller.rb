class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document
  before_action :set_comment, only: [:update, :destroy]

  def create
    @comment = @document.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      # Notify mentioned users
      notify_mentioned_users(@comment)
      
      # Create activity
      Activity.track(current_user, :document_commented, @document, {
        comment_preview: @comment.content.truncate(100)
      })
      
      respond_to do |format|
        format.html { redirect_to @document, notice: 'Comment added successfully.' }
        format.json { render json: @comment, status: :created }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @document, alert: 'Failed to add comment.' }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @comment.user == current_user
      if @comment.edit!(comment_params[:content])
        respond_to do |format|
          format.html { redirect_to @document, notice: 'Comment updated successfully.' }
          format.json { render json: @comment }
          format.turbo_stream
        end
      else
        respond_to do |format|
          format.html { redirect_to @document, alert: 'Failed to update comment.' }
          format.json { render json: @comment.errors, status: :unprocessable_entity }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @document, alert: 'You can only edit your own comments.' }
        format.json { render json: { error: 'Unauthorized' }, status: :forbidden }
      end
    end
  end

  def destroy
    if @comment.user == current_user || current_user.can_manage_users?
      @comment.destroy
      respond_to do |format|
        format.html { redirect_to @document, notice: 'Comment deleted successfully.' }
        format.json { head :no_content }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @document, alert: 'You can only delete your own comments.' }
        format.json { render json: { error: 'Unauthorized' }, status: :forbidden }
      end
    end
  end

  private

  def set_document
    @document = Current.tenant.documents.find(params[:document_id])
  end

  def set_comment
    @comment = @document.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end

  def notify_mentioned_users(comment)
    # Extract @mentions from comment content
    mentions = comment.content.scan(/@(\w+)/).flatten
    
    mentions.each do |username|
      user = Current.tenant.users.find_by("lower(name) = ?", username.downcase)
      next unless user && user != current_user
      
      # Send notification if user has enabled mention notifications
      if user.settings&.dig("notifications", "email_on_mention")
        CommentMailer.mention_notification(user, comment).deliver_later
      end
    end
  end
end