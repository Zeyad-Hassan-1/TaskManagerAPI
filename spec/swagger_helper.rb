# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  config.swagger_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  config.swagger_docs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Task Manager API',
        description: 'A comprehensive task management API with teams, projects, and collaboration features',
        version: 'v1'
      },
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        },
        {
          url: 'https://your-production-url.com',
          description: 'Production server'
        }
      ],
      components: {
        securitySchemes: {
          BearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT'
          }
        }
      },
      paths: {},
      tags: [
        { name: 'Authentication', description: 'User authentication endpoints' },
        { name: 'Users', description: 'User management endpoints' },
        { name: 'Password Resets', description: 'Password reset endpoints' },
        { name: 'Teams', description: 'Team management endpoints' },
        { name: 'Projects', description: 'Project management endpoints' },
        { name: 'Tasks', description: 'Task management endpoints' },
        { name: 'Sub Tasks', description: 'Sub-task management endpoints' },
        { name: 'Comments', description: 'Comment management endpoints' },
        { name: 'Attachments', description: 'Attachment management endpoints' },
        { name: 'Tags', description: 'Tag management endpoints' },
        { name: 'Activities', description: 'User activity endpoints' },
        { name: 'Invitations', description: 'Invitation management endpoints' },
        { name: 'Memberships', description: 'Membership management endpoints' },
        { name: 'System', description: 'System health and monitoring endpoints' }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The swagger_docs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in the filename
  # of the resulting Swagger file.
  config.swagger_format = :yaml
end
