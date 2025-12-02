# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require 'app_packages_catalog'

domain = ENV['HOST'] || 'http://localhost:3000'

AppPackagesCatalog.update_all unless Rails.env.test?

# Find or create the app
app = App.find_or_create_by(name: 'test app') do |a|
  a.domain_url = domain
end

# Update domain_url if it changed
app.update(domain_url: domain) if app.domain_url != domain

# Create or update ArticleSetting for the app
# Extract subdomain from domain (remove protocol and path)
host = domain.gsub(/^https?:\/\//, '').split('/').first
subdomain = host.split('.').first if host.present?

if app.article_settings.present?
  # Update existing ArticleSetting if domain/subdomain changed
  article_setting = app.article_settings
  article_setting.update(
    subdomain: subdomain || article_setting.subdomain || 'app',
    domain: host || article_setting.domain || domain
  )
else
  # Create new ArticleSetting
  app.create_article_settings(
    subdomain: subdomain || 'app',
    domain: host || domain
  )
end

Doorkeeper::Application.find_or_create_by(name: 'authapp') do |doorkeeper_app|
  doorkeeper_app.confidential = false
  # redirect_uri: "#{domain}/callback"
end
