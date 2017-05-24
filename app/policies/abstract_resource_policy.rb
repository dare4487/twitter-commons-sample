class AbstractResourcePolicy

  class Scope
    attr_reader :current_user, :scope

    def initialize(user, scope)
      @current_user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end

  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @model = model
  end

  def index?
    # @current_user.admin?
    true
  end

  def new?
    # @current_user.admin?
    true
  end

  def edit?
    # @current_user.admin?
    true
  end

  def show?
    # @current_user.admin? or @current_user == @user
    true
  end

  def create?
    # @current_user.admin?
    true
  end

  def update?
    # @current_user.admin?
    true
  end

  def destroy?
    # return false if @current_user == @user
    # @current_user.admin?
    true
  end

  def attach?
    true
  end

  def detach?
    true
  end

  def prefer?
    true
  end

  def defer?
    true
  end

  def activate?
    true
  end

  def deactivate?
    true
  end

end
