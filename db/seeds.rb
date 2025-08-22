# Clear existing data
puts "Clearing existing data..."
User.destroy_all
Team.destroy_all
Project.destroy_all
Task.destroy_all

# Create a test user
puts "Creating test user..."
user = User.create!(
  username: 'testuser',
  email: 'test@example.com',
  password: 'password123',
  bio: 'Test user for development'
)

# Create a test team
puts "Creating test team..."
team = Team.create!(
  name: 'Development Team',
  discription: 'Main development team for the project'
)

# Create team membership
puts "Creating team membership..."
TeamMembership.create!(
  user: user,
  team: team,
  role: :admin
)

# Create a test project
puts "Creating test project..."
project = Project.create!(
  name: 'Task Manager API',
  discription: 'A comprehensive task management system',
  team: team
)

# Create project membership
puts "Creating project membership..."
ProjectMembership.create!(
  user: user,
  project: project,
  role: 1 # admin role
)

# Create a test task
puts "Creating test task..."
task = Task.create!(
  project: project
)

# Create task membership
puts "Creating task membership..."
TaskMembership.create!(
  user: user,
  task: task,
  role: :assignee
)

puts "Seed data created successfully!"
puts "User: #{user.username}"
puts "Team: #{team.name}"
puts "Project: #{project.name}"
puts "Task ID: #{task.id}"
