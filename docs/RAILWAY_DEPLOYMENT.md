# 🚂 Railway Deployment Guide (100% Free)
# Complete guide for deploying your Task Manager API to Railway

## Prerequisites
- GitHub account
- Your TaskManagerAPI repository pushed to GitHub

## Step 1: Prepare Your Repository

### Add Railway Configuration
Create a `railway.toml` file in your project root:

```toml
[build]
  builder = "nixpacks"

[deploy]
  healthcheckPath = "/health"
  restartPolicyType = "ON_FAILURE"
  restartPolicyMaxRetries = 10

[environments.production]
  [environments.production.variables]
    RAILS_ENV = "production"
```

### Create a Health Check Endpoint
Add this to your `config/routes.rb`:

```ruby
get '/health', to: proc { [200, {}, ['OK']] }
```

### Prepare Database Configuration
Railway will provide a DATABASE_URL automatically.

## Step 2: Deploy to Railway

1. **Sign Up**: Go to https://railway.app
   - Click "Login with GitHub"
   - Authorize Railway to access your repositories

2. **Create New Project**:
   - Click "Deploy from GitHub repo"
   - Select your `TaskManagerAPI` repository
   - Railway will automatically detect it's a Rails app

3. **Add PostgreSQL Database**:
   - Click "New Service" in your project
   - Select "Database" → "PostgreSQL"
   - Railway automatically connects it to your app

4. **Set Environment Variables**:
   - Go to your web service
   - Click "Variables" tab
   - Add all variables from your .env.production file:

## Step 3: Environment Variables to Set

Copy these from your .env.production (one by one):

```
JWT_SECRET=e7812e313ac4db145f930b912d72bb21322ae36fb1a0db51ad5a69942af744f2783f4e2e807a6f17e83debd96904d576bb77eba17db3286a3dd54b82d92d0f5b
SECRET_KEY_BASE=5a72b21dd5be85a211f9e3cf03fdd22914309f4f3197b474193daea57c0bd5fc1953eabc014b2e57363dd510919734d09f1078f64837f8a9bf096be848837a78
RAILS_MASTER_KEY=b11153ee5e344c743c7c1aee237a123d
APP_NAME=task_manager_api
RAILS_ENV=production
RAILS_LOG_LEVEL=info
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=gmail.com
SMTP_USERNAME=Zeyad.h.dev@gmail.com
SMTP_PASSWORD=xgvs cpsc ouyg ezsw
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_OPENSSL_VERIFY_MODE=peer
SMTP_RAISE_DELIVERY_ERRORS=true
ACTIVE_STORAGE_SERVICE=local
WEB_CONCURRENCY=2
MAX_THREADS=5
RAILS_MAX_THREADS=5
```

**Important**: Don't set DATABASE_URL - Railway sets this automatically!

## Step 4: Deploy and Migrate

Railway will automatically deploy when you push to GitHub.

**Run Database Migrations**:
- In Railway dashboard, go to your service
- Open "Deploy" tab
- Once deployed, click "View Logs"
- You should see successful deployment

**Run Database Setup**:
- Go to your service settings
- Under "Deploy" section, you can run one-off commands
- Or use Railway CLI (optional):

```bash
# Install Railway CLI
npm install -g @railway/cli
railway login
railway run rails db:migrate db:seed
```

## Step 5: Update Your App Settings

Once deployed, Railway will give you a URL like:
`https://your-app-name.up.railway.app`

Update these in Railway's environment variables:
- `APP_HOST` = `your-app-name.up.railway.app`
- `APP_PROTOCOL` = `https`
- `APP_PORT` = `443`
- `CORS_ORIGINS` = `https://your-frontend-domain.com,https://your-app-name.up.railway.app`

## Step 6: Test Your Deployment

1. **API Health Check**: Visit `https://your-app-name.up.railway.app/health`
2. **API Documentation**: Visit `https://your-app-name.up.railway.app/api-docs`
3. **Test Registration**: POST to `/api/v1/users` to create a user
4. **Test Password Reset**: This will send emails via your Gmail

## Free Tier Limits

Railway Free Tier includes:
- ✅ $5/month usage credit (very generous for APIs)
- ✅ PostgreSQL database
- ✅ Custom domains
- ✅ Automatic HTTPS
- ✅ GitHub integration
- ✅ No credit card required

## Monitoring Your Usage

- Check usage in Railway dashboard
- Monitor database size and requests
- Your API should easily stay within free limits

## Backup Strategy (Free)

Since you're on free tier:
1. Regular `pg_dump` via Railway CLI
2. Store schema in your Git repository
3. Keep your seeds.rb file updated

## Alternative: Render.com

If Railway doesn't work, Render.com is also completely free:

1. Go to render.com
2. "New Web Service" from GitHub
3. Add PostgreSQL database (free)
4. Set environment variables
5. Deploy

**Note**: Render free tier spins down after 15min inactivity, Railway doesn't.

---

## Quick Start Commands

```bash
# 1. Add railway.toml and health endpoint
# 2. Push to GitHub
git add . && git commit -m "Railway deployment config" && git push

# 3. Deploy on Railway dashboard
# 4. Set environment variables
# 5. Your API is live!
```

Your Task Manager API will be fully functional and completely free! 🎉
