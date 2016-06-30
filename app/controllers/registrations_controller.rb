class RegistrationsController < Devise::RegistrationsController
  protected

  def after_sign_up_path_for(resource)
    # '/an/example/path' # Or :prefix_to_your_route
    "/users/#{current_user.id}/edit"
    # edit_user_path
  end
end