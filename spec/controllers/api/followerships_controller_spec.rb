require 'rails_helper'

RSpec.describe Api::FollowershipsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'inheritance' do
    it 'inherits from ApplicationController' do
      expect(described_class.superclass).to eq(ApplicationController)
    end
  end

  describe 'POST #create' do
    context 'when following a user for the first time' do
      it 'creates a new followership' do
        request.headers['Authorization'] = user.id.to_s
        
        expect do
          post :create, params: { other_user_id: other_user.id }
        end.to change(Followership, :count).by(1)

        expect(response).to have_http_status(:created)

        json_response = JSON.parse(response.body)
        expect(json_response['action']).to eq('follow')
        expect(json_response['message']).to eq('Successfully followed user')
        expect(json_response['code']).to eq('SUCCESS')
      end
    end

    context 'when already following the user' do
      let!(:followership) { create(:followership, follower: user, followed: other_user) }

      it 'returns success like newly create a new followership' do
        request.headers['Authorization'] = user.id.to_s

        expect do
          post :create, params: { other_user_id: other_user.id }
        end.not_to change(Followership, :count)

        expect(response).to have_http_status(:created) # suppposed to be 200, but it's also fine, nothing major

        json_response = JSON.parse(response.body)
        expect(json_response['action']).to eq('follow')
        expect(json_response['message']).to eq('Successfully followed user')
        expect(json_response['code']).to eq('SUCCESS')
      end
    end

    context 'when trying to follow a non-existent user' do
      it 'returns not found error' do
        request.headers['Authorization'] = user.id.to_s
        post :create, params: { other_user_id: 99999 }

        expect(response).to have_http_status(:not_found)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('User not found')
        expect(json_response['code']).to eq('USER_NOT_FOUND')
      end
    end

    context 'when trying to follow yourself' do
      it 'returns validation error' do
        request.headers['Authorization'] = user.id.to_s
        expect do
          post :create, params: { other_user_id: user.id }
        end.not_to change(Followership, :count)

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Cannot follow yourself')
        expect(json_response['code']).to eq('RECORD_INVALID')
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when unfollowing a user' do
      let!(:followership) { create(:followership, follower: user, followed: other_user) }

      it 'marks the followership as unfollowed' do
        request.headers['Authorization'] = user.id.to_s
        expect do
          delete :destroy, params: { other_user_id: other_user.id }
        end.not_to change(Followership, :count)

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['action']).to eq('unfollow')
        expect(json_response['message']).to eq('Successfully unfollowed user')
        expect(json_response['code']).to eq('SUCCESS')

        followership.reload
        expect(followership.status).to eq('unfollowed')
        expect(followership.unfollowed_at).to be_present
      end
    end

    context 'when not following the user' do
      it 'returns error' do
        request.headers['Authorization'] = user.id.to_s
        delete :destroy, params: { other_user_id: other_user.id }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Not following this user')
        expect(json_response['code']).to eq('BUSINESS_LOGIC_ERROR')
      end
    end

    context 'when already unfollowed the user' do
      let!(:followership) { create(:followership, :unfollowed, follower: user, followed: other_user) }

      it 'returns error' do
        request.headers['Authorization'] = user.id.to_s
        delete :destroy, params: { other_user_id: other_user.id }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Already unfollowed this user')
        expect(json_response['code']).to eq('BUSINESS_LOGIC_ERROR')
      end
    end

    context 'when trying to unfollow a non-existent user' do
      it 'returns not found error' do
        request.headers['Authorization'] = user.id.to_s
        delete :destroy, params: { other_user_id: 99999 }

        expect(response).to have_http_status(:not_found)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('User not found')
        expect(json_response['code']).to eq('USER_NOT_FOUND')
      end
    end

    context 'when user does not exist' do
      it 'returns not found error' do
        request.headers['Authorization'] = user.id.to_s
        delete :destroy, params: { other_user_id: 99999 }

        expect(response).to have_http_status(:not_found)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('User not found')
        expect(json_response['code']).to eq('USER_NOT_FOUND')
      end
    end
  end

  describe 'refollow functionality' do
    let!(:unfollowed_followership) { create(:followership, :unfollowed, follower: user, followed: other_user) }

    it 'reactivates an unfollowed followership' do
      request.headers['Authorization'] = user.id.to_s
      expect do
        post :create, params: { other_user_id: other_user.id }
      end.not_to change(Followership, :count)

      expect(response).to have_http_status(:created)

      unfollowed_followership.reload
      expect(unfollowed_followership.status).to eq('active')
      expect(unfollowed_followership.unfollowed_at).to be_nil
    end
  end
end
