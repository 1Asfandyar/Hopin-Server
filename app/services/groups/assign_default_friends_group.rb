module Groups
  class AssignDefaultFriendsGroup
    DESCRIPTION = "Default Friend's Group".freeze

    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      Group.transaction do
        group = Group.find_or_initialize_by(created_by: user, kind: :friends)
        group.name = default_name if group.name.blank?
        group.description = DESCRIPTION if group.description.blank?
        group.save! if group.new_record? || group.changed?

        GroupsUser.find_or_create_by!(group: group, user: user)
        group
      end
    end

    private

    attr_reader :user

    def default_name
      owner_name = user.full_name.presence || user.email.presence || "My"
      "#{owner_name}'s Friends"
    end
  end
end
