require 'rails_helper'

RSpec.describe Api::SleepRecordsController, type: :controller do
  let(:user) { create(:user) }

  describe 'inheritance' do
    it 'inherits from ApplicationController' do
      expect(described_class.superclass).to eq(ApplicationController)
    end
  end

  describe 'POST #create' do
    context 'when action_type is clock_in' do
      context 'when user has no active sleep record' do
        it 'clocks in the user' do
          request.headers['Authorization'] = user.id.to_s

          expect do
            post :create, params: { action_type: 'clock_in' }
          end.to change(SleepRecord, :count).by(1)

          expect(response).to have_http_status(:created)

          sleep_record = SleepRecord.last
          json_response = JSON.parse(response.body)
          expect(json_response['action']).to eq('clock_in')
          expect(json_response['message']).to eq('Successfully clocked in')
          expect(json_response['data']['clock_in_at']).to be_present
          expect(json_response['data']['clock_out_at']).to be_nil
          expect(json_response['data']['user']['id']).to eq(user.id)
          expect(json_response['data']['user']['name']).to eq(user.name)
        end
      end

      context 'when user has an active sleep record' do
        let!(:active_record) { create(:sleep_record, :active, user: user) }

        it 'returns error' do
          request.headers['Authorization'] = user.id.to_s

          expect do
            post :create, params: { action_type: 'clock_in' }
          end.not_to change(SleepRecord, :count)

          expect(response).to have_http_status(:unprocessable_entity)

          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('User already has an active sleep record')
        end
      end
    end

    context 'when action_type is clock_out' do
      context 'when user has an active sleep record' do
        let!(:active_record) { create(:sleep_record, :active, user: user) }

        it 'clocks out the user' do
          request.headers['Authorization'] = user.id.to_s

          expect do
            post :create, params: { action_type: 'clock_out' }
          end.not_to change(SleepRecord, :count)

          expect(response).to have_http_status(:ok)

          json_response = JSON.parse(response.body)
          expect(json_response['action']).to eq('clock_out')
          expect(json_response['message']).to eq('Successfully clocked out')
          expect(json_response['data']['clock_out_at']).to be_present
          expect(json_response['data']['duration']).to be_present
        end
      end

      context 'when user has no active sleep record' do
        it 'returns error' do
          request.headers['Authorization'] = user.id.to_s

          expect do
            post :create, params: { action_type: 'clock_out' }
          end.not_to change(SleepRecord, :count)

          expect(response).to have_http_status(:unprocessable_entity)

          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('No active sleep record found')
        end
      end
    end

    context 'when action_type is invalid' do
      it 'returns bad request error' do
        request.headers['Authorization'] = user.id.to_s

        post :create, params: { action_type: 'invalid_action' }

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('action_type must be either \'clock_in\' or \'clock_out\'')
      end
    end

    context 'when action_type is missing' do
      it 'returns bad request error' do
        request.headers['Authorization'] = user.id.to_s

        post :create

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('action_type must be either \'clock_in\' or \'clock_out\'')
      end
    end

    context 'when user ID is not provided' do
      it 'returns unauthorized error' do
        post :create, params: { action_type: 'clock_in' }

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('User ID required')
      end
    end
  end

  describe 'sleep record JSON structure' do
    it 'includes all required fields' do
      request.headers['Authorization'] = user.id.to_s

      post :create, params: { action_type: 'clock_in' }

      json_response = JSON.parse(response.body)
      record_json = json_response['data']

      expect(record_json).to include(
        'id',
        'user',
        'clock_in_at',
        'clock_out_at',
        'duration',
        'created_at',
      )
    end
  end
end
