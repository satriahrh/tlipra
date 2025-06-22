require 'swagger_helper'

RSpec.describe 'Sleep Records API', type: :request do
  let(:user) { create(:user) }
  let(:Authorization) { user.id }

  path '/api/sleep_records' do
    post('Clock in or out') do
      tags 'Sleep Records'
      description 'Clock in or out for sleep tracking.'
      consumes 'application/json'
      produces 'application/json'
      security [UserAuth: []]
      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          action_type: { type: :string, enum: %w[clock_in clock_out] }
        },
        required: ['action_type']
      }

      response(201, 'Successfully clocked in') do
        let(:params) { { action_type: 'clock_in' } }
        schema '$ref' => '#/components/schemas/SleepRecordResponse'
        run_test!
      end

      response(200, 'Successfully clocked out') do
        let(:params) { { action_type: 'clock_out' } }
        before { create(:sleep_record, :active, user: user) }
        schema '$ref' => '#/components/schemas/SleepRecordResponse'
        run_test!
      end

      response(401, 'Unauthorized') do
        let(:Authorization) { nil }
        let(:params) { { action_type: 'clock_in' } }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end

      response(422, 'Already clocked in') do
        let(:params) { { action_type: 'clock_in' } }
        before { create(:sleep_record, :active, user: user) }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end

      response(422, 'No active sleep record') do
        let(:params) { { action_type: 'clock_out' } }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end
    end
  end

  path '/api/sleep_records/feeds' do
    get('Get sleep record feeds') do
      tags 'Sleep Records'
      description 'Get sleep record feeds from followed users (previous week).'
      produces 'application/json'
      security [UserAuth: []]
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number for pagination (default 1)'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Number of records per page (default 20)'

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/SleepRecordFeedResponse'
        run_test!
      end

      response(401, 'unauthorized') do
        let(:Authorization) { nil }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end
    end
  end

  path '/api/sleep_records/clock_in_history' do
    get('Get clock in history') do
      tags 'Sleep Records'
      description "Retrieve a paginated list of clock in timestamps for the authenticated user.\nRecords are ordered by creation date (newest first)."
      produces 'application/json'
      security [UserAuth: []]
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number for pagination (default 1)'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Number of records per page (default 20)'

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/ClockInHistoryResponse'
        run_test!
      end

      response(401, 'unauthorized') do
        let(:Authorization) { nil }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end
    end
  end
end 