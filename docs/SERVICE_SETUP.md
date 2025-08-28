# Service Configuration Guide 📋

This guide helps you configure essential services for production deployment.

## 🔧 Required Configurations Before Deployment

### 1. 📧 Email Service Setup (Required for password resets)

#### Option A: Gmail SMTP (Easiest for testing)
```bash
# 1. Enable 2-Factor Authentication on your Gmail account
# 2. Generate an App Password: https://myaccount.google.com/apppasswords
# 3. Use these settings in your .env.production:
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=gmail.com
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-16-character-app-password
```

#### Option B: SendGrid (Recommended for production)
```bash
# 1. Sign up at https://sendgrid.com
# 2. Create API key in Settings > API Keys
# 3. Use these settings:
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_DOMAIN=your-domain.com
SMTP_USERNAME=apikey
SMTP_PASSWORD=your-sendgrid-api-key
```

#### Option C: Mailgun
```bash
# 1. Sign up at https://www.mailgun.com
# 2. Add your domain and verify it
# 3. Get SMTP credentials from Domains > Your Domain > SMTP
SMTP_ADDRESS=smtp.mailgun.org
SMTP_PORT=587
SMTP_DOMAIN=your-domain.com
SMTP_USERNAME=your-mailgun-smtp-username
SMTP_PASSWORD=your-mailgun-smtp-password
```

### 2. 📁 File Storage Setup (Optional - starts with local storage)

#### Option A: Amazon S3 (Most popular)
```bash
# 1. Create AWS account and S3 bucket
# 2. Create IAM user with S3 permissions
# 3. Get access keys from IAM console
ACTIVE_STORAGE_SERVICE=amazon
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
AWS_S3_BUCKET=your-bucket-name
```

S3 Bucket Policy Example:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::YOUR-ACCOUNT-ID:user/YOUR-IAM-USER" },
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::your-bucket-name/*"
    }
  ]
}
```

#### Option B: Google Cloud Storage
```bash
# 1. Create GCP project and enable Cloud Storage API
# 2. Create service account with Storage Admin role
# 3. Download service account key JSON file
ACTIVE_STORAGE_SERVICE=google
GCP_PROJECT=your-project-id
GCP_BUCKET=your-bucket-name
GCP_CREDENTIALS_PATH=path/to/service-account-key.json
```

### 3. 🗄️ Database Setup

#### Option A: Hosted Database (Recommended)
- **Heroku PostgreSQL**: Automatic with Heroku deployment
- **Railway PostgreSQL**: One-click setup in Railway dashboard
- **Amazon RDS**: Managed PostgreSQL on AWS
- **Google Cloud SQL**: Managed PostgreSQL on GCP
- **DigitalOcean Managed Database**: Simple setup

#### Option B: Self-hosted PostgreSQL
```bash
# Install PostgreSQL
sudo apt update
sudo apt install postgresql postgresql-contrib

# Create database and user
sudo -u postgres psql
CREATE DATABASE task_manager_api_production;
CREATE USER task_manager_api WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE task_manager_api_production TO task_manager_api;
```

### 4. 🔐 Security Secrets Generation

```bash
# Generate JWT secret
ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"

# Generate Rails secret key base
rails secret

# Your secrets are already generated in .env.production file!
```

### 5. 🌐 Domain and SSL Setup

#### For Custom Domain:
```bash
# 1. Purchase domain from registrar (Namecheap, GoDaddy, etc.)
# 2. Point DNS A record to your server IP
# 3. Get SSL certificate (Let's Encrypt is free):
sudo certbot --nginx -d your-domain.com
```

#### Platform-specific SSL:
- **Heroku**: Automatic with paid dynos
- **Railway**: Automatic for custom domains
- **Render**: Automatic SSL certificates
- **DigitalOcean**: One-click SSL certificates

### 6. 📊 Optional: Monitoring Setup

#### Error Tracking with Sentry:
```bash
# 1. Sign up at https://sentry.io
# 2. Create new Rails project
# 3. Get your DSN and add to .env.production:
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id

# 4. Uncomment sentry gems in Gemfile and run bundle install
```

#### Performance Monitoring with New Relic:
```bash
# 1. Sign up at https://newrelic.com
# 2. Get license key from account settings
NEW_RELIC_LICENSE_KEY=your-license-key
NEW_RELIC_APP_NAME=Task Manager API
```

## 🚀 Deployment Platform Specific Settings

### Heroku Configuration:
```bash
# Set config vars
heroku config:set JWT_SECRET=your_jwt_secret
heroku config:set SMTP_USERNAME=your_email@gmail.com
heroku config:set SMTP_PASSWORD=your_app_password
# Add other environment variables...
```

### Railway Configuration:
1. Go to project dashboard
2. Click "Variables" tab
3. Add environment variables from .env.production

### Render Configuration:
1. Connect GitHub repository
2. Set environment variables in dashboard
3. Choose PostgreSQL database plan

## ✅ Pre-Deployment Checklist:

- [ ] Email service configured and tested
- [ ] Database connection string ready
- [ ] JWT_SECRET generated and secure
- [ ] CORS_ORIGINS set to your frontend domains
- [ ] Storage service configured (S3/GCS/local)
- [ ] Domain name purchased (if using custom domain)
- [ ] SSL certificate plan ready
- [ ] Environment variables file completed
- [ ] Backup strategy planned

## 🧪 Test Your Configuration:

```bash
# Test email configuration
rails runner "PasswordMailer.with(user: User.first).reset.deliver_now"

# Test storage configuration
rails runner "ActiveStorage::Blob.service.exist?('test')"

# Test database connection
rails runner "puts User.count"
```

## 📞 Need Help?

Common issues and solutions:
- **Email not sending**: Check app password vs regular password for Gmail
- **S3 permissions**: Ensure IAM user has proper bucket permissions
- **Database connection**: Verify DATABASE_URL format
- **CORS issues**: Make sure your frontend domain is in CORS_ORIGINS

Your API is ready for production deployment! 🎉
