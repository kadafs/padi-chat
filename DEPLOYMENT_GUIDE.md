# Deployment Guide for Padi Chat

This guide will help you deploy your Padi Chat application online. The application is a Ruby on Rails backend with a React frontend, using PostgreSQL and Redis.

## Prerequisites

- Git repository (GitHub, GitLab, or Bitbucket)
- Account on your chosen hosting platform
- Domain name (optional, but recommended)

## Quick Deploy Options

### Option 1: Heroku (Easiest - One-Click Deploy)

Heroku is the easiest option since your app is already configured for it.

#### Steps:

1. **Click the Deploy Button:**
   - Visit: https://heroku.com/deploy?template=https://github.com/chaskiq/chaskiq/tree/main
   - Or use the button in your README.md

2. **Configure Environment Variables:**
   After deployment, set these in Heroku Dashboard → Settings → Config Vars:
   ```
   HOST=https://your-app-name.herokuapp.com
   WS=wss://your-app-name.herokuapp.com/cable
   ASSET_HOST=https://your-app-name.herokuapp.com
   ADMIN_EMAIL=your-email@example.com
   ADMIN_PASSWORD=your-secure-password
   SECRET_TOKEN=(auto-generated)
   AWS_ACCESS_KEY_ID=(if using S3 for file storage)
   AWS_SECRET_ACCESS_KEY=(if using S3)
   AWS_S3_BUCKET=(if using S3)
   AWS_S3_REGION=(if using S3)
   DEFAULT_SENDER_EMAIL=(for email sending)
   ```

3. **Run Database Migrations:**
   ```bash
   heroku run rails db:migrate
   heroku run rails db:seed
   ```

4. **Access Your App:**
   Visit: `https://your-app-name.herokuapp.com`

**Note:** Heroku free tier is no longer available. You'll need a paid plan starting at $7/month.

---

### Option 2: Railway (Modern & Easy)

Railway is a modern platform that's great for Rails apps.

#### Steps:

