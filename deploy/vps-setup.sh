#!/bin/bash
# VPS Setup Script for Padi Chat
# Run this script on a fresh Ubuntu 20.04+ server
# Usage: sudo bash deploy/vps-setup.sh

set -e

echo "🚀 Starting Padi Chat VPS Setup..."

# Update system
echo "📦 Updating system packages..."
apt-get update
apt-get upgrade -y

# Install basic dependencies
echo "📦 Installing basic dependencies..."
apt-get install -y curl git build-essential libssl-dev libreadline-dev zlib1g-dev \
  libpq-dev libyaml-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev \
  software-properties-common libffi-dev nodejs npm yarn nginx

# Install PostgreSQL
echo "📦 Installing PostgreSQL..."
apt-get install -y postgresql postgresql-contrib

# Install Redis
echo "📦 Installing Redis..."
apt-get install -y redis-server

# Install Ruby using RVM
echo "📦 Installing Ruby 3.3.5..."
if ! command -v rvm &> /dev/null; then
  curl -sSL https://rvm.io/mpapis.asc | gpg --import -
  \curl -sSL https://get.rvm.io | bash -s stable
  source /etc/profile.d/rvm.sh
fi

rvm install 3.3.5
rvm use 3.3.5 --default

# Install Bundler
echo "📦 Installing Bundler..."
gem install bundler

# Create application user
echo "👤 Creating application user..."
if ! id "chaskiq" &>/dev/null; then
  useradd -m -s /bin/bash chaskiq
  usermod -aG sudo chaskiq
fi

# Create application directory
echo "📁 Creating application directory..."
APP_DIR="/var/www/chaskiq"
mkdir -p $APP_DIR
chown chaskiq:chaskiq $APP_DIR

# Setup PostgreSQL
echo "🗄️  Setting up PostgreSQL..."
sudo -u postgres psql << EOF
CREATE USER chaskiq WITH PASSWORD 'CHANGE_THIS_PASSWORD';
CREATE DATABASE chaskiq_production OWNER chaskiq;
ALTER USER chaskiq CREATEDB;
\q
EOF

# Configure Redis
echo "🔴 Configuring Redis..."
sed -i 's/supervised no/supervised systemd/' /etc/redis/redis.conf
systemctl restart redis-server
systemctl enable redis-server

# Setup Nginx
echo "🌐 Setting up Nginx..."
# Copy nginx config (you'll need to customize it)
# cp deploy/nginx.conf /etc/nginx/sites-available/chaskiq
# ln -s /etc/nginx/sites-available/chaskiq /etc/nginx/sites-enabled/
# rm /etc/nginx/sites-enabled/default

# Install SSL with Let's Encrypt
echo "🔒 Setting up SSL (Let's Encrypt)..."
apt-get install -y certbot python3-certbot-nginx

# Setup systemd service
echo "⚙️  Setting up systemd service..."
cat > /etc/systemd/system/chaskiq.service << 'EOF'
[Unit]
Description=Padi Chat Application Server
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
User=chaskiq
WorkingDirectory=/var/www/chaskiq
Environment="RAILS_ENV=production"
Environment="RACK_ENV=production"
ExecStart=/usr/local/rvm/bin/rvm 3.3.5 do bundle exec puma -C config/puma.rb
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=chaskiq

[Install]
WantedBy=multi-user.target
EOF

# Setup Sidekiq service
cat > /etc/systemd/system/chaskiq-sidekiq.service << 'EOF'
[Unit]
Description=Padi Chat Sidekiq Worker
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
User=chaskiq
WorkingDirectory=/var/www/chaskiq
Environment="RAILS_ENV=production"
Environment="RACK_ENV=production"
ExecStart=/usr/local/rvm/bin/rvm 3.3.5 do bundle exec sidekiq -C config/sidekiq.yml
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=chaskiq-sidekiq

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Clone your repository to /var/www/chaskiq"
echo "2. Set up environment variables in /var/www/chaskiq/.env"
echo "3. Run: cd /var/www/chaskiq && bundle install && yarn install"
echo "4. Run: RAILS_ENV=production bundle exec rails assets:precompile"
echo "5. Run: RAILS_ENV=production bundle exec rails db:migrate"
echo "6. Run: RAILS_ENV=production bundle exec rails db:seed"
echo "7. Configure Nginx (edit /etc/nginx/sites-available/chaskiq)"
echo "8. Get SSL certificate: certbot --nginx -d your-domain.com"
echo "9. Start services:"
echo "   sudo systemctl enable chaskiq chaskiq-sidekiq"
echo "   sudo systemctl start chaskiq chaskiq-sidekiq"
echo "   sudo systemctl restart nginx"


