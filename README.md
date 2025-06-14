# Good Night

## Explicit requirements (in my language)

1. Build API using Ruby on Rails
2. API to record (clock in/out) when about to go bed and wake up.
3. API to return all clocked in times, ordered by created time.
4. API to follow and unfollow users.
5. API to see all sleep records of all users the are following.
   - From previous week only
   - Sorted by the duration of each sleep record across all followed users.
   - Shall be a flat list of records
6. Implement the model, database migrations, schema, and JSON API.
7. Write tests for the APIs.
8. Handle a growing user base, managing high data volumes and concurrent requests, efficiently
9. Document the strategy.

## Given Assumption

1. User only have id and name
2. No need to implement user registration API
3. Use any ruby gems

## Our Assumptions

1. Simplified model, we will directly use aggregated table with simple schema
2. API Design simplification, to limit the number of API
3. API Security simplification, passing user id in Authorization shall be suffice. We can try to implement proper security later.
4. Use MySql, because we are more familiar with among rails's db pairing.
5. Testing strategy that we are aware of in Rails. We are targetting for must and secondary items.
   - [must] unit test in model or small package
   - [must] unit test in business logic, mainly in service layer
   - [secondary] integration test in the controller
   - [optional] end to end test

## Planned timeline

- Day 1: Understand and planning
- Day 2: Models, migrations, clock in/out API and follow/unfollow API
- Day 3-5: Sleep records API, business logic, expect adjustment on model due to indexing
- Day 6: Completing testing, clean code, performance check up
- Day 7: Documentation, final polish

## API Spec

- **Clock In/Out**: Single endpoint that handles both operations (POST `/api/sleep-records`)
  - If no active record exists → clock in
  - If active record exists → clock out
- **Follow/Unfollow**: Simple toggle endpoint (POST `/api/follows`)
- **Sleep Record Feeds**: GET `/api/feeds?page=1&per_page=20`

## Development Log

- June 10, 2025
   - Project reading and recap on Ruby language and RoR
   - Started project setup and planning with 7-day development timeline

- June 11, 2025
   - Defined requirements for sleep tracking API with follow/unfollow functionality
   - Implemented User model with test coverage
   - Initiated implementation of Followership, might add test later, uncommited yet

- June 12, 2025
  - Continue working on followership model, complete test coverage

- June 13, 2025
   - Completed initial sleep record and its rspec
