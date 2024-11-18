class EpgBroker::TokensController < ApplicationController
  require 'net/http'
  require 'uri'
  require 'json'
  
  # for testing purposes only
  JWT_SECRET = 'your_jwt_secret'
  EGP_BROKER_URL = 'http://host.docker.internal:3001/egp-broker-service'

  def generate_jwt_token(payload)
    token_payload = payload.merge(exp: Time.now.to_i + 3600) # Expires in 1 hour
    token = JWT.encode(payload, JWT_SECRET, 'HS256')
    return token
  end

  def get_tokens
    user_id = "67393490ddab8ff9922ee674"
    course_id = "6739348fddab8ff9922ee652"

    token = generate_jwt_token({ id: user_id })

    headers = {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json'
    }

    url = URI(EGP_BROKER_URL + '/api/tool_auth/get_freepasses')

    begin
      # Create an HTTP request
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https') # Enable SSL if the URL is HTTPS

      request = Net::HTTP::Post.new(url)
      headers.each { |key, value| request[key] = value }

      # Add request body
      request.body = { userId: user_id, courseId: course_id }.to_json

      # Execute the request
      response = http.request(request)

      # Parse and return response
      if response.is_a?(Net::HTTPSuccess)
        response_data = { 
          status: "success", 
          data: JSON.parse(response.body), 
          message: "Tokens fetched successfully" 
        }
      else
        response_data = { 
          status: "error", 
          message: response.body 
        }
      end

      # If called from controller action, render response
      if @_response
        render json: response_data, status: response.is_a?(Net::HTTPSuccess) ? :ok : response.code.to_i
      else
        # If called from console, return data
        return response_data
      end

    rescue StandardError => e
      error_data = { 
        status: "error", 
        message: e.message 
      }
      
      if @_response
        render json: error_data, status: :internal_server_error
      else
        return error_data
      end
    end
  end
  
  def redeem_token

    token_id = params[:token_id]
    inst_chapter_module_id = params[:inst_chapter_module_id]
    user_id = params[:user_id]

    Rails.logger.info "Token ID: #{token_id}"
    Rails.logger.info "Inst Chapter Module ID: #{inst_chapter_module_id}"
    Rails.logger.info "User ID: #{user_id}"

    inst_chapter_module = InstChapterModule.find(inst_chapter_module_id)
    Rails.logger.info "InstChapterModule: #{inst_chapter_module.inspect}"

    new_due_date = inst_chapter_module.due_date + 24.hours
    new_close_date = inst_chapter_module.close_date + 24.hours

    StudentExtension.create_or_update!(
      user_id,
      inst_chapter_module,
      {
        'due_date' => new_due_date.to_i,
        'close_date' => new_close_date.to_i
      }
    )

    # Rails.logger.info "New due date: #{new_due_date}"
    # Rails.logger.info "New close date: #{new_close_date}"

    # render json: { status: "success", message: "Token redeemed successfully" }, status: :ok
    return inst_chapter_module.inspect
  end
  
  def redeem_token2()
    # canvas
    inst_chapter_module_id = 1
    # broker
    token_id = "67393490ddab8ff9922ee6be"
    # for onw broker, but should match canvas
    user_id = "67393490ddab8ff9922ee674"
    # course_id = "6739348fddab8ff9922ee652"
    
    # Validate parameters
    unless token_id && inst_chapter_module_id
      render json: { status: "error", message: "Missing required parameters" }, status: :bad_request
      return
    end

    # Request the EPG broker to redeem the token and get extension value
    # token = generate_jwt_token({ id: user_id })
    # headers = {
    #   'Authorization' => "Bearer #{token}",
    #   'Content-Type' => 'application/json'
    # }

    # url = URI(EGP_BROKER_URL + '/api/tool_auth/redeem_freepass')

    # begin
    #   http = Net::HTTP.new(url.host, url.port)
    #   http.use_ssl = (url.scheme == 'https') # Enable SSL if the URL is HTTPS

    #   request = Net::HTTP::Post.new(url)
    #   headers.each { |key, value| request[key] = value }
    #   request.body = { userId: user_id, courseId: course_id, token: token_id }.to_json

    #   response = http.request(request)

    #   if response.is_a?(Net::HTTPSuccess)
    #     response_data = {
    #       status: "success",
    #       data: JSON.parse(response.body),
    #       message: "Token redeemed successfully"
    #     }
    #     # Check if the response contains the expected extension value
    #     response_body = JSON.parse(response.body)
    #     if response_body["extension"].nil?
    #       response_data = {
    #         status: "error", 
    #         message: "Missing extension value in response"
    #       }
    #       return render json: response_data, status: :unprocessable_entity
    #     end


      
    #   else
    #     response_data = {
    #       status: "error",
    #       message: response.body
    #     }
    #   end

    #   render json: response_data, status: response.is_a?(Net::HTTPSuccess) ? :ok : response.code.to_i

    # rescue StandardError => e
    #   render json: { status: "error", message: e.message }, status: :internal_server_error
    
    # end

    
    inst_chapter_module = InstChapterModule.find(inst_chapter_module_id)
    
    # Calculate new dates based on token value (assuming 24 hours extension)
    new_due_date = inst_chapter_module.due_date + 24.hours
    new_close_date = inst_chapter_module.close_date + 24.hours
    
    # Create or update student extension
    begin
      StudentExtension.create_or_update!(
        current_user,
        inst_chapter_module,
        {
          'due_date' => new_due_date.to_i,
          'close_date' => new_close_date.to_i
        }
      )
      
      render json: { 
        status: "success", 
        message: "Token redeemed successfully",
        new_due_date: new_due_date,
        new_close_date: new_close_date
        }, status: :ok
      rescue => e
        render json: { status: "error", message: e.message }, status: :unprocessable_entity
      end
    end
  end
  
  def get_tokens_old
    # Request the EPG broker for available tokens based on the user
    get_tokens_test()
    tokens = [
      { id: 1, name: "example_token", value: 24, description: "This is an example token", quantity: 1 },
      { id: 2, name: "example_token_2", value: 12, description: "This is another example token", quantity: 2 }
    ]
    
    render json: { status: "success", data: tokens, message: "Tokens fetched successfully" }, status: :ok
  rescue => e
    render json: { status: "error", message: e.message }, status: :internal_server_error
  end