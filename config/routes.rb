Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  # API Versioning
  namespace :api do
    namespace :v1 do
      resources :activities, only: [ :index ] do
        collection do
          post :mark_as_read
        end
      end
      resources :invitations, only: [ :index, :update, :destroy ]
      # Authentication routes
      post "/login", to: "auth#login"
      post "/refresh", to: "auth#refresh"
      post "/logout", to: "auth#logout"
      post "/signup", to: "users#create"
      get "/me", to: "users#me"

      # Password resets
      resources :password_resets, only: [ :create ] do
        collection do
          put "/", to: "password_resets#update"  # PUT /api/v1/password_resets
        end
      end

      # Teams
      resources :teams do
        # Nested projects under teams
        resources :projects, only: [ :index, :create ]

        # Team member management
        member do
          post :invite_member
          delete "members/:user_id", to: "teams#remove_member", as: :remove_member
          put "members/:user_id/promote", to: "teams#promote_member", as: :promote_member
          put "members/:user_id/demote", to: "teams#demote_member", as: :demote_member
        end
      end

      # Projects (can also be accessed directly)
      resources :projects, except: [ :index, :create ] do
        # Nested tasks under projects
        resources :tasks, only: [ :index, :create ]
        resources :tags, only: [ :create, :destroy ], controller: "project_tags"
        resources :comments, only: [ :create, :update, :destroy ], controller: "project_comments"
        resources :attachments, only: [ :create, :destroy ], controller: "project_attachments"

        # Project member management
        member do
          post :invite_member
          delete "members/:user_id", to: "projects#remove_member", as: :remove_member
          put "members/:user_id/promote", to: "projects#promote_member", as: :promote_member
          put "members/:user_id/demote", to: "projects#demote_member", as: :demote_member
        end
      end

      # Tasks (can also be accessed directly)
      resources :tasks, except: [ :index, :create ] do
        resources :sub_tasks, only: [ :index, :create ]
        resources :tags, only: [ :create, :destroy ], controller: "task_tags"
        resources :comments, only: [ :create, :update, :destroy ], controller: "task_comments"
        resources :attachments, only: [ :create, :destroy ], controller: "task_attachments"
        # Task member management
        member do
          post :assign_member
          delete "members/:user_id", to: "tasks#remove_member", as: :remove_member
        end
      end

      resources :sub_tasks, only: [ :show, :update, :destroy ] do
        member do
          post :assign_member
          delete "members/:user_id", to: "sub_tasks#remove_member", as: :remove_member
        end
      end

      # Team memberships
      resources :team_memberships, only: [ :index, :create, :destroy ]

      # Project memberships
      resources :project_memberships, only: [ :index, :create, :destroy ]

      # Task memberships
      resources :task_memberships, only: [ :index, :create, :destroy ]
    end
  end

  # Legacy routes (for backward compatibility - you can remove these later)
  # post "/login", to: "auth#login"
  # post "/refresh", to: "auth#refresh"
  # post "/logout", to: "auth#logout"
  # post "/signup", to: "users#create"
  # get "/me", to: "users#me"
  # resources :password_resets, only: [ :create ] do
  #   collection do
  #     put "/", to: "password_resets#update"
  #   end
  # end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
