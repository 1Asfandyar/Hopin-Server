require "rails_helper"

RSpec.describe Group, type: :model do
  describe "kind" do
    it "does not allow changing kind after creation" do
      user = create(:user)
      group = user.friends_group

      group.kind = "custom"

      expect(group).not_to be_valid
      expect(group.errors[:kind]).to include("cannot be changed")
    end
  end
end
