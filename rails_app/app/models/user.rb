class User < ApplicationRecord
  has_encrypted :name
  has_encrypted :email
  has_encrypted :phone

  validates :name, :email, :phone, presence: true
end
