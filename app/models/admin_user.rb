class AdminUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :validatable

  validates :email, presence: true, uniqueness: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at email id updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
