# Production Deployment Checklist

## Pre-deployment Setup

### 1. Environment Variables

- [ ] Copy `.env.production.example` to `.env.production`
- [ ] Fill in all required environment variables
- [ ] Set strong passwords and secrets
- [ ] Configure database connection details

### 2. Database Setup

- [ ] Create production database
- [ ] Run database migrations: `rails db:migrate`
- [ ] Seed database if needed: `rails db:seed`
- [ ] Set up database backups

### 3. Storage Configuration

- [ ] Choose storage service (AWS S3, Google Cloud Storage, Azure, or local)
- [ ] Configure storage credentials
- [ ] Test file uploads in staging environment

### 4. Email Configuration

- [ ] Set up SMTP service (Gmail, SendGrid, Mailgun, etc.)
- [ ] Configure SMTP credentials
- [ ] Test email delivery

### 5. Security Configuration

- [ ] Set up SSL certificate
- [ ] Configure firewall rules
- [ ] Set up monitoring and logging
- [ ] Configure rate limiting

### 6. Performance Optimization

- [ ] Configure Redis for caching
- [ ] Set up background job processing
- [ ] Configure asset compilation
- [ ] Set up CDN for static assets

## Deployment Steps

### 1. Code Deployment

```bash
# Using Kamal (recommended)
kamal setup
kamal deploy

# Or using Capistrano
cap production deploy
```

### 2. Post-deployment Checks

- [ ] Verify application is running
- [ ] Test all API endpoints
- [ ] Check database connectivity
- [ ] Verify email functionality
- [ ] Test file uploads
- [ ] Check background jobs
- [ ] Monitor application logs

### 3. Monitoring Setup

- [ ] Set up error tracking (Rollbar, Sentry)
- [ ] Configure application monitoring
- [ ] Set up log aggregation
- [ ] Configure alerts

## Environment Variables Reference

### Required Variables

- `APP_HOST`: Your domain name
- `TASK_MANAGER_API_DATABASE_PASSWORD`: Database password
- `JWT_SECRET`: JWT signing secret (256+ bits)
- `SECRET_KEY_BASE`: Rails secret key base

### Optional but Recommended

- `SMTP_*`: Email configuration
- `AWS_*` or `GCP_*` or `AZURE_*`: Cloud storage
- `REDIS_URL`: Redis connection for caching
- `ROLLBAR_ACCESS_TOKEN`: Error tracking
- `SENTRY_DSN`: Error monitoring

## Troubleshooting

### Common Issues

1. **Database connection errors**: Check DATABASE_URL format
2. **Email not sending**: Verify SMTP settings
3. **File uploads failing**: Check storage configuration
4. **CORS errors**: Update CORS_ORIGINS environment variable

### Logs to Check

- Rails logs: `log/production.log`
- Nginx/Apache access logs
- Database logs
- Background job logs

## Security Checklist

- [ ] HTTPS enabled
- [ ] Secure cookies configured
- [ ] CORS properly configured
- [ ] Environment variables encrypted
- [ ] Database password complexity
- [ ] File permissions correct
- [ ] No sensitive data in logs