1. **Sign up at [railway.app](https://railway.app)**

2. **Create New Project:**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Connect your repository

3. **Add Services:**
   - **PostgreSQL:** Add PostgreSQL service
   - **Redis:** Add Redis service
   - **Web Service:** Add your app

4. **Configure Environment Variables:**
   In your web service settings, add:
   ```
   RAILS_ENV=production
   RACK_ENV=production
   DATABASE_URL=(auto-set by Railway)
   REDIS_URL=(auto-set by Railway)
   SECRET_KEY_BASE=(run: rails secret)
   HOST=https://your-app.up.railway.app
   WS=wss://your-app.up.railway.app/cable
   ASSET_HOST=https://your-app.up.railway.app
   ADMIN_EMAIL=your-email@example.com
   ADMIN_PASSWORD=your-secure-password
   ```

5. **Deploy:**
   Railway will automatically detect your Rails app and deploy it.

6. **Run Migrations:**
   Use Railway's CLI or run:
   ```bash
   railway run rails db:migrate
   railway run rails db:seed
   ```

**Pricing:** Railway offers a $5/month starter plan with $5 credit.

---

### Option 3: Render (Great for Rails)

Render is excellent for Rails applications with automatic SSL and zero-downtime deployments.

#### Steps:

1. **Sign up at [render.com](https://render.com)**

2. **Create New Web Service:**
   - Connect your GitHub repository
   - Select your repository
   - Choose "Ruby" as the environment

3. **Configure Build Settings:**
   ```
   Build Command: bundle install && yarn install && bundle exec rails assets:precompile
   Start Command: bundle exec puma -C config/puma.rb
   ```

4. **Add PostgreSQL Database:**
   - Create a new PostgreSQL database
   - Render will automatically set `DATABASE_URL`

5. **Add Redis:**
   - Create a new Redis instance
   - Set `REDIS_URL` environment variable

6. **Set Environment Variables:**
   ```
   RAILS_ENV=production
   RACK_ENV=production
   SECRET_KEY_BASE=(run: rails secret)
   HOST=https://your-app.onrender.com
   WS=wss://your-app.onrender.com/cable
   ASSET_HOST=https://your-app.onrender.com
   ADMIN_EMAIL=your-email@example.com
   ADMIN_PASSWORD=your-secure-password
   ```

7. **Deploy:**
   Render will automatically deploy your app.

**Pricing:** Free tier available (with limitations), paid plans start at $7/month.

---

### Option 4: Fly.io (Docker-based)

Fly.io is great if you want to use Docker.

#### Steps:

1. **Install Fly CLI:**
   ```bash
   # Windows (PowerShell)
   iwr https://fly.io/install.ps1 -useb | iex
   ```

2. **Login:**
   ```bash
   fly auth login
   ```

3. **Initialize Fly.io:**
   ```bash
   fly launch
   ```
   This will create a `fly.toml` configuration file.

4. **Create PostgreSQL Database:**
   ```bash
   fly postgres create --name your-app-db
   fly postgres attach your-app-db
   ```

5. **Create Redis:**
   ```bash
   fly redis create
   ```

6. **Set Secrets:**
   ```bash
   fly secrets set SECRET_KEY_BASE=$(rails secret)
   fly secrets set RAILS_ENV=production
   fly secrets set HOST=https://your-app.fly.dev
   fly secrets set WS=wss://your-app.fly.dev/cable
   ```

7. **Deploy:**
   ```bash
   fly deploy
   ```

8. **Run Migrations:**
   ```bash
   fly ssh console -C "rails db:migrate"
   fly ssh console -C "rails db:seed"
   ```

**Pricing:** Free tier available, paid plans start at $1.94/month.

---

### Option 5: DigitalOcean App Platform

#### Steps:

1. **Sign up at [digitalocean.com](https://digitalocean.com)**

2. **Create App:**
   - Go to App Platform
   - Create new app from GitHub

3. **Configure:**
   - Select your repository
   - Choose Ruby as the runtime
   - Add PostgreSQL and Redis databases

4. **Set Environment Variables:**
   Same as other platforms

5. **Deploy:**
   DigitalOcean will handle the deployment automatically.

**Pricing:** Starts at $5/month.

---

## Manual Deployment (VPS)

If you prefer to deploy on your own VPS (DigitalOcean, Linode, AWS EC2, etc.):

### Requirements:
- Ubuntu 20.04+ or similar Linux distribution
- PostgreSQL 15+
- Redis 6+
- Node.js 16+
- Ruby 3.3.5+
- Nginx (for reverse proxy)

### Quick Setup Script:

See `deploy/vps-setup.sh` for a complete setup script.

### Manual Steps:

1. **Install Dependencies:**
   ```bash
   sudo apt update
   sudo apt install -y postgresql redis-server nginx nodejs yarn git
   ```

2. **Install Ruby:**
   ```bash
   curl -sSL https://rvm.io/mpapis.asc | gpg --import -
   \curl -sSL https://get.rvm.io | bash -s stable --ruby=3.3.5
   ```

3. **Clone Repository:**
   ```bash
   git clone https://github.com/your-username/chaskiq.git
   cd chaskiq
   ```

4. **Install Dependencies:**
   ```bash
   bundle install
   yarn install
   ```

5. **Configure Database:**
   ```bash
   # Create database
   sudo -u postgres createuser -s your_user
   sudo -u postgres createdb chaskiq_production
   
   # Set environment variables
   export DATABASE_URL=postgresql://user:password@localhost/chaskiq_production
   export REDIS_URL=redis://localhost:6379/0
   export SECRET_KEY_BASE=$(rails secret)
   export RAILS_ENV=production
   ```

6. **Precompile Assets:**
   ```bash
   RAILS_ENV=production bundle exec rails assets:precompile
   ```

7. **Run Migrations:**
   ```bash
   RAILS_ENV=production bundle exec rails db:migrate
   RAILS_ENV=production bundle exec rails db:seed
   ```

8. **Setup Systemd Service:**
   Create `/etc/systemd/system/chaskiq.service`:
   ```ini
   [Unit]
   Description=Padi Chat
   After=network.target

   [Service]
   Type=simple
   User=your_user
   WorkingDirectory=/path/to/chaskiq
   Environment="RAILS_ENV=production"
   Environment="DATABASE_URL=postgresql://..."
   Environment="REDIS_URL=redis://localhost:6379/0"
   ExecStart=/usr/local/rvm/bin/rvm 3.3.5 do bundle exec puma -C config/puma.rb
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

9. **Start Service:**
   ```bash
   sudo systemctl enable chaskiq
   sudo systemctl start chaskiq
   ```

10. **Configure Nginx:**
    See `deploy/nginx.conf` for Nginx configuration.

---

## Environment Variables Reference

### Required Variables:
- `RAILS_ENV=production`
- `RACK_ENV=production`
- `SECRET_KEY_BASE` - Generate with: `rails secret`
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string
- `HOST` - Your app's URL (e.g., https://your-app.com)
- `WS` - WebSocket URL (e.g., wss://your-app.com/cable)
- `ASSET_HOST` - Asset host URL (usually same as HOST)

### Optional but Recommended:
- `ADMIN_EMAIL` - Admin user email
- `ADMIN_PASSWORD` - Admin user password
- `AWS_ACCESS_KEY_ID` - For S3 file storage
- `AWS_SECRET_ACCESS_KEY` - For S3 file storage
- `AWS_S3_BUCKET` - S3 bucket name
- `AWS_S3_REGION` - S3 region
- `DEFAULT_SENDER_EMAIL` - Email sender address

### Generate Secret Key:
```bash
rails secret
```

---

## Post-Deployment Checklist

- [ ] Database migrations completed
- [ ] Database seeded with initial data
- [ ] Environment variables configured
- [ ] SSL certificate installed (HTTPS)
- [ ] Admin account created
- [ ] Email configuration tested
- [ ] File storage configured (S3 or local)
- [ ] Background jobs (Sidekiq) running
- [ ] WebSocket server (AnyCable) running
- [ ] Monitoring/logging configured

---

## Troubleshooting

### Database Connection Issues:
- Verify `DATABASE_URL` is correct
- Check database is accessible
- Ensure migrations have run

### Asset Compilation Errors:
- Check Node.js version (should be 16+)
- Verify all dependencies installed
- Check build logs for specific errors

### WebSocket Issues:
- Verify `WS` environment variable is set
- Check AnyCable/Redis connection
- Ensure WebSocket endpoint is accessible

### Performance Issues:
- Enable asset CDN (CloudFront, Cloudflare)
- Configure Redis caching
- Optimize database queries
- Use background jobs for heavy tasks

---

## Support

For more help:
- Check the [official documentation](https://dev.chaskiq.io)
- Visit [GitHub Issues](https://github.com/chaskiq/chaskiq/issues)
- Join the community discussions

---

## Recommended Hosting Comparison

| Platform | Ease of Use | Price | Best For |
|----------|-------------|-------|----------|
| Heroku | ⭐⭐⭐⭐⭐ | $7+/mo | Quick deployment |
| Railway | ⭐⭐⭐⭐ | $5+/mo | Modern apps |
| Render | ⭐⭐⭐⭐ | $7+/mo | Rails apps |
| Fly.io | ⭐⭐⭐ | $2+/mo | Docker apps |
| DigitalOcean | ⭐⭐⭐ | $5+/mo | Full control |
| VPS | ⭐⭐ | $5+/mo | Custom setup |

Choose based on your needs:
- **Quickest:** Heroku or Railway
- **Budget:** Fly.io or VPS
- **Control:** VPS or DigitalOcean
- **Modern:** Railway or Render

