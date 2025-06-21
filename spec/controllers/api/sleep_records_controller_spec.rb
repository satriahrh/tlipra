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

  describe 'GET #feeds' do
    let(:service_instance) { instance_double(Users::GetSleepRecordsFeedsService) }
    let(:service_result) do
      {
        records: [],
        total: 0,
        page: 1,
        per_page: 20
      }
    end

    before do
      request.headers['Authorization'] = user.id.to_s
      allow(Users::GetSleepRecordsFeedsService).to receive(:new).and_return(service_instance)
      allow(service_instance).to receive(:call).and_return(service_result)
    end

    it 'initializes the service with the correct user and params' do
      expect(Users::GetSleepRecordsFeedsService).to receive(:new).with(user, page: 1, per_page: 20).and_return(service_instance)
      get :feeds, params: { page: '1', per_page: '20' }
    end

    it 'calls the service' do
      expect(service_instance).to receive(:call)
      get :feeds
    end

    it 'returns a successful response' do
      get :feeds
      expect(response).to have_http_status(:ok)
    end

    it 'renders the JSON output from the service' do
      get :feeds
      json = JSON.parse(response.body)
      expect(json['total']).to eq(0)
      expect(json['page']).to eq(1)
      expect(json['per_page']).to eq(20)
    end

    context 'when page parameter is invalid' do
      it 'returns bad request for non-numeric page' do
        get :feeds, params: { page: 'abc' }
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('page must be a positive integer')
        expect(json['code']).to eq('INVALID_PARAMS')
      end

      it 'returns bad request for zero page' do
        get :feeds, params: { page: '0' }
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('page must be a positive integer')
        expect(json['code']).to eq('INVALID_PARAMS')
      end

      it 'returns bad request for negative page' do
        get :feeds, params: { page: '-1' }
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('page must be a positive integer')
        expect(json['code']).to eq('INVALID_PARAMS')
      end

      it 'returns bad request for decimal page' do
        get :feeds, params: { page: '1.5' }
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('page must be a positive integer')
        expect(json['code']).to eq('INVALID_PARAMS')
      end
    end

    context 'when per_page parameter is invalid' do
      it 'returns bad request for non-numeric per_page' do
        get :feeds, params: { per_page: 'abc' }
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('per_page must be a positive integer')
        expect(json['code']).to eq('INVALID_PARAMS')
      end

      it 'returns bad request for zero per_page' do
        get :feeds, params: { per_page: '0' }
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('per_page must be a positive integer')
        expect(json['code']).to eq('INVALID_PARAMS')
      end

      it 'returns bad request for negative per_page' do
        get :feeds, params: { per_page: '-1' }
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('per_page must be a positive integer')
        expect(json['code']).to eq('INVALID_PARAMS')
      end

      it 'returns bad request for decimal per_page' do
        get :feeds, params: { per_page: '10.5' }
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('per_page must be a positive integer')
        expect(json['code']).to eq('INVALID_PARAMS')
      end
    end

    context 'when parameters are valid' do
      it 'accepts valid positive integers' do
        expect(Users::GetSleepRecordsFeedsService).to receive(:new).with(user, page: 5, per_page: 15).and_return(service_instance)
        get :feeds, params: { page: '5', per_page: '15' }
        expect(response).to have_http_status(:ok)
      end

      it 'uses default values when parameters are not provided' do
        expect(Users::GetSleepRecordsFeedsService).to receive(:new).with(user, page: Users::GetSleepRecordsFeedsService::DEFAULT_PAGE, per_page: Users::GetSleepRecordsFeedsService::DEFAULT_PER_PAGE).and_return(service_instance)
        get :feeds
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the service raises an ArgumentError' do
      it 'returns a bad request response' do
        allow(service_instance).to receive(:call).and_raise(ArgumentError.new("Invalid parameters"))
        get :feeds
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq("Invalid parameters")
        expect(json['code']).to eq('INVALID_PARAMS')
      end
    end

    context 'when user is not authenticated' do
      it 'returns an unauthorized error' do
        request.headers['Authorization'] = nil
        get :feeds
        expect(response).to have_http_status(:unauthorized)
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

  describe 'GET #clock_in_history' do
    let!(:active_records) { create_list(:sleep_record, 25, user: user) }

    before do
      request.headers['Authorization'] = user.id.to_s
    end

    it 'returns the list sorted by most recent first (by id)' do
      get :clock_in_history
      json = JSON.parse(response.body)

      # The controller is sorting by id, so the order should be by creation
      expected_order = active_records.sort_by(&:id).reverse.map { |r| r.clock_in_at.iso8601(3) }
      response_data = json['data'].map { |t| Time.parse(t).iso8601(3) }
      expect(response_data.first).to eq(expected_order.first)
      expect(response_data.last).to eq(expected_order[response_data.length - 1])
    end

    context 'when user is not authenticated' do
      it 'returns an unauthorized error' do
        request.headers['Authorization'] = nil
        get :clock_in_history, params: { per_page: 10 }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when pagination is applied' do
      it 'returns the correct number of records' do
        get :clock_in_history, params: { per_page: 10 }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data'].size).to eq(10)
        expect(json['total']).to eq(25)
        expect(json['page']).to eq(1)
        expect(json['per_page']).to eq(10)
      end
    end
  end
end
