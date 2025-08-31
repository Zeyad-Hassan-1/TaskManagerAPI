# Task Manager API

A comprehensive task management API built with Ruby on Rails, featuring teams, projects, tasks, and collaboration capabilities.

## Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Database Setup](#database-setup)
  - [Running the Application](#running-the-application)
- [API Documentation](#api-documentation)
- [Authentication](#authentication)
- [Configuration](#configuration)
- [Testing](#testing)
- [Deployment](#deployment)
  - [Environment Variables](#environment-variables)
  - [Security Considerations](#security-considerations)
  - [Performance Optimization](#performance-optimization)
- [ERD Diagram](#erd-diagram)
- [Contributing](#contributing)
- [License](#license)

## Features

- User authentication (signup, login, logout, password reset)
- Team management (create, update, delete teams)
- Project management within teams
- Task and sub-task management
- Role-based access control (owner, admin, member)
- Activity tracking
- File attachments and comments
- Real-time notifications
- API documentation with Swagger

## Getting Started

### Prerequisites

- Ruby 3.4.4
- Rails 8.0.2.1
- PostgreSQL 13+
- Node.js 16+ (for asset compilation)
- Yarn 1.22+ (for asset dependencies)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/task_manager_api.git
   cd task_manager_api
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Install additional tools:
   ```bash
   gem install foreman  # For process management
   ```

### Database Setup

1. Create the database:
   ```bash
   rails db:create
   ```

2. Run migrations:
   ```bash
   rails db:migrate
   ```

3. (Optional) Seed the database with sample data:
   ```bash
   rails db:seed
   ```

### Running the Application

You can run the application in two ways:

#### Option 1: Direct Installation (Recommended for Development)

1. Make sure PostgreSQL is running on your system
2. Set up the database:
   ```bash
   rails db:create
   rails db:migrate
   ```
3. Start the Rails server:
   ```bash
   rails server
   ```

#### Option 2: Docker (Recommended for Consistent Development Environment)

1. Build and start the services:
   ```bash
   docker-compose up --build
   ```

2. On first run, set up the database:
   ```bash
   docker-compose exec web rails db:create
   docker-compose exec web rails db:migrate
   ```

The application will be available at `http://localhost:3000`.

## API Documentation

This API is fully documented using Swagger UI. All endpoints, parameters, request/response formats, and examples are available through the interactive documentation.

### Accessing Swagger Documentation

1. Start the Rails server:
   ```bash
   rails server
   ```

2. Open your browser and navigate to:
   ```
   http://localhost:3000/api-docs
   ```

3. You'll see the Swagger UI interface with all available endpoints organized by category.

### Using the API Documentation

1. **Authentication**: Most endpoints require authentication. Click the "Authorize" button at the top of the Swagger UI and enter your Bearer token.

2. **Exploring Endpoints**: 
   - Expand any endpoint to see details
   - Click "Try it out" to test endpoints directly in the browser
   - View example requests and responses
   - See required parameters and data formats

## Using This API in Your Applications

If you're a developer who wants to integrate this Task Manager API into your own application, you can explore all available endpoints through the Swagger UI documentation.

### Core Concepts

- **Teams**: Top-level organizational units
- **Projects**: Belong to teams
- **Tasks**: Belong to projects
- **Sub-tasks**: Belong to tasks
- **Memberships**: Users can have different roles (owner, admin, member) in teams, projects, and tasks
- **Invitations**: Users can invite others to teams and projects

### Authentication

All API requests (except signup and login) require authentication using JWT tokens. 
Refer to the Swagger documentation for specific authentication endpoints and flows.

### Integration with Frontend Applications

This API can be easily integrated with any frontend framework. Here are instructions for common scenarios:

#### JavaScript/TypeScript Integration

Example using fetch API:

```javascript
// User Login
async function login(username, password) {
  const response = await fetch('/api/v1/login', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ username, password }),
  });
  
  if (response.ok) {
    const data = await response.json();
    // Store the access token in localStorage or state management
    localStorage.setItem('access_token', data.access_token);
    return data;
  }
  throw new Error('Login failed');
}

// Making Authenticated Requests
async function apiRequest(endpoint, options = {}) {
  const token = localStorage.getItem('access_token');
  
  const defaultOptions = {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
      ...options.headers,
    },
  };
  
  const response = await fetch(`/api/v1${endpoint}`, {
    ...options,
    ...defaultOptions,
  });
  
  return response.json();
}
```

#### CORS Configuration

The API is configured to allow cross-origin requests. In production, make sure to:
1. Set the `CORS_ORIGINS` environment variable to your frontend domain(s)
2. Example: `CORS_ORIGINS=https://yourapp.com,https://app.yourapp.com`

#### File Uploads

For file attachments, use multipart form data:

```javascript
async function uploadAttachment(taskId, file, name) {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('name', name);
  
  const response = await fetch(`/api/v1/tasks/${taskId}/attachments`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${localStorage.getItem('access_token')}`,
    },
    body: formData,
  });
  
  return response.json();
}
```

#### Error Handling

Implement consistent error handling across your application:

```javascript
async function handleApiError(response) {
  if (response.status === 401) {
    // Token expired, redirect to login
    localStorage.removeItem('access_token');
    window.location.href = '/login';
  } else if (response.status === 422) {
    // Validation errors
    const errorData = await response.json();
    throw new Error(errorData.errors.join(', '));
  } else {
    // Other errors
    throw new Error('An error occurred');
  }
}
```

#### Best Practices

1. **State Management**: Use a state management solution (Redux, Context API, etc.) to manage user data and authentication state
2. **Loading States**: Show loading indicators during API requests
3. **Error Boundaries**: Implement error boundaries to handle API failures gracefully
4. **Caching**: Implement caching strategies to reduce unnecessary API calls
5. **Security**: Never store sensitive tokens in plain text; use secure storage mechanisms

### SDKs and Libraries

Currently, there are no official SDKs for this API. However, you can:

1. Use the Swagger documentation to generate client code in your preferred language
2. Use standard HTTP libraries to make requests
3. Follow REST best practices for your integration

### 7. API Versioning and Compatibility

This API follows semantic versioning:
- Major versions (v1, v2) may introduce breaking changes
- Minor versions (v1.1, v1.2) add functionality without breaking changes
- Patch versions (v1.0.1, v1.0.2) include bug fixes

Currently, the API is at v1. When new versions are released:
- Old versions will be supported for a transition period
- Deprecation notices will be provided in advance
- Migration guides will be provided for breaking changes

To ensure compatibility:
- Always specify the API version in your requests (`/api/v1/...`)
- Monitor release notes for breaking changes
- Test your integration with new versions before upgrading

## Configuration

### Environment Variables

Create a `.env` file in the root directory based on `.env.example`:

```bash
cp .env.example .env
```

Key configuration variables include:

- `DATABASE_URL`: PostgreSQL database connection string
- `JWT_SECRET`: Secret key for JWT token signing
- `RAILS_ENV`: Application environment (development, test, production)
- `RAILS_MASTER_KEY`: Master key for encrypted credentials

### CORS Configuration

The API is configured to allow cross-origin requests. Modify `config/initializers/cors.rb` to adjust allowed origins for your deployment.

### Email Configuration

For password reset functionality, configure your email service in `config/environments/production.rb`.

## Testing

Run the test suite with:

```bash
rspec
```

Run tests with coverage report:

```bash
COVERAGE=true rspec
```

## Deployment

### Environment Variables for Production

In production, ensure these environment variables are set:

- `DATABASE_URL`: Production database connection
- `JWT_SECRET`: Strong secret key (use `rails secret` to generate)
- `SECRET_KEY_BASE`: Rails secret key base (use `rails secret` to generate)
- `RAILS_ENV`: Set to "production"
- `RAILS_SERVE_STATIC_FILES`: Set to "true" if serving assets with Rails
- `RAILS_LOG_TO_STDOUT`: Set to "true" for containerized deployments
- `CORS_ORIGINS`: Comma-separated list of allowed origins (e.g., "https://yourfrontend.com,https://app.yourfrontend.com")
- `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_DOMAIN`, `SMTP_USERNAME`, `SMTP_PASSWORD`: Email configuration for password resets

### Security Considerations

1. **Strong Secrets**: 
   - Generate new `JWT_SECRET` and `SECRET_KEY_BASE` for production
   - Never commit secrets to version control
   - Use environment variables or encrypted credentials

2. **HTTPS**: 
   - Always use HTTPS in production
   - Configure SSL termination at the load balancer or reverse proxy level

3. **Database Security**:
   - Use strong database credentials
   - Restrict database access to application servers only
   - Enable database encryption for sensitive data

4. **CORS**: 
   - Restrict allowed origins in `config/initializers/cors.rb` or via `CORS_ORIGINS` environment variable
   - Never use "*" in production

5. **Rate Limiting**: 
   - Implement rate limiting at the infrastructure level
   - Consider adding Rack attack middleware for application-level rate limiting

6. **File Uploads**: 
   - Validate file types and sizes
   - Store uploaded files securely (consider using cloud storage like AWS S3)
   - Sanitize filenames

7. **Authentication**:
   - Use secure password policies
   - Implement account lockout after failed attempts
   - Regularly rotate JWT secrets

### Performance Optimization

1. **Database**:
   - Add appropriate database indexes, especially on foreign keys and frequently queried columns
   - Use connection pooling (configured via `RAILS_MAX_THREADS`)
   - Consider read replicas for read-heavy workloads

2. **Caching**:
   - Implement HTTP caching headers
   - Use Redis for caching frequently accessed data
   - Consider fragment caching for complex views

3. **Background Jobs**:
   - Use Active Job with a backend like Sidekiq for time-consuming operations
   - Process email sending and notifications asynchronously

4. **Asset Precompilation**:
   ```bash
   RAILS_ENV=production rails assets:precompile
   ```

5. **Monitoring**:
   - Set up application performance monitoring (APM)
   - Monitor database query performance
   - Track error rates and response times

### Deployment Platforms

#### Heroku

1. Create a new Heroku app:
   ```bash
   heroku create your-app-name
   ```

2. Set environment variables:
   ```bash
   heroku config:set JWT_SECRET=$(rails secret)
   heroku config:set SECRET_KEY_BASE=$(rails secret)
   ```

3. Add PostgreSQL database:
   ```bash
   heroku addons:create heroku-postgresql:hobby-dev
   ```

4. Deploy:
   ```bash
   git push heroku main
   ```

5. Run migrations:
   ```bash
   heroku run rails db:migrate
   ```

#### Docker (Generic Deployment)

1. Build the Docker image:
   ```bash
   docker build -t task_manager_api .
   ```

2. Run with Docker (example with environment variables):
   ```bash
   docker run -d \
     -p 80:80 \
     -e DATABASE_URL=postgresql://user:pass@dbhost:5432/dbname \
     -e JWT_SECRET=your-secret-here \
     -e SECRET_KEY_BASE=your-secret-key-base-here \
     --name task_manager_api \
     task_manager_api
   ```

#### Docker Compose (Multi-container Deployment)

For production-like deployments with separate services:

1. Update `docker-compose.yml` with production settings
2. Run:
   ```bash
   docker-compose up -d
   ```

#### Traditional Server Deployment

1. Set up a reverse proxy (Nginx) to serve static assets and proxy requests to Rails
2. Use a process manager like systemd or PM2 to manage the Rails server process
3. Set up log rotation for Rails logs
4. Configure automated backups for the database
5. Set up SSL certificates (Let's Encrypt)
6. Configure firewall rules to restrict access

### Health Checks

The application includes a health check endpoint at `/up` that returns 200 if the app is running properly. This can be used by load balancers and uptime monitors.

### Backup and Recovery

1. Regularly backup your database
2. Store backups in a secure, geographically distributed location
3. Test backup restoration procedures regularly
4. Consider point-in-time recovery for critical data

## ERD Diagram

![ERD Diagram](erd.pdf)

The Entity Relationship Diagram shows the database structure including Users, Teams, Projects, Tasks, and their relationships.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.