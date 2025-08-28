# 🎨 Render.com Deployment Guide (100% Free Forever)

## Why Render.com?
- ✅ **Completely free** - No credit card required
- ✅ PostgreSQL database included
- ✅ Automatic HTTPS
- ✅ GitHub integration
- ✅ Easy environment variables
- ⚠️ Only limitation: Spins down after 15min inactivity

## Step 1: Prepare Your Repository

### Create render.yaml (Optional but Recommended)
```yaml
services:
  - type: web
    name: task-manager-api
    env: ruby
    buildCommand: bundle install; bundle exec rails assets:precompile; bundle exec rails db:migrate
    startCommand: bundle exec rails server -p $PORT -e $RAILS_ENV
    envVars:
      - key: RAILS_ENV
        value: production
      - key: RAILS_SERVE_STATIC_FILES
        value: true
      - key: RAILS_LOG_TO_STDOUT
        value: true

databases:
  - name: task-manager-db
    databaseName: task_manager_api_production
    user: task_manager_api
```

## Step 2: Deploy to Render

### 1. Sign Up
- Go to https://render.com
- Click "Get Started for Free"
- Sign up with GitHub (no credit card needed)

### 2. Create Web Service
- Click "New +" → "Web Service"
- Connect your GitHub account
- Select your `TaskManagerAPI` repository
- Choose these settings:
  - **Name**: `task-manager-api` (or your choice)
  - **Environment**: `Ruby`
  - **Build Command**: `bundle install; bundle exec rails db:migrate`
  - **Start Command**: `bundle exec rails server -p $PORT -e production`

### 3. Create PostgreSQL Database
- Click "New +" → "PostgreSQL"
- Name: `task-manager-db`
- Plan: **Free** (no credit card required)
- Save the database info (Render will provide connection details)

### 4. Connect Database to Web Service
- Go to your web service settings
- In "Environment" tab, Render automatically adds:
  - `DATABASE_URL` (points to your free PostgreSQL)

## Step 3: Set Environment Variables

In your web service "Environment" tab, add these variables:

```
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true

# Your secrets (from .env.production)
JWT_SECRET=e7812e313ac4db145f930b912d72bb21322ae36fb1a0db51ad5a69942af744f2783f4e2e807a6f17e83debd96904d576bb77eba17db3286a3dd54b82d92d0f5b
SECRET_KEY_BASE=5a72b21dd5be85a211f9e3cf03fdd22914309f4f3197b474193daea57c0bd5fc1953eabc014b2e57363dd510919734d09f1078f64837f8a9bf096be848837a78
RAILS_MASTER_KEY=b11153ee5e344c743c7c1aee237a123d

# Email configuration
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=gmail.com
SMTP_USERNAME=Zeyad.h.dev@gmail.com
SMTP_PASSWORD=xgvs cpsc ouyg ezsw
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_OPENSSL_VERIFY_MODE=peer
SMTP_RAISE_DELIVERY_ERRORS=true

# App settings
APP_NAME=task_manager_api
ACTIVE_STORAGE_SERVICE=local
WEB_CONCURRENCY=1
MAX_THREADS=5
RAILS_MAX_THREADS=5
```

## Step 4: Deploy

1. **Automatic Deployment**: Render deploys automatically when you push to GitHub
2. **Manual Deploy**: Click "Deploy Latest Commit" in Render dashboard
3. **Check Logs**: Monitor deployment in the "Logs" tab

## Step 5: Run Database Setup

After first deployment, run database commands:

### Option A: Render Dashboard
- Go to your service → "Shell" tab
- Run: `bundle exec rails db:seed`

### Option B: Render CLI (Optional)
```bash
# Install Render CLI
npm install -g @render/cli
render auth login
render shell task-manager-api
bundle exec rails db:seed
```

## Step 6: Update App URLs

Once deployed, you'll get a URL like: `https://task-manager-api.onrender.com`

Update these environment variables in Render:
```
APP_HOST=task-manager-api.onrender.com
APP_PROTOCOL=https
APP_PORT=443
CORS_ORIGINS=https://your-frontend-domain.com,https://task-manager-api.onrender.com
```

## Step 7: Test Your API

1. **Health Check**: `https://task-manager-api.onrender.com/health`
2. **API Docs**: `https://task-manager-api.onrender.com/api-docs`
3. **Create User**: POST to `/api/v1/users`
4. **Password Reset**: Test email functionality

## Free Tier Details

**Web Service (Free)**:
- ✅ 750 hours/month (enough for always-on if you optimize)
- ✅ Automatic HTTPS
- ✅ Custom domains
- ✅ GitHub auto-deploys
- ⚠️ Spins down after 15min inactivity (cold start: ~30 seconds)

**PostgreSQL (Free)**:
- ✅ 1GB storage
- ✅ Shared CPU
- ✅ 90 days data retention
- ✅ Perfect for development/portfolio projects

## Keep Your App Warm (Optional)

To prevent spin-down, you can:

1. **Use a monitoring service** (free):
   - UptimeRobot.com (free tier)
   - Monitor your `/health` endpoint every 5 minutes

2. **Add a simple cron job** to ping your app

## Alternative: Fly.io

If Render doesn't work for you:

### Fly.io Free Tier
```bash
# Install flyctl
curl -L https://fly.io/install.sh | sh

# Deploy (in your project directory)
fly launch --name task-manager-api
fly deploy
fly postgres create --name task-manager-db
fly postgres attach --app task-manager-api task-manager-db
```

Fly.io gives you:
- ✅ 3 shared CPU VMs
- ✅ PostgreSQL database
- ✅ Better performance than Render
- ✅ No spin-down issues

## Summary

**Best Free Options (No Credit Card)**:
1. **Render.com** - Easiest setup, spins down after 15min
2. **Fly.io** - Better performance, more complex setup
3. **Railway** - If you haven't used it yet (best option)

Your Task Manager API will be **100% functional and free**! 🎉

Choose Render.com for simplicity or Fly.io for performance.
