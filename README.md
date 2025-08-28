# Task Manager API

A comprehensive REST API for task management built with Ruby on Rails 8. This API provides a complete solution for managing teams, projects, tasks, and user invitations with real-time notifications.

## Features

### Core Functionality

- **User Management**: Registration, authentication, password reset
- **Team Management**: Create teams, manage members, role-based permissions
- **Project Management**: Organize tasks within projects
- **Task Management**: Create, assign, and track tasks with priorities and due dates
- **File Attachments**: Upload and manage files for projects and tasks
- **Comments System**: Add comments to projects and tasks
- **Tagging System**: Organize content with tags

### New Features ✨

- **Invitation System**: Invite users to teams and projects with email notifications
- **Activity Feed**: Real-time notifications for user activities
- **Polymorphic Associations**: Flexible relationships between models
- **JWT Authentication**: Secure token-based authentication with refresh tokens
- **Comprehensive API Documentation**: Swagger/OpenAPI documentation

## Tech Stack

- **Ruby**: 3.4.4
- **Rails**: 8.0.2.1
- **Database**: PostgreSQL
- **Authentication**: JWT with refresh tokens
- **File Storage**: Active Storage (configurable for AWS S3, Google Cloud, Azure)
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **Email**: SMTP (configurable)
- **API Documentation**: Rswag/Swagger
- **Testing**: RSpec with FactoryBot

## Quick Start

### Prerequisites

- Ruby 3.4.4
- PostgreSQL
- Redis (optional, for caching)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/Zeyad-Hassan-1/TaskManagerAPI.git
   cd task_manager_api
   ```

2. **Install dependencies**

   ```bash
   bundle install
   ```

3. **Set up the database**

   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. **Start the server**

   ```bash
   rails server
   ```

The API will be available at `http://localhost:3000`

## API Documentation

### Swagger UI

Access the interactive API documentation at:

- **Development**: `http://localhost:3000/api-docs`
- **Production**: `https://yourdomain.com/api-docs`

### Authentication

The API uses JWT (JSON Web Tokens) for authentication. Include the token in the Authorization header:

```text
Authorization: Bearer your_jwt_token_here
```

### Key Endpoints

#### Authentication Endpoints

- `POST /api/v1/signup` - User registration
- `POST /api/v1/login` - User login
- `POST /api/v1/refresh` - Refresh access token
- `GET /api/v1/me` - Get current user info

#### Teams

- `GET /api/v1/teams` - List user's teams
- `POST /api/v1/teams` - Create a team
- `POST /api/v1/teams/:id/invite_member` - Invite user to team

#### Projects

- `GET /api/v1/teams/:team_id/projects` - List team projects
- `POST /api/v1/teams/:team_id/projects` - Create project
- `POST /api/v1/projects/:id/invite_member` - Invite user to project

#### Tasks

- `GET /api/v1/projects/:project_id/tasks` - List project tasks
- `POST /api/v1/projects/:project_id/tasks` - Create task
- `POST /api/v1/tasks/:id/assign_member` - Assign task to user

#### Invitations (New) ✨

- `GET /api/v1/invitations` - List pending invitations
- `PUT /api/v1/invitations/:id` - Accept/decline invitation
- `DELETE /api/v1/invitations/:id` - Decline invitation

#### Activities (New) ✨

- `GET /api/v1/activities` - List user activities/notifications
- `POST /api/v1/activities/mark_as_read` - Mark all notifications as read

## Testing

### Run the full test suite

```bash
bundle exec rspec
```

### Run specific test files

```bash
# Model tests
bundle exec rspec spec/models/

# Controller tests
bundle exec rspec spec/controllers/

# Request specs
bundle exec rspec spec/requests/
```

### Test Coverage

The application includes comprehensive tests covering:

- Model validations and associations
- Controller actions and error handling
- API request/response cycles
- Authentication and authorization
- Background job processing

## Production Deployment

This API is ready for production deployment with comprehensive guides for different platforms.

### 🚀 Quick Deploy Options

**Free Deployment (No Credit Card Required):**
- **[Render.com](docs/RENDER_DEPLOYMENT.md)** - Easy setup, spins down after 15min
- **[Railway](docs/RAILWAY_DEPLOYMENT.md)** - $5/month credit, best performance
- **Fly.io** - Great performance, CLI-based

**Use deployment helper scripts:**
```bash
# For Render.com
./bin/deploy-render

# Check production configuration
./bin/production-check
```

### 📋 Production Features

✅ **Complete Configuration**
- JWT authentication with secure secrets
- Gmail SMTP integration for password resets
- Multi-database setup (primary, cache, queue, cable)
- File storage (local/cloud)
- Rate limiting and security headers

✅ **Production Ready**
- All 320 tests passing
- Comprehensive error handling
- API documentation included
- Health check endpoints
- Database migrations ready

### 📚 Deployment Guides

- **[Production Deployment Guide](docs/PRODUCTION_DEPLOYMENT.md)** - Complete production setup
- **[Render.com Deployment](docs/RENDER_DEPLOYMENT.md)** - Free tier deployment
- **[Railway Deployment](docs/RAILWAY_DEPLOYMENT.md)** - Premium free tier
- **[Service Setup Guide](docs/SERVICE_SETUP.md)** - Configure external services

## Configuration

### Storage Services

The application supports multiple storage backends:

- **Local Storage**: Files stored on the server
- **Amazon S3**: Cloud storage with AWS
- **Google Cloud Storage**: Cloud storage with GCP
- **Azure Storage**: Cloud storage with Microsoft Azure

### Email Services

Configure SMTP settings for email delivery:

- Gmail
- SendGrid
- Mailgun
- Custom SMTP server

### Background Jobs

The application uses Solid Queue for background job processing:

- Email delivery
- File processing
- Notification delivery

## Development

### Code Quality

- **Rubocop**: Code linting and style enforcement
- **Brakeman**: Security vulnerability scanning
- **RSpec**: Comprehensive test suite

### Database Schema

The application uses PostgreSQL with the following main tables:

- `users` - User accounts
- `teams` - Team entities
- `projects` - Project entities
- `tasks` - Task entities
- `invitations` - User invitations (polymorphic)
- `activities` - User activity notifications
- `team_memberships`, `project_memberships`, `task_memberships` - Membership relationships

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions or issues:

1. Check the API documentation at `/api-docs`
2. Review the test suite for usage examples
3. Check the logs for error details
4. Open an issue on GitHub

---

Built with ❤️ using Ruby on Rails 8
