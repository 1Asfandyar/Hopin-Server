require 'rails_helper'

RSpec.describe User, type: :model do
  describe "default friends group" do
    it "creates a friends group with the user as the only member after create" do
      user = create(:user)

      group = user.reload.friends_group

      expect(group).to be_friends
      expect(group.name).to eq("#{user.full_name}'s Friends")
      expect(group.description).to eq("Default group for all friends.")
      expect(group.users).to contain_exactly(user)
    end

    it "does not duplicate the friends group or membership when assignment runs again" do
      user = create(:user)

      expect { Groups::AssignDefaultFriendsGroup.call(user) }
        .not_to change { Group.friends.where(created_by: user).count }

      expect(user.reload.friends_group.users.where(id: user.id).count).to eq(1)
    end
  end

  describe "default categories" do
    it "assigns predefined categories after create" do
      user = create(:user)

      expect(user.categories.count).to eq(Categories::Defaults.all.size)
      expect(user.categories.pluck(:name)).to include("Groceries", "Salary", "Other")
    end

    it "does not duplicate defaults when assignment runs again" do
      user = create(:user)

      Categories::AssignDefaults.call(user)

      expect(user.categories.count).to eq(Categories::Defaults.all.size)
    end

    it "does not overwrite existing category metadata" do
      user = create(:user)
      category = user.categories.find_by!(name: "Groceries")
      category.update!(icon: "custom_icon", color: "#123456")

      Categories::AssignDefaults.call(user)

      expect(category.reload.icon).to eq("custom_icon")
      expect(category.color).to eq("#123456")
    end
  end
end
