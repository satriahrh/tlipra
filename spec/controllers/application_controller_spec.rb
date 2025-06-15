require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  # Create a test controller that inherits from ApplicationController
  controller do
    def index
      render json: { user_id: @user.id, message: "Success" }
    end
  end

  let(:user) { create(:user) }

  describe "#set_user" do
    context "when Authorization header is present and user exists" do
      it "sets @user and allows the action to proceed" do
        request.headers["Authorization"] = user.id.to_s

        get :index

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["user_id"]).to eq(user.id)
        expect(json_response["message"]).to eq("Success")
      end
    end

    context "when Authorization header is missing" do
      it "returns unauthorized error" do
        get :index

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("User ID required")
      end
    end

    context "when Authorization header is blank" do
      it "returns unauthorized error" do
        request.headers["Authorization"] = ""

        get :index

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("User ID required")
      end
    end

    context "when Authorization header contains whitespace only" do
      it "returns unauthorized error" do
        request.headers["Authorization"] = "   "

        get :index

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("User ID required")
      end
    end

    context "when user does not exist" do
      it "returns not found error" do
        request.headers["Authorization"] = "999999"

        get :index

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("User not found")
      end
    end

    context "when Authorization header contains invalid user ID" do
      it "returns not found error" do
        request.headers["Authorization"] = "invalid_id"

        get :index

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("User not found")
      end
    end
  end
end
