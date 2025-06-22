require 'swagger_helper'

RSpec.describe 'Sleep Records API', type: :request do
  let(:user) { create(:user) }
  let(:Authorization) { user.id }

  path '/api/sleep_records/clock_in' do
    post('Clock in for sleep tracking') do
      tags 'Sleep Records'
      description 'Record a sleep clock-in event. Only one active sleep record per user is allowed.'
      consumes 'application/json'
      produces 'application/json'
      security [UserAuth: []]

      response(201, 'Successfully clocked in') do
        schema '$ref' => '#/components/schemas/SleepRecordResponse'
        run_test!
      end

      response(401, 'Unauthorized') do
        let(:Authorization) { nil }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end

      response(422, 'Already clocked in') do
        before { create(:sleep_record, :active, user: user) }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end
    end
  end

  path '/api/sleep_records/clock_out' do
    post('Clock out for sleep tracking') do
      tags 'Sleep Records'
      description 'Record a sleep clock-out event. The user must have an active sleep record.'
      consumes 'application/json'
      produces 'application/json'
      security [UserAuth: []]

      response(200, 'Successfully clocked out') do
        before { create(:sleep_record, :active, user: user) }
        schema '$ref' => '#/components/schemas/SleepRecordResponse'
        run_test!
      end

      response(401, 'Unauthorized') do
        let(:Authorization) { nil }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end

      response(422, 'No active sleep record') do
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
      security [ UserAuth: [] ]
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
      security [ UserAuth: [] ]
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
