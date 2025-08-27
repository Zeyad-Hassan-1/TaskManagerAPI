class Api::V1::ActivitiesController < Api::ApplicationController
  # GET /api/v1/activities
  def index
    @activities = current_user.activities.order(created_at: :desc)
    render json: @activities
  rescue StandardError => e
    Rails.logger.error("Error fetching activities for user #{current_user.id}: #{e.message}")
    render_error("An error occurred while fetching activities", :internal_server_error)
  end

  # POST /api/v1/activities/mark_as_read
  def mark_as_read
    current_user.activities.where(read_at: nil).update_all(read_at: Time.current)
    render json: { message: "All notifications marked as read." }
  rescue StandardError => e
    Rails.logger.error("Error marking activities as read for user #{current_user.id}: #{e.message}")
    render_error("An error occurred while marking notifications as read", :internal_server_error)
  end
end
