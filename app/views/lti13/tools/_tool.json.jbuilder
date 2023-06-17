json.extract! tool, :id, :name, :client_id, :private_key, :deployment_id, :keyset_url, :created_at, :updated_at
json.url lti_tool_url(tool, format: :json)