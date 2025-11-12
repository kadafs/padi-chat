# frozen_string_literal: true

class SharedFile < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, polymorphic: true

  validates :file_name, presence: true

  scope :images, -> { where(is_image: true) }
  scope :documents, -> { where(is_document: true) }
  scope :recent, -> { order(created_at: :desc) }

  # Tidio-like file sharing
  def self.create_from_upload(conversation, sender, file_data)
    file_type = determine_file_type(file_data[:content_type] || file_data[:type])
    
    create!(
      conversation: conversation,
      sender: sender,
      file_name: file_data[:filename] || file_data[:name],
      file_type: file_type,
      file_size: file_data[:size],
      file_url: file_data[:url],
      thumbnail_url: file_data[:thumbnail_url],
      is_image: image?(file_type),
      is_document: document?(file_type),
      metadata: file_data[:metadata] || {}
    )
  end

  def file_size_formatted
    return '0 B' unless file_size

    units = ['B', 'KB', 'MB', 'GB']
    size = file_size.to_f
    unit_index = 0

    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end

    "#{size.round(2)} #{units[unit_index]}"
  end

  def image?
    is_image
  end

  def document?
    is_document
  end

  private

  def self.determine_file_type(content_type)
    return 'unknown' unless content_type

    case content_type
    when /^image\//
      'image'
    when /^application\/pdf/
      'pdf'
    when /^application\/.*word/
      'word'
    when /^application\/.*excel/
      'excel'
    when /^text\//
      'text'
    else
      'document'
    end
  end

  def self.image?(file_type)
    file_type == 'image'
  end

  def self.document?(file_type)
    %w[pdf word excel text document].include?(file_type)
  end
end


