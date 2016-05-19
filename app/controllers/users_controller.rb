class UsersController < ApplicationController
  load_and_authorize_resource :find_by => :slug
  # before_action :authenticate_user!
  # after_action :verify_authorized

  def index
    @users = User.all
  end

  def show
    @user = User.friendly.find(params[:id])
    # authorize! @user
  end

  def edit
    @user = User.friendly.find(params[:id])
    # authorize! @user
  end

  def update
    @user = User.friendly.find(params[:id])
    # authorize! @user
    if @user.update_attributes(secure_params)
      redirect_to user_path(@user), :notice => "User updated."
    else
      redirect_to users_path, :alert => "Unable to update user."
    end
  end

  def destroy
    user = User.friendly.find(params[:id])
    # authorize! user
    user.destroy
    redirect_to users_path, :notice => "User deleted."
  end

  private

  def secure_params
    params.require(:user).permit(:role, :slug)

  end

end
