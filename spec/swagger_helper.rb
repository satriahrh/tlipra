# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that this folder exists and is accessible by the web server.
  config.swagger_root = Rails.root.join('public/docs').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the documentation defined here will
  # be generated.
  config.swagger_docs = {
    'swagger.yml' => {
      openapi: '3.0.1',
      info: {
        title: 'Good Night Sleep Tracking API',
        version: 'v1',
        description: 'API for tracking sleep patterns with follow/unfollow functionality.'
      },
      paths: {},
      servers: [
        {
          url: 'http://{defaultHost}',
          variables: {
            defaultHost: {
              default: '127.0.0.1:3000'
            }
          }
        }
      ],
      components: {
        securitySchemes: {
          UserAuth: {
            type: :apiKey,
            in: :header,
            name: 'Authorization'
          }
        },
        schemas: {
          ErrorResponse: {
            type: :object,
            properties: {
              error: { type: :string, example: 'An error message' },
              code: { type: :string, example: 'ERROR_CODE' }
            },
            required: %w[error code]
          },
          User: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              name: { type: :string, example: 'John Doe' }
            },
            required: %w[id name]
          },
          SleepRecord: {
            type: :object,
            properties: {
              user: { '$ref' => '#/components/schemas/User' },
              clock_in_at: { type: :string, format: 'date-time', example: '2025-01-15T22:00:00Z' },
              clock_out_at: { type: :string, format: 'date-time', nullable: true, example: '2025-01-16T06:00:00Z' },
              duration: { type: :integer, nullable: true, example: 28800 },
              created_at: { type: :string, format: 'date-time', example: '2025-01-15T22:00:00Z' }
            },
            required: %w[user clock_in_at created_at]
          },
          SleepRecordResponse: {
            type: :object,
            properties: {
              action: { type: :string, enum: %w[clock_in clock_out] },
              data: { '$ref' => '#/components/schemas/SleepRecord' },
              message: { type: :string },
              code: { type: :string, example: 'SUCCESS' }
            },
            required: %w[action data message code]
          },
          SleepRecordFeedResponse: {
            type: :object,
            properties: {
              data: { type: :array, items: { '$ref' => '#/components/schemas/SleepRecord' } },
              total: { type: :integer },
              page: { type: :integer },
              per_page: { type: :integer }
            },
            required: %w[data total page per_page]
          },
          ClockInHistoryResponse: {
            type: :object,
            properties: {
              data: { type: :array, items: { type: :string, format: 'date-time' } },
              total: { type: :integer },
              page: { type: :integer },
              per_page: { type: :integer }
            },
            required: %w[data total page per_page]
          },
          Followership: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              follower_id: { type: :integer, example: 123 },
              followed_id: { type: :integer, example: 456 },
              status: { type: :string, enum: %w[active unfollowed] },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[id follower_id followed_id status created_at updated_at]
          },
          FollowershipResponse: {
            type: :object,
            properties: {
              action: { type: :string, enum: %w[follow unfollow] },
              message: { type: :string },
              code: { type: :string, example: 'SUCCESS' }
            },
            required: %w[action message code]
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The swagger_docs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.swagger_format = :yaml
end 