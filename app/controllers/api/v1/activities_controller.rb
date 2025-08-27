class Api::V1::ActivitiesController < Api::ApplicationController
  # GET /api/v1/activities
  def index
    @activities = current_user.activities.order(created_at: :desc)
    render json: @activities
  end

  # POST /api/v1/activities/mark_as_read
  def mark_as_read
    current_user.activities.where(read_at: nil).update_all(read_at: Time.current)
    render json: { message: "All notifications marked as read." }
  end
end
