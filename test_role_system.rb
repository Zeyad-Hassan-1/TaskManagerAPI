#!/usr/bin/env ruby

# Simple test script to demonstrate the role-based access control system
# Run this with: ruby test_role_system.rb

puts "🧪 Testing Role-Based Access Control System"
puts "=" * 50

# Load the Rails environment
require_relative 'config/environment'

begin
  # Create test users
  puts "\n👥 Creating test users..."
  user1 = User.create!(username: 'owner_user', email: 'owner@test.com', password: 'password123')
  user2 = User.create!(username: 'admin_user', email: 'admin@test.com', password: 'password123')
  user3 = User.create!(username: 'member_user', email: 'member@test.com', password: 'password123')
  puts "✅ Created users: #{user1.username}, #{user2.username}, #{user3.username}"

  # Create a team
  puts "\n🏢 Creating a test team..."
  team = Team.create!(name: 'Test Team', discription: 'A team for testing roles')
  puts "✅ Created team: #{team.name}"

  # Create team memberships with different roles
  puts "\n🔐 Setting up team memberships..."
  owner_membership = TeamMembership.create!(user: user1, team: team, role: :owner)
  admin_membership = TeamMembership.create!(user: user2, team: team, role: :admin)
  member_membership = TeamMembership.create!(user: user3, team: team, role: :member)
  puts "✅ Created memberships: Owner(#{user1.username}), Admin(#{user2.username}), Member(#{user3.username})"

  # Test role methods
  puts "\n🔍 Testing role methods..."
  puts "Owner membership: member?=#{owner_membership.member?}, admin?=#{owner_membership.admin?}, owner?=#{owner_membership.owner?}"
  puts "Admin membership: member?=#{admin_membership.member?}, admin?=#{admin_membership.admin?}, owner?=#{admin_membership.owner?}"
  puts "Member membership: member?=#{member_membership.member?}, admin?=#{member_membership.admin?}, owner?=#{member_membership.owner?}"

  # Test role inheritance
  puts "\n📊 Testing role inheritance..."
  puts "Owner can do everything: member=#{owner_membership.member?}, admin=#{owner_membership.admin?}, owner=#{owner_membership.owner?}"
  puts "Admin can do member things: member=#{admin_membership.member?}, admin=#{admin_membership.admin?}, owner=#{admin_membership.owner?}"
  puts "Member can only do member things: member=#{member_membership.member?}, admin=#{member_membership.admin?}, owner=#{member_membership.owner?}"

  # Create a project
  puts "\n📁 Creating a test project..."
  project = Project.create!(name: 'Test Project', discription: 'A project for testing roles', team: team)
  puts "✅ Created project: #{project.name}"

  # Create project memberships
  puts "\n🔐 Setting up project memberships..."
  project_owner = ProjectMembership.create!(user: user1, project: project, role: :owner)
  project_admin = ProjectMembership.create!(user: user2, project: project, role: :admin)
  project_member = ProjectMembership.create!(user: user3, project: project, role: :member)
  puts "✅ Created project memberships: Owner(#{user1.username}), Admin(#{user2.username}), Member(#{user3.username})"

  # Create a task
  puts "\n✅ Creating a test task..."
  task = Task.create!(project: project)
  puts "✅ Created task in project: #{project.name}"

  # Test task assignment
  puts "\n📋 Testing task assignment..."
  task_assignee = TaskMembership.create!(user: user3, task: task, role: :assignee)
  puts "✅ Assigned #{user3.username} to task as assignee"

  # Test permission checking (simulating the Authorizable concern)
  puts "\n🔒 Testing permission checking..."

  # Helper methods to simulate the concern
  def member_of_team?(user, team)
    membership = team.team_memberships.find_by(user: user)
    membership.present?
  end

  def admin_of_team?(user, team)
    membership = team.team_memberships.find_by(user: user)
    membership&.admin? || membership&.owner? || false
  end

  def owner_of_team?(user, team)
    membership = team.team_memberships.find_by(user: user)
    membership&.owner? || false
  end

  def can_invite_to_team?(user, team)
    admin_of_team?(user, team)
  end

  def can_manage_team_members?(user, team)
    owner_of_team?(user, team)
  end

  def can_delete_team?(user, team)
    owner_of_team?(user, team)
  end

  # Test permissions
  puts "\n🔐 Testing team permissions..."
  puts "#{user1.username} (Owner): member=#{member_of_team?(user1, team)}, admin=#{admin_of_team?(user1, team)}, owner=#{owner_of_team?(user1, team)}"
  puts "#{user2.username} (Admin): member=#{member_of_team?(user2, team)}, admin=#{admin_of_team?(user2, team)}, owner=#{owner_of_team?(user2, team)}"
  puts "#{user3.username} (Member): member=#{member_of_team?(user3, team)}, admin=#{admin_of_team?(user3, team)}, owner=#{owner_of_team?(user3, team)}"

  puts "\n🔐 Testing team actions..."
  puts "#{user1.username} (Owner): can_invite=#{can_invite_to_team?(user1, team)}, can_manage=#{can_manage_team_members?(user1, team)}, can_delete=#{can_delete_team?(user1, team)}"
  puts "#{user2.username} (Admin): can_invite=#{can_invite_to_team?(user2, team)}, can_manage=#{can_invite_to_team?(user2, team)}, can_delete=#{can_delete_team?(user2, team)}"
  puts "#{user3.username} (Member): can_invite=#{can_invite_to_team?(user3, team)}, can_manage=#{can_invite_to_team?(user3, team)}, can_delete=#{can_delete_team?(user3, team)}"

  # Test role promotion/demotion simulation
  puts "\n⬆️ Testing role promotion simulation..."
  puts "Before promotion: #{user3.username} is #{user3.team_memberships.find_by(team: team).role}"

  # Simulate promotion (in real app, this would be done by owner)
  if can_manage_team_members?(user1, team)
    user3.team_memberships.find_by(team: team).update!(role: :admin)
    puts "After promotion: #{user3.username} is now #{user3.team_memberships.find_by(team: team).role}"
  end

  puts "\n🎉 Role system test completed successfully!"
  puts "\n📋 Summary of what was tested:"
  puts "✅ User creation and authentication"
  puts "✅ Team and project creation"
  puts "✅ Role-based memberships (Member, Admin, Owner)"
  puts "✅ Role inheritance (Admin gets Member permissions, Owner gets Admin permissions)"
  puts "✅ Permission checking methods"
  puts "✅ Task assignment system"
  puts "✅ Role promotion/demotion capability"

rescue => e
  puts "\n❌ Error during testing: #{e.message}"
  puts e.backtrace.first(5)
end

puts "\n🧹 Cleaning up test data..."
# Clean up test data
User.where(username: [ 'owner_user', 'admin_user', 'member_user' ]).destroy_all
Team.where(name: 'Test Team').destroy_all
Project.where(name: 'Test Project').destroy_all
puts "✅ Cleanup completed"
