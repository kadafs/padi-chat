# Quick Deploy Guide - Get Online in 5 Minutes

## Fastest Option: Railway or Render

### 🚀 Railway (Recommended - Easiest)

1. **Sign up:** Go to [railway.app](https://railway.app) and sign up with GitHub

2. **Deploy:**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your `chaskiq` repository

3. **Add Databases:**
   - Click "+ New" → Add PostgreSQL
   - Click "+ New" → Add Redis

4. **Set Environment Variables:**
   Click on your web service → Variables tab → Add these:
   ```
   RAILS_ENV=production
   RACK_ENV=production
   SECRET_KEY_BASE=(click "Generate" or run: rails secret)
   HOST=https://your-app.up.railway.app
   WS=wss://your-app.up.railway.app/cable
   ASSET_HOST=https://your-app.up.railway.app
   ADMIN_EMAIL=your-email@example.com
   ADMIN_PASSWORD=your-secure-password
   ```

5. **Deploy & Migrate:**
   - Railway will auto-deploy
   - Once deployed, go to your service → Deployments → Click the latest deployment
   - Open the terminal and run:
     ```bash
     rails db:migrate
     rails db:seed
     ```

6. **Done!** Visit your app URL

---

### 🎨 Render (Alternative)

1. **Sign up:** Go to [render.com](https://render.com) and sign up

2. **Create Web Service:**
   - New → Web Service
   - Connect your GitHub repo
   - Select your repository

3. **Configure:**
   - **Build Command:** `bundle install && yarn install && bundle exec rails assets:precompile`
   - **Start Command:** `bundle exec puma -C config/puma.rb`

4. **Add PostgreSQL:**
   - New → PostgreSQL
   - Render will auto-set `DATABASE_URL`

5. **Add Redis:**
   - New → Redis
   - Set `REDIS_URL` in your web service environment variables

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

7. **Deploy:** Render will automatically deploy

8. **Run Migrations:**
   - Go to your service → Shell
   - Run: `rails db:migrate && rails db:seed`

---

### ⚡ One-Click Heroku Deploy

If you have a Heroku account:

1. **Click this button:**
   [![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/chaskiq/chaskiq/tree/main)

2. **Fill in the form:**
   - App name
   - Region
   - Environment variables (see DEPLOYMENT_GUIDE.md)

3. **Deploy:** Click "Deploy app"

4. **Run migrations:**
   ```bash
   heroku run rails db:migrate
   heroku run rails db:seed
   ```

---

## Generate Secret Key

Before deploying, generate your secret key:

```bash
# On your local machine
rails secret
```

Copy the output and use it for `SECRET_KEY_BASE` environment variable.

---

## What You'll Need

- ✅ GitHub repository (public or connected to your hosting platform)
- ✅ Email address for admin account
- ✅ Credit card (for paid plans, though some have free tiers)

---

## Post-Deployment

After deployment:

1. ✅ Visit your app URL
2. ✅ Login with your admin credentials
3. ✅ Configure your app settings
4. ✅ Test the chat functionality
5. ✅ Set up custom domain (optional)

---

## Need Help?

- 📖 Full guide: See `DEPLOYMENT_GUIDE.md`
- 🐛 Issues: Check GitHub Issues
- 💬 Community: Join discussions

---

## Platform Comparison

| Platform | Time to Deploy | Free Tier | Easiest |
|----------|---------------|-----------|---------|
| Railway  | 5 minutes     | ❌        | ⭐⭐⭐⭐⭐ |
| Render   | 10 minutes    | ✅        | ⭐⭐⭐⭐ |
| Heroku   | 5 minutes     | ❌        | ⭐⭐⭐⭐⭐ |

**Recommendation:** Start with Railway or Render for the easiest experience!


