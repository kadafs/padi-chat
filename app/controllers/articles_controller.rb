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
    # Try full subdomain first (e.g., "web-production-d051e.up")
    # Then try just the first subdomain (e.g., "web-production-d051e") for Railway domains
    article_setting = ArticleSetting.find_by(subdomain: subdomains.join(".")) ||
                      (subdomains.any? ? ArticleSetting.find_by(subdomain: subdomains.first) : nil)
    
    if article_setting.nil?
      attempted_subdomains = subdomains.any? ? [subdomains.join("."), subdomains.first].compact.uniq.join(", ") : "none"
      raise ActiveRecord::RecordNotFound, "ArticleSetting not found for subdomain(s): #{attempted_subdomains}"
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
