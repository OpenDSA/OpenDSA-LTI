class EpgBroker::TokensController < ApplicationController
  def get_tokens
    # Request the EPG broker for available tokens based on the user
    

    tokens = [
      { id: 1, name: "example_token", value: 24, description: "This is an example token", quantity: 1 },
      { id: 2, name: "example_token_2", value: 12, description: "This is another example token", quantity: 2 }
    ]
    
    render json: { status: "success", data: tokens, message: "Tokens fetched successfully" }, status: :ok
  rescue => e
    render json: { status: "error", message: e.message }, status: :internal_server_error
  end

  def redeem_token
    token = params[:token] 
    if token == "example_token"
      render json: { status: "success", message: "Token redeemed successfully" }, status: :ok
    else
      render json: { status: "error", message: "Invalid token" }, status: :unprocessable_entity
    end
  rescue => e
    render json: { status: "error", message: e.message }, status: :internal_server_error
  end
end
