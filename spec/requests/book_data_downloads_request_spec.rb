require 'rails_helper'

RSpec.describe "BookDataDownloads", type: :request do

  describe "GET /index" do
    it "returns http success" do
      get "/book_data_downloads/index"
      expect(response).to have_http_status(:success)
    end
  end

end
