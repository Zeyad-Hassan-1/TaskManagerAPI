require 'rails_helper'

RSpec.describe Api::V1::ActivitiesController, type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'GET #index' do
    context 'when user has activities' do
      let!(:activity1) { create(:activity, user: user, action: 'invited', created_at: 2.hours.ago) }
      let!(:activity2) { create(:activity, user: user, action: 'joined', created_at: 1.hour.ago) }
      let!(:other_activity) { create(:activity, user: other_user, action: 'invited') }

      it 'returns user activities ordered by creation date descending' do
        get '/api/v1/activities', headers: auth_headers_for(user)

        expect(response).to have_http_status(:success)
        activities = json_response['data']
        expect(activities.length).to eq(2)
        expect(activities.first['id']).to eq(activity2.id)
        expect(activities.second['id']).to eq(activity1.id)
      end

      it 'does not return other users activities' do
        get '/api/v1/activities', headers: auth_headers_for(user)

        activities = json_response['data']
        activity_ids = activities.map { |a| a['id'] }
        expect(activity_ids).not_to include(other_activity.id)
      end
    end

    context 'when user has no activities' do
      it 'returns empty array' do
        get '/api/v1/activities', headers: auth_headers_for(user)

        expect(response).to have_http_status(:success)
        expect(json_response['data']).to eq([])
      end
    end
  end

  describe 'PUT #mark_all_read' do
    context 'when user has unread activities' do
      let!(:unread_activity1) { create(:activity, user: user, read_at: nil) }
      let!(:unread_activity2) { create(:activity, user: user, read_at: nil) }
      let!(:read_activity) { create(:activity, :read, user: user) }
      let!(:other_unread_activity) { create(:activity, user: other_user, read_at: nil) }

      it 'marks all user unread activities as read' do
        put '/api/v1/activities/mark_all_read', headers: auth_headers_for(user)

        expect(response).to have_http_status(:success)
        expect(json_response['message']).to eq('All activities marked as read.')

        unread_activity1.reload
        unread_activity2.reload
        read_activity.reload
        other_unread_activity.reload

        expect(unread_activity1.read_at).not_to be_nil
        expect(unread_activity2.read_at).not_to be_nil
        expect(read_activity.read_at).not_to be_nil # already read
        expect(other_unread_activity.read_at).to be_nil # other user's activity unchanged
      end
    end

    context 'when user has no unread activities' do
      let!(:read_activity) { create(:activity, :read, user: user) }

      it 'still returns success message' do
        put '/api/v1/activities/mark_all_read', headers: auth_headers_for(user)

        expect(response).to have_http_status(:success)
        expect(json_response['message']).to eq('All activities marked as read.')
      end
    end

    context 'when user has no activities' do
      it 'returns success message' do
        put '/api/v1/activities/mark_all_read', headers: auth_headers_for(user)

        expect(response).to have_http_status(:success)
        expect(json_response['message']).to eq('All activities marked as read.')
      end
    end
  end
end
