# frozen_string_literal: true

class GuestDownload < ApplicationRecord
  validates :remote_ip_address, :download_count, presence: true
end
