# frozen_string_literal: true

class ArticlesController < ApplicationController
  layout "articles"

  def show
    messenger_data
    render html: "", layout: "articles"
  end

  private

  def messenger_data
    subdomains = request.subdomains
    host = request.host
    
    # Try multiple lookup strategies:
    # 1. Full subdomain (e.g., "web-production-d051e.up")
    # 2. First subdomain only (e.g., "web-production-d051e") for Railway domains
    # 3. By domain field matching the host
    # 4. Fallback: if only one ArticleSetting exists, use it (for single-tenant deployments)
    article_setting = ArticleSetting.find_by(subdomain: subdomains.join(".")) ||
                      (subdomains.any? ? ArticleSetting.find_by(subdomain: subdomains.first) : nil) ||
                      ArticleSetting.find_by(domain: host) ||
                      (ArticleSetting.count == 1 ? ArticleSetting.first : nil)
    
    # Auto-create ArticleSetting if not found
    if article_setting.nil?
      # Try to find an app to associate with
      # domain_url is stored in preferences JSONB column, so we need to query it differently
      app = App.where("preferences->>'domain_url' = ?", host).first ||
            App.where("preferences->>'domain_url' LIKE ?", "%#{host}%").first ||
            (App.count == 1 ? App.first : nil)
      
      # If no app found by domain_url, try to find any app without ArticleSetting
      if app.nil?
        app = App.left_joins(:article_settings)
                 .where(article_settings: { id: nil })
                 .first || App.first
      end
      
      # If still no app, create one
      if app.nil?
        begin
          app = App.create!(
            name: 'Default App',
            domain_url: "https://#{host}"
          )
          Rails.logger.info "Created default App for host: #{host}"
        rescue StandardError => e
          Rails.logger.error "Failed to create App: #{e.message}"
          app = nil
        end
      end
      
      if app.present?
        # Auto-create or update ArticleSetting for the app
        subdomain_value = subdomains.first || host.split('.').first
        
        begin
          if app.article_settings.present?
            # Update existing ArticleSetting to match current subdomain/domain
            article_setting = app.article_settings
            # Only update if values are different to avoid validation issues
            if article_setting.subdomain != subdomain_value || article_setting.domain != host
              article_setting.update_columns(
                subdomain: subdomain_value,
                domain: host
              )
            end
            article_setting.reload
          else
            # Create new ArticleSetting for the app
            # Use find_or_create_by to handle race conditions
            article_setting = ArticleSetting.find_or_create_by(app: app) do |as|
              as.subdomain = subdomain_value
              as.domain = host
            end
            # If it already existed, update it
            if article_setting.persisted? && (article_setting.subdomain != subdomain_value || article_setting.domain != host)
              article_setting.update_columns(
                subdomain: subdomain_value,
                domain: host
              )
              article_setting.reload
            end
          end
        rescue ActiveRecord::RecordInvalid => e
          # If creation/update fails (e.g., validation error), log and try to find existing
          Rails.logger.error "Failed to create/update ArticleSetting: #{e.message}"
          # Try to find by app only
          article_setting = app.article_settings
        rescue StandardError => e
          Rails.logger.error "Error creating/updating ArticleSetting: #{e.message}"
          # Try to find by app only
          article_setting = app.article_settings
        end
      end
    end
    
    if article_setting.nil?
      attempted_lookups = []
      attempted_lookups << "subdomain: #{subdomains.join('.')}" if subdomains.any?
      attempted_lookups << "subdomain: #{subdomains.first}" if subdomains.any? && subdomains.length > 1
      attempted_lookups << "domain: #{host}"
      
      # Get existing subdomains for debugging
      existing_subdomains = ArticleSetting.pluck(:subdomain).compact
      existing_domains = ArticleSetting.pluck(:domain).compact
      app_count = App.count
      
      error_msg = "ArticleSetting not found. Tried: #{attempted_lookups.join(', ')}. "
      if existing_subdomains.any? || existing_domains.any?
        error_msg += "Existing ArticleSettings - subdomains: #{existing_subdomains.join(', ')}, domains: #{existing_domains.join(', ')}. "
      end
      error_msg += "Apps in database: #{app_count}. "
      error_msg += "Please create an ArticleSetting record with subdomain matching: #{subdomains.first || host} or domain matching: #{host}"
      
      raise ActiveRecord::RecordNotFound, error_msg
    end
    
    @app = article_setting.app
    key = @app.encryption_key
    @sessionless = params[:sessionless]

    @h = {
      http: Rails.env.production? ? "https://" : "http://",
      ws: Rails.env.production? ? "wss://" : "ws://"
    }

    @json_payload = {
      domain: @h[:http] + request.env["HTTP_HOST"],
      ws: Rails.application.config.action_cable.url,
      app_id: @app.key.to_s
    }
    @json_payload = @json_payload.to_json
    @encrypted_data = JWE.encrypt(@json_payload, key, alg: "dir")
  end
end
