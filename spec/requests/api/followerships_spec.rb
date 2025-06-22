require 'swagger_helper'

RSpec.describe 'Followerships API', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:Authorization) { user.id }

  path '/api/users/{other_user_id}/follow' do
    post('Follow a user') do
      tags 'Followerships'
      description 'Follow another user.'
      produces 'application/json'
      security [ UserAuth: [] ]
      parameter name: :other_user_id, in: :path, type: :integer, required: true

      response(201, 'Successfully followed user') do
        let(:other_user_id) { other_user.id }
        schema '$ref' => '#/components/schemas/FollowershipResponse'
        run_test!
      end

      response(404, 'User not found') do
        let(:other_user_id) { 'invalid' }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end

      response(422, 'Cannot follow self') do
        let(:other_user_id) { user.id }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end
    end
  end

  path '/api/users/{other_user_id}/unfollow' do
    delete('Unfollow a user') do
      tags 'Followerships'
      description 'Unfollow another user.'
      produces 'application/json'
      security [ UserAuth: [] ]
      parameter name: :other_user_id, in: :path, type: :integer, required: true

      response(200, 'Successfully unfollowed user') do
        let(:other_user_id) { other_user.id }
        before { user.follow!(other_user) }
        schema '$ref' => '#/components/schemas/FollowershipResponse'
        run_test!
      end

      response(404, 'User not found') do
        let(:other_user_id) { 'invalid' }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end

      response(422, 'Not following user') do
        let(:other_user_id) { other_user.id }
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end
    end
  end
end
