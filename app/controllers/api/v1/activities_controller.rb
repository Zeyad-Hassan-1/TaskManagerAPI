class Api::V1::ActivitiesController < Api::ApplicationController
  # GET /api/v1/activities
  def index
    @activities = current_user.activities.includes(:actor, :notifiable).order(created_at: :desc)

    serialized_activities = @activities.map do |activity|
      {
        id: activity.id,
        action: activity.action,
        read_at: activity.read_at,
        created_at: activity.created_at,
        actor: activity.actor ? { id: activity.actor.id, username: activity.actor.username } : nil,
        notifiable: activity.notifiable ? {
          id: activity.notifiable.id,
          name: if activity.notifiable_type == "Invitation"
                  activity.notifiable.invitable.try(:name) || activity.notifiable.invitable.try(:username) || "Unknown"
                else
                  activity.notifiable.try(:name) || activity.notifiable.try(:username) || "Unknown"
                end,
          type: activity.notifiable_type
        } : nil
      }
    end

    render json: { data: serialized_activities }
  rescue StandardError => e
    Rails.logger.error("Error fetching activities for user #{current_user.id}: #{e.message}")
    render_error("An error occurred while fetching activities", :internal_server_error)
  end

  # PUT /api/v1/activities/:id/read
  def read
    activity = current_user.activities.find(params[:id])
    activity.update(read_at: Time.current)
    render json: { message: "Activity marked as read." }
  rescue ActiveRecord::RecordNotFound
    render_error("Activity not found", :not_found)
  rescue StandardError => e
    Rails.logger.error("Error marking activity as read for user #{current_user.id}: #{e.message}")
    render_error("An error occurred while marking activity as read", :internal_server_error)
  end

  # PUT /api/v1/activities/mark_all_read
  def mark_all_read
    current_user.activities.where(read_at: nil).update_all(read_at: Time.current)
    render json: { message: "All activities marked as read." }
  rescue StandardError => e
    Rails.logger.error("Error marking all activities as read for user #{current_user.id}: #{e.message}")
    render_error("An error occurred while marking activities as read", :internal_server_error)
  end
end
