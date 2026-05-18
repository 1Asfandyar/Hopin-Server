# == Schema Information
#
# Table name: groups
#
#  id            :bigint           not null, primary key
#  description   :text
#  name          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  created_by_id :bigint           not null
#  kind          :integer          default("custom"), not null
#
# Indexes
#
#  index_groups_on_created_by_id                   (created_by_id)
#  index_groups_on_created_by_id_and_friends_kind  (created_by_id,kind) UNIQUE WHERE (kind = 1)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#
class Group < ApplicationRecord
  enum :kind, { custom: 0, friends: 1 }

  validates :name, presence: true
  validates :kind, presence: true
  validates :created_by_id,
            uniqueness: { scope: :kind, message: "already has a friends group" },
            if: :friends?
  validate :kind_is_immutable, on: :update

  belongs_to :created_by, class_name: "User", inverse_of: :created_groups
  has_many :groups_users, dependent: :destroy
  has_many :users, through: :groups_users
  has_many :transactions

  private

  def kind_is_immutable
    errors.add(:kind, "cannot be changed") if will_save_change_to_kind?
  end
end
