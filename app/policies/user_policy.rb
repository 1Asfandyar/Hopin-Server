class UserPolicy
  attr_reader :current_user, :record

  def initialize(current_user, record)
    @current_user = current_user
    @record = record
  end

  def index?
    current_user.present?
  end

  def show?
    current_user.present?
  end

  def create?
    current_user.present?
  end

  def update?
    current_user.present?
  end

  def destroy?
    current_user.present?
  end
end
