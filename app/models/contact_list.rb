# frozen_string_literal: true

class ContactList < ApplicationRecord
  belongs_to :app
  has_many :contact_list_memberships, dependent: :destroy
  has_many :app_users, through: :contact_list_memberships

  validates :name, presence: true

  scope :dynamic, -> { where(is_dynamic: true) }
  scope :static, -> { where(is_dynamic: false) }

  # Tidio-like contact list management
  def update_members!
    return unless is_dynamic?

    # Clear existing memberships
    contact_list_memberships.destroy_all

    # Find matching contacts based on filter criteria
    matching_users = find_matching_users

    # Add matching contacts
    matching_users.each do |app_user|
      contact_list_memberships.create!(
        app_user: app_user,
        added_at: Time.current
      )
    end

    # Update contacts count
    update!(contacts_count: contact_list_memberships.count)
  end

  def add_contact(app_user)
    return if contact_list_memberships.exists?(app_user_id: app_user.id)

    contact_list_memberships.create!(
      app_user: app_user,
      added_at: Time.current
    )

    increment!(:contacts_count)
  end

  def remove_contact(app_user)
    membership = contact_list_memberships.find_by(app_user_id: app_user.id)
    return unless membership

    membership.destroy
    decrement!(:contacts_count)
  end

  private

  def find_matching_users
    query = app.app_users

    # Apply filter criteria
    if filter_criteria['tags']&.any?
      query = query.tagged_with(filter_criteria['tags'], any: true)
    end

    if filter_criteria['lifecycle_stage']
      query = query.where(lifecycle_stage: filter_criteria['lifecycle_stage'])
    end

    if filter_criteria['created_after']
      query = query.where('created_at >= ?', Date.parse(filter_criteria['created_after']))
    end

    if filter_criteria['created_before']
      query = query.where('created_at <= ?', Date.parse(filter_criteria['created_before']))
    end

    if filter_criteria['custom_attributes']&.any?
      filter_criteria['custom_attributes'].each do |key, value|
        query = query.where("custom_attributes->>? = ?", key, value.to_s)
      end
    end

    query
  end
end


