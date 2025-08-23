# Role-Based Access Control System

## Overview

The Task Manager API implements a comprehensive three-tier role-based access control (RBAC) system that governs permissions for teams, projects, and tasks. Each user can have different roles in different contexts, providing flexible and secure access management.

## Role Hierarchy

### 1. **Member** (role: 0)
- **Lowest privilege level**
- **Can join teams/projects** if invited by admins or owners
- **Can be assigned to tasks** by admins
- **Can view** teams, projects, and tasks they're members of
- **Cannot** create, modify, or delete resources
- **Cannot** invite other users
- **Cannot** manage other members

### 2. **Admin** (role: 1)
- **Medium privilege level**
- **All member permissions** plus:
- **Can create tasks and projects** within teams they're admin of
- **Can assign tasks to members** within their projects
- **Can invite members** to teams and projects (as members or admins)
- **Can update** team and project information
- **Cannot** delete teams, projects, or tasks
- **Cannot** remove members
- **Cannot** promote/demote other members

### 3. **Owner** (role: 2)
- **Highest privilege level**
- **All admin permissions** plus:
- **Can delete** teams, projects, and tasks
- **Can remove members** from teams and projects
- **Can promote members** to admin role
- **Can demote admins** to member role
- **Full administrative control** over their resources

## Implementation Details

### Database Schema

The role system is implemented through three membership models:

```ruby
# Team memberships
class TeamMembership < ApplicationRecord
  belongs_to :user
  belongs_to :team
  enum :role, { member: 0, admin: 1, owner: 2 }
end

# Project memberships  
class ProjectMembership < ApplicationRecord
  belongs_to :user
  belongs_to :project
  enum :role, { member: 0, admin: 1, owner: 2 }
end

# Task memberships
class TaskMembership < ApplicationRecord
  belongs_to :user
  belongs_to :task
  enum :role, { assignee: 0, reviewer: 1, watcher: 2 }
end
```

### Authorization System

The API uses a centralized `Authorizable` concern that provides helper methods for checking permissions:

```ruby
module Authorizable
  # Team permissions
  def member_of_team?(team)
  def admin_of_team?(team)
  def owner_of_team?(team)
  
  # Project permissions
  def member_of_project?(project)
  def admin_of_project?(project)
  def owner_of_project?(project)
  
  # Task permissions
  def can_manage_tasks_in_project?(project)
  def can_assign_tasks?(project)
  
  # Member management permissions
  def can_invite_to_team?(team)
  def can_manage_team_members?(team)
  def can_delete_team?(team)
end
```

## API Endpoints

### Team Management

#### Invite Member
```
POST /api/v1/teams/:id/invite
Body: { "username": "john_doe", "role": "member" }
```
- **Required Role**: Admin or Owner
- **Description**: Invites a user to join the team with specified role

#### Remove Member
```
DELETE /api/v1/teams/:id/members/:user_id
```
- **Required Role**: Owner only
- **Description**: Removes a member from the team (cannot remove owner)

#### Promote Member
```
PUT /api/v1/teams/:id/members/:user_id/promote
```
- **Required Role**: Owner only
- **Description**: Promotes a member to admin role

#### Demote Member
```
PUT /api/v1/teams/:id/members/:user_id/demote
```
- **Required Role**: Owner only
- **Description**: Demotes an admin to member role

### Project Management

#### Invite Member
```
POST /api/v1/projects/:id/invite
Body: { "username": "john_doe", "role": "admin" }
```
- **Required Role**: Admin or Owner
- **Description**: Invites a user to join the project with specified role

#### Remove Member
```
DELETE /api/v1/projects/:id/members/:user_id
```
- **Required Role**: Owner only
- **Description**: Removes a member from the project (cannot remove owner)

#### Promote Member
```
PUT /api/v1/projects/:id/members/:user_id/promote
```
- **Required Role**: Owner only
- **Description**: Promotes a member to admin role

#### Demote Member
```
PUT /api/v1/projects/:id/members/:user_id/demote
```
- **Required Role**: Owner only
- **Description**: Demotes an admin to member role

### Task Management

#### Assign Member
```
POST /api/v1/tasks/:id/assign
Body: { "username": "john_doe", "role": "assignee" }
```
- **Required Role**: Admin or Owner
- **Description**: Assigns a user to a task with specified role
- **Task Roles**: assignee, reviewer, watcher

#### Remove Member
```
DELETE /api/v1/tasks/:id/members/:user_id
```
- **Required Role**: Admin or Owner
- **Description**: Removes a user from a task

## Permission Matrix

| Action | Member | Admin | Owner |
|--------|--------|-------|-------|
| **View Resources** | ✅ | ✅ | ✅ |
| **Create Tasks** | ❌ | ✅ | ✅ |
| **Create Projects** | ❌ | ✅ | ✅ |
| **Assign Tasks** | ❌ | ✅ | ✅ |
| **Invite Members** | ❌ | ✅ | ✅ |
| **Update Resources** | ❌ | ✅ | ✅ |
| **Delete Resources** | ❌ | ❌ | ✅ |
| **Remove Members** | ❌ | ❌ | ✅ |
| **Promote/Demote** | ❌ | ❌ | ✅ |

## Security Features

### 1. **Role Inheritance**
- Admins inherit all member permissions
- Owners inherit all admin permissions

### 2. **Contextual Permissions**
- Users can have different roles in different teams/projects
- Permissions are checked at the resource level

### 3. **Action Validation**
- All destructive actions require owner role
- Member management requires appropriate role level
- Invitations can only be sent by admins or owners

### 4. **Data Isolation**
- Users can only access resources they're members of
- Role checks are performed before any data access

## Usage Examples

### Creating a Team and Inviting Members

```ruby
# 1. Create team (automatically becomes owner)
POST /api/v1/teams
Body: { "team": { "name": "Development Team", "discription": "Software development team" } }

# 2. Invite admin
POST /api/v1/teams/1/invite
Body: { "username": "tech_lead", "role": "admin" }

# 3. Invite member
POST /api/v1/teams/1/invite
Body: { "username": "developer", "role": "member" }
```

### Managing Project Members

```ruby
# 1. Create project (requires admin/owner role in team)
POST /api/v1/teams/1/projects
Body: { "project": { "name": "Web App", "discription": "Main web application" } }

# 2. Invite project member
POST /api/v1/projects/1/invite
Body: { "username": "designer", "role": "member" }

# 3. Promote to admin
PUT /api/v1/projects/1/members/3/promote
```

### Task Assignment

```ruby
# 1. Create task (requires admin/owner role in project)
POST /api/v1/projects/1/tasks

# 2. Assign member to task
POST /api/v1/tasks/1/assign
Body: { "username": "developer", "role": "assignee" }

# 3. Add reviewer
POST /api/v1/tasks/1/assign
Body: { "username": "tech_lead", "role": "reviewer" }
```

## Best Practices

### 1. **Role Assignment**
- Start users with member role and promote as needed
- Use admin role for team leads and project managers
- Reserve owner role for resource creators

### 2. **Security**
- Regularly review member roles and permissions
- Remove inactive members promptly
- Use the principle of least privilege

### 3. **Team Structure**
- Keep teams focused and manageable in size
- Use projects to organize work within teams
- Assign clear responsibilities through roles

## Error Handling

The API returns appropriate HTTP status codes and error messages:

- **403 Forbidden**: User lacks required permissions
- **404 Not Found**: Resource or user not found
- **422 Unprocessable Entity**: Invalid role or action
- **400 Bad Request**: Missing or invalid parameters

All error responses include descriptive messages explaining what went wrong and what permissions are required.
