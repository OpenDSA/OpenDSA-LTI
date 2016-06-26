class Api::V1::OdsaUserInteraction < Api::V1::BaseController

  private

    def odsa_user_interaction_params
      params.require(:user).permit(:name)
    end

    def odsa_user_interaction_params
      params.permit(:name)
    end

end

