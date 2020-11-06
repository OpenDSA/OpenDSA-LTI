require 'rails_helper'

RSpec.describe "BookUsers", type: :request do

  describe "GET /index" do
    it "returns http success" do
      get "/book_users/index"
      expect(response).to have_http_status(:success)
    end
  end

end
