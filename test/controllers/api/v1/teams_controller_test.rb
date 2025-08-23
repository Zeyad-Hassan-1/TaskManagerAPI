require "test_helper"

module Api
  module V1
    class TeamsControllerTest < ActionDispatch::IntegrationTest
      include Devise::Test::IntegrationHelpers

      setup do
        @user = users(:one)
        @team = teams(:one)
        @team_membership = team_memberships(:one)

        # Create test users with different roles
        @member_user = users(:two)
        @admin_user = users(:three)
        @owner_user = users(:four)

        # Set up team memberships
        @team.team_memberships.create!(user: @member_user, role: :member)
        @team.team_memberships.create!(user: @admin_user, role: :admin)
        @team.team_memberships.create!(user: @owner_user, role: :owner)
      end

      test "should get index" do
        sign_in @user
        get api_v1_teams_url
        assert_response :success
      end

      test "should create team" do
        sign_in @user
        assert_difference("Team.count") do
          post api_v1_teams_url, params: { team: { name: "New Team", discription: "Test team" } }
        end
        assert_response :created
      end

      test "should invite member to team" do
        sign_in @admin_user
        assert_difference("TeamMembership.count") do
          post invite_member_api_v1_team_url(@team), params: { username: "newuser", role: "member" }
        end
        assert_response :created
      end

      test "member cannot invite others" do
        sign_in @member_user
        assert_no_difference("TeamMembership.count") do
          post invite_member_api_v1_team_url(@team), params: { username: "newuser", role: "member" }
        end
        assert_response :forbidden
      end

      test "should promote member to admin" do
        sign_in @owner_user
        put promote_member_api_v1_team_url(@team, @member_user)
        assert_response :success
        @member_user.team_memberships.find_by(team: @team).admin?
      end

      test "admin cannot promote members" do
        sign_in @admin_user
        put promote_member_api_v1_team_url(@team, @member_user)
        assert_response :forbidden
      end

      test "should demote admin to member" do
        sign_in @owner_user
        put demote_member_api_v1_team_url(@team, @admin_user)
        assert_response :success
        @admin_user.team_memberships.find_by(team: @team).member?
      end

      test "should remove member" do
        sign_in @owner_user
        assert_difference("TeamMembership.count", -1) do
          delete remove_member_api_v1_team_url(@team, @member_user)
        end
        assert_response :success
      end

      test "admin cannot remove members" do
        sign_in @admin_user
        assert_no_difference("TeamMembership.count") do
          delete remove_member_api_v1_team_url(@team, @member_user)
        end
        assert_response :forbidden
      end

      test "should delete team" do
        sign_in @owner_user
        assert_difference("Team.count", -1) do
          delete api_v1_team_url(@team)
        end
        assert_response :success
      end

      test "admin cannot delete team" do
        sign_in @admin_user
        assert_no_difference("Team.count") do
          delete api_v1_team_url(@team)
        end
        assert_response :forbidden
      end
    end
  end
end
