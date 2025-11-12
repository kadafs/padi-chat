# frozen_string_literal: true

class WidgetTheme < ApplicationRecord
  belongs_to :app

  validates :name, presence: true

  scope :active, -> { where(is_active: true) }
  scope :default, -> { where(is_default: true) }

  # Tidio-like widget customization
  def apply_to_widget
    theme_config || {}
  end

  def set_as_default!
    # Unset other default themes
    app.widget_themes.where.not(id: id).update_all(is_default: false)
    
    # Set this as default
    update!(is_default: true, is_active: true)
  end

  def duplicate!
    dup.tap do |new_theme|
      new_theme.name = "#{name} (Copy)"
      new_theme.is_default = false
      new_theme.is_active = false
      new_theme.theme_config = theme_config.deep_dup
      new_theme.save!
    end
  end
end


