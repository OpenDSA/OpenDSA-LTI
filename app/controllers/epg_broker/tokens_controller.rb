class EpgBroker::TokensController < ApplicationController
  require 'net/http'
  require 'uri'
  require 'json'
  
  # for testing purposes only
  JWT_SECRET = 'secretkey'
  EGP_BROKER_URL = 'https://one-sunbeam-distinctly.ngrok-free.app'

  def generate_jwt_token(payload)
    token_payload = payload.merge(exp: Time.now.to_i + 3600) # Expires in 1 hour
    token = JWT.encode(payload, JWT_SECRET, 'HS256')
    return token
  end

  def get_tokens
    user_id = "stud001"
    course_id = "course001"

    token = generate_jwt_token({ id: user_id })

    headers = {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json'
    }

    url = URI(EGP_BROKER_URL + '/api/tool/student_passes')

    begin
      # Create an HTTP request
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https') # Enable SSL if the URL is HTTPS

      request = Net::HTTP::Post.new(url)
      headers.each { |key, value| request[key] = value }

      # Add request body
      request.body = { canvasStudentId: user_id, canvasCourseId: course_id, passType: "DURATION" }.to_json

      # Execute the request
      response = http.request(request)

      Rails.logger.info "Response Code: #{response.code}"
      Rails.logger.info "Response Body: #{response.body}"

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

    # body parameters
    # pass_id
    # studentCanvasID (custom_canvas_user_id in TP)
    # studentEmail (custom_canvas_user_email in TP)
    # courseCanvasID (custom_canvas_course_id in TP)
    # inst_chapter_module_id (custom_inst_chapter_module_id in TP)
    # assignmentCanvasID (this can be obtained from inst_chapter_module_id 
    #                      or custom_canvas_assignment_id)

    # pass_id = params[:pass_id]
    # inst_chapter_module_id = params[:inst_chapter_module_id]
    # studentCanvasID = params[:studentCanvasID]
    # studentEmail = params[:studentEmail]
    # canvasCourseID = params[:canvasCourseID]
    # canvasAssignmentID = params[:canvasAssignmentID]

    # dummy data
    pass_id = "67c89f9b1353a53eaf685cbd"
    inst_chapter_module_id = 17
    studentCanvasID = "stud001"
    studentEmail = "saketh@vt.edu"
    canvasCourseID = "course001"
    canvasAssignmentID = "assign001"

    Rails.logger.info "
      pass_id: #{pass_id},
      inst_chapter_module_id: #{inst_chapter_module_id},
      studentCanvasID: #{studentCanvasID},
      studentEmail: #{studentEmail},
      canvasCourseID: #{canvasCourseID},
      canvasAssignmentID: #{canvasAssignmentID}
    "

    # Validate parameters
    unless pass_id && inst_chapter_module_id && studentCanvasID && canvasCourseID && canvasAssignmentID
      render json: { status: "error", message: "Missing required parameters" }, status: :bad_request
      return
    end

    # Request the EPG broker to redeem the token and get extension value
    token = generate_jwt_token({ id: studentCanvasID })
    headers = {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json'
    }

    url = URI(EGP_BROKER_URL + '/api/tool/redeem_pass')

    begin
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https') # Enable SSL if the URL is HTTPS

      request = Net::HTTP::Post.new(url)
      headers.each { |key, value| request[key] = value }

      request.body = {
        passId: pass_id,
        canvasStudentId: studentCanvasID,
        canvasCourseId: canvasCourseID,
        canvasAssignmentId: canvasAssignmentID
      }.to_json

      response = http.request(request)
      if response.is_a?(Net::HTTPSuccess)
        response_body = JSON.parse(response.body)
        duration_hours = response_body["durationHours"]
        if duration_hours.nil?
          render json: { status: "error", message: "Missing durationHours in response" }, status: :unprocessable_entity
          return
        end

        # Find the InstChapterModule instance
        inst_chapter_module = InstChapterModule.find(inst_chapter_module_id)
        if inst_chapter_module.nil?
          render json: { status: "error", message: "Invalid inst_chapter_module_id" }, status: :unprocessable_entity
          return
        end

        # Find the student with email (use email because user canvas id is not stored in OpenDSA DB)
        student = User.find_by(email: studentEmail)
        if student.nil?
          render json: { status: "error", message: "Student not found (searched for student using email)" }, status: :unprocessable_entity
          return
        end

        # Calculate new dates based on durationHours
        new_due_date = inst_chapter_module.due_date + duration_hours.hours
        new_close_date = inst_chapter_module.close_date + duration_hours.hours

        # create or update a StudentExtension record
        extension = StudentExtension.find_or_create_by(inst_chapter_module_id: inst_chapter_module_id, user_id: student.id)
        extension.update(due_date: new_due_date, close_date: new_close_date)

        render json: { 
          status: "success", 
          message: "Token redeemed successfully",
          new_due_date: new_due_date,
          new_close_date: new_close_date
        }, status: :ok

      else
        Rails.logger.error "Error Response: #{response.body}"
        render json: { status: "error", message: response.body }, status: response.code.to_i
      end
    end

  end
  

end