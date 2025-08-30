module Authorizable
  extend ActiveSupport::Concern

  included do
    private

    # Check if user has at least member role in team
    def member_of_team?(team)
      membership = team.team_memberships.find_by(user: current_user)
      membership.present?
    end

    # Check if a specific user has at least member role in team
    def member_of_team_for_user?(team, user)
      membership = team.team_memberships.find_by(user: user)
      membership.present?
    end

    # Check if user has at least admin role in team
    def admin_of_team?(team)
      membership = team.team_memberships.find_by(user: current_user)
      membership&.admin? || membership&.owner? || false
    end

    # Check if user has owner role in team
    def owner_of_team?(team)
      membership = team.team_memberships.find_by(user: current_user)
      membership&.owner? || false
    end

    # Check if user has at least member role in project
    def member_of_project?(project)
      membership = project.project_memberships.find_by(user: current_user)
      membership.present?
    end

    # Check if a specific user has at least member role in project
    def member_of_project_for_user?(project, user)
      membership = project.project_memberships.find_by(user: user)
      membership.present?
    end

    # Check if user has at least admin role in project
    def admin_of_project?(project)
      membership = project.project_memberships.find_by(user: current_user)
      membership&.admin? || membership&.owner? || false
    end

    # Check if user has owner role in project
    def owner_of_project?(project)
      membership = project.project_memberships.find_by(user: current_user)
      membership&.owner? || false
    end

    # Check if user can manage tasks in project
    def can_manage_tasks_in_project?(project)
      admin_of_project?(project)
    end

    # Check if user can assign tasks
    def can_assign_tasks?(project)
      admin_of_project?(project)
    end

    # Check if user can invite members to team
    def can_invite_to_team?(team)
      admin_of_team?(team)
    end

    # Check if user can invite members to project
    def can_invite_to_project?(project)
      admin_of_project?(project)
    end

    # Check if user can manage team members (promote/demote/fire)
    def can_manage_team_members?(team)
      owner_of_team?(team)
    end

    # Check if user can manage project members (promote/demote/fire)
    def can_manage_project_members?(project)
      owner_of_project?(project)
    end

    # Check if user can delete team
    def can_delete_team?(team)
      owner_of_team?(team)
    end

    # Check if user can delete project
    def can_delete_project?(project)
      owner_of_project?(project)
    end

    # Check if user can delete task
    def can_delete_task?(task)
      project = task.project
      owner_of_project?(project)
    end

    # Render unauthorized error
    def render_unauthorized(message = "You don't have permission to perform this action")
      render json: { error: message }, status: :forbidden
    end
  end
end
