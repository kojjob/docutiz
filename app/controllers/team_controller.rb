class TeamController < ApplicationController
  layout 'dashboard'
  
  before_action :authenticate_user!
  before_action :require_admin!, except: [:index, :show, :activity]
  before_action :set_user, only: [:show, :edit, :update, :destroy, :resend_invitation]
  before_action :set_invitation, only: [:cancel_invitation, :resend_invitation]

  def index
    @users = Current.tenant.users.includes(:documents, :created_extraction_results)
    @pending_invitations = Current.tenant.team_invitations.pending.includes(:invited_by)
    @stats = {
      total_members: @users.count,
      owners: @users.owner.count,
      admins: @users.admin.count,
      members: @users.member.count
    }
  end

  def show
    @user_documents = @user.documents.recent.limit(10)
    @user_activities = Activity.where(user: @user).recent.limit(20)
    @user_stats = {
      documents_uploaded: @user.documents.count,
      documents_processed: @user.documents.completed.count,
      comments_made: @user.comments.count,
      member_since: @user.created_at
    }
  end

  def new
    @invitation = Current.tenant.team_invitations.build
  end

  def create
    @invitation = Current.tenant.team_invitations.build(invitation_params)
    @invitation.invited_by = current_user
    
    if @invitation.save
      TeamMailer.invitation(@invitation).deliver_later
      Activity.track(current_user, :user_invited, @invitation, { 
        invitee_email: @invitation.email,
        invitee_name: @invitation.name 
      })
      redirect_to team_index_path, notice: "Invitation sent to #{@invitation.email}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Don't allow password updates through this action
    filtered_params = user_params.except(:password, :password_confirmation)
    old_role = @user.role
    
    if @user.update(filtered_params)
      if old_role != @user.role
        Activity.track(current_user, :user_role_changed, @user, {
          old_role: old_role,
          new_role: @user.role,
          changed_by: current_user.name
        })
      end
      redirect_to team_index_path, notice: "Team member updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to team_index_path, alert: "You cannot remove yourself from the team."
      return
    end
    
    if @user.owner? && Current.tenant.users.owner.count == 1
      redirect_to team_index_path, alert: "Cannot remove the last owner. Please assign another owner first."
      return
    end
    
    user_name = @user.name
    @user.destroy
    Activity.track(current_user, :user_removed, Current.tenant, {
      removed_user: user_name,
      removed_by: current_user.name
    })
    redirect_to team_index_path, notice: "Team member removed successfully."
  end

  def activity
    @activities = Current.tenant.activities
                         .includes(:user, :trackable)
                         .recent
                         .page(params[:page])
    
    @activities = @activities.where(user_id: params[:user_id]) if params[:user_id].present?
    @activities = @activities.where(action: params[:action]) if params[:action].present?
    
    respond_to do |format|
      format.html
      format.json { render json: @activities }
    end
  end

  def cancel_invitation
    @invitation.destroy
    redirect_to team_index_path, notice: "Invitation cancelled."
  end

  def resend_invitation
    if @invitation.resend!
      redirect_to team_index_path, notice: "Invitation resent to #{@invitation.email}"
    else
      redirect_to team_index_path, alert: "Failed to resend invitation."
    end
  end

  # Accept invitation (usually accessed via email link)
  def accept_invitation
    @invitation = TeamInvitation.find_by!(token: params[:token])
    
    if @invitation.expired?
      redirect_to new_user_session_path, alert: "This invitation has expired."
    elsif @invitation.accepted?
      redirect_to new_user_session_path, alert: "This invitation has already been accepted."
    else
      # Store invitation in session and redirect to sign up
      session[:invitation_token] = @invitation.token
      redirect_to new_user_registration_path(invitation_token: @invitation.token)
    end
  end

  private

  def set_user
    @user = Current.tenant.users.find(params[:id])
  end

  def set_invitation
    @invitation = Current.tenant.team_invitations.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :role)
  end

  def invitation_params
    params.require(:team_invitation).permit(:email, :name, :role)
  end

  def require_admin!
    unless current_user.can_manage_users?
      redirect_to team_index_path, alert: "You don't have permission to perform this action."
    end
  end
end