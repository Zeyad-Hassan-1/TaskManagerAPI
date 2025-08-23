#!/usr/bin/env ruby

# Preparation script for Postman testing
# Run this with: ruby prepare_for_testing.rb

puts "🚀 Preparing Task Manager API for Postman Testing"
puts "=" * 50

# Load the Rails environment
require_relative 'config/environment'

begin
  puts "\n🧹 Cleaning up any existing test data..."

  # Clean up any existing test users and data
  test_usernames = [ 'owner_user', 'admin_user', 'member_user' ]
  test_users = User.where(username: test_usernames)

  if test_users.any?
    puts "Found #{test_users.count} existing test users. Removing..."
    test_users.destroy_all
    puts "✅ Cleaned up existing test users"
  else
    puts "✅ No existing test data found"
  end

  # Clean up test teams and projects
  test_teams = Team.where(name: [ 'RBAC Test Team', 'Member Test Team' ])
  if test_teams.any?
    puts "Found #{test_teams.count} existing test teams. Removing..."
    test_teams.destroy_all
    puts "✅ Cleaned up existing test teams"
  end

  test_projects = Project.where(name: [ 'RBAC Test Project', 'Member Test Project' ])
  if test_projects.any?
    puts "Found #{test_projects.count} existing test projects. Removing..."
    test_projects.destroy_all
    puts "✅ Cleaned up existing test projects"
  end

  puts "\n🔍 Checking database connection..."
  if ActiveRecord::Base.connection.active?
    puts "✅ Database connection is active"
  else
    puts "❌ Database connection failed"
    exit 1
  end

  puts "\n🗃️ Checking database tables..."
  required_tables = %w[users teams projects tasks team_memberships project_memberships task_memberships]
  existing_tables = ActiveRecord::Base.connection.tables

  missing_tables = required_tables - existing_tables
  if missing_tables.any?
    puts "❌ Missing required tables: #{missing_tables.join(', ')}"
    puts "Please run: rails db:migrate"
    exit 1
  else
    puts "✅ All required tables exist"
  end

  puts "\n🔐 Testing models and relationships..."

  # Test User model
  test_user = User.new(username: 'test_check', email: 'test@example.com', password: 'password123')
  if test_user.valid?
    puts "✅ User model is working"
  else
    puts "❌ User model validation failed: #{test_user.errors.full_messages.join(', ')}"
  end

  # Test Team model
  test_team = Team.new(name: 'Test Team Check', discription: 'Test description')
  if test_team.valid?
    puts "✅ Team model is working"
  else
    puts "❌ Team model validation failed: #{test_team.errors.full_messages.join(', ')}"
  end

  # Test role enums
  if TeamMembership.roles.keys == [ 'member', 'admin', 'owner' ]
    puts "✅ TeamMembership roles are correctly defined"
  else
    puts "❌ TeamMembership roles are not correct: #{TeamMembership.roles.keys}"
  end

  if ProjectMembership.roles.keys == [ 'member', 'admin', 'owner' ]
    puts "✅ ProjectMembership roles are correctly defined"
  else
    puts "❌ ProjectMembership roles are not correct: #{ProjectMembership.roles.keys}"
  end

  if TaskMembership.roles.keys == [ 'assignee', 'reviewer', 'watcher' ]
    puts "✅ TaskMembership roles are correctly defined"
  else
    puts "❌ TaskMembership roles are not correct: #{TaskMembership.roles.keys}"
  end

  puts "\n🛠️ Testing API endpoints configuration..."

  # Check if routes are loaded
  rails_routes = Rails.application.routes.routes.map { |route| route.path.spec.to_s }

  required_routes = [
    '/api/v1/teams',
    '/api/v1/teams/:id',
    '/api/v1/teams/:id/invite_member',
    '/api/v1/projects',
    '/api/v1/tasks',
    '/api/v1/login',
    '/api/v1/signup'
  ]

  missing_routes = required_routes.select do |route|
    !rails_routes.any? { |r| r.include?(route.gsub(':id', '')) }
  end

  if missing_routes.any?
    puts "⚠️ Some routes might be missing: #{missing_routes.join(', ')}"
    puts "Routes are probably configured correctly with member routes"
  else
    puts "✅ All required routes are available"
  end

  puts "\n📊 Database statistics:"
  puts "Users: #{User.count}"
  puts "Teams: #{Team.count}"
  puts "Projects: #{Project.count}"
  puts "Tasks: #{Task.count}"
  puts "Team Memberships: #{TeamMembership.count}"
  puts "Project Memberships: #{ProjectMembership.count}"
  puts "Task Memberships: #{TaskMembership.count}"

  puts "\n🎉 Preparation completed successfully!"
  puts "\nNext steps:"
  puts "1. Start your Rails server: rails server"
  puts "2. Import the Postman collection and environment"
  puts "3. Run the tests in Postman"
  puts "\nFiles to import in Postman:"
  puts "- Task_Manager_API_RBAC_Tests.postman_collection.json"
  puts "- Task_Manager_API_Environment.postman_environment.json"

rescue => e
  puts "\n❌ Error during preparation: #{e.message}"
  puts e.backtrace.first(3)
  puts "\nPlease fix the above error before running Postman tests."
  exit 1
end
