json.extract! launch, :id, :jwt, :decoded_jwt, :created_at, :updated_at
json.url lti_tool_launch_url(launch.tool_id, launch, format: :json)