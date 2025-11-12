# frozen_string_literal: true

class ContactListMembership < ApplicationRecord
  belongs_to :contact_list
  belongs_to :app_user

  validates :app_user_id, uniqueness: { scope: :contact_list_id }

  scope :recent, -> { order(added_at: :desc) }
end


