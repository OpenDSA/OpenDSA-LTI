require 'rails_helper'

RSpec.describe "EpgBroker::Tokens", type: :request do

  describe "GET /get_tokens" do
    it "returns http success" do
      get "/epg_broker/tokens/get_tokens"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /redeem_token" do
    it "returns http success" do
      get "/epg_broker/tokens/redeem_token"
      expect(response).to have_http_status(:success)
    end
  end

end
