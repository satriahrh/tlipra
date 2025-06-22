# Good Night

This application is a backend service for a sleep tracking social application. Users can record their sleep, follow other users, and view a feed of their friends' sleep records from the past week.

## Features Summary

-   Record clock-in (going to bed) and clock-out (waking up) times.
-   View all personal sleep records, ordered by creation date.
-   Follow and unfollow other users.
-   View a feed of sleep records from all followed users from the previous week, sorted by sleep duration.

## Overall Architecture

This application is built with **Ruby on Rails**, following a conventional project structure. It uses **MySQL** as its database.

Key architectural patterns include:

-   **Service Objects**: Business logic is encapsulated within service objects (e.g., `GetSleepRecordsFeedsService`) to keep controllers thin and models focused on data persistence.
-   **Database Partitioning**: The `sleep_records` table is partitioned by clock_in_at (range type partition) to ensure query performance remains high as the data volume grows.
-   **API-only**: This is a JSON API backend, with no server-side rendered views.

## API Documentation (Swagger)

The API is documented using Swagger/OpenAPI. Once the application is running, the interactive documentation can be accessed at:

`http://localhost:3000/api-docs`

## How to Run

This guide provides instructions for setting up and running the application in a local development environment.

### Prerequisites

-   **Ruby**: Version `3.4.1` (It is recommended to use a version manager like `rbenv` or `rvm`).
-   **Bundler**: The Ruby dependency manager.
-   **MySQL 8.0**: The database for the application.

### Setup Instructions

1.  **Clone the Repository**
    ```sh
    git clone https://github.com/satriahrh/tlipra.git
    cd tlipra
    ```
    *(Note: You may need to update the repository URL.)*

2.  **Install Dependencies**
    Install the required gems using Bundler:
    ```sh
    bundle install
    ```

3.  **Configure the Database**
    The application is configured to connect to a local MySQL server. The default settings in `config/database.yml` expect a user `root` with the password `rootpw`.

    If your local MySQL installation uses different credentials, please update the `development` section of `config/database.yml`.

4.  **Create and Migrate the Database**
    Run the following Rails commands to create the database, apply the schema, and populate it with seed data:
    ```sh
    bundle exec rails db:create
    bundle exec rails db:migrate
    bundle exec rails db:seed
    ```

5.  **Run the Maintenance Task**
    The application uses database partitioning, which requires a maintenance task to be run to create the necessary partitions for the current week.
    ```sh
    bundle exec rake partitions:maintain_sleep_records_partitions
    ```

6.  **Start the Rails Server**
    You can now start the application:
    ```sh
    bundle exec rails server
    ```
    The application will be available at http://localhost:3000. For convenient purpose, we can also access swagger ui through http://localhost:3000/api-docs/index.html.

## Architecture Decision Records (ADRs)

*This section will document the key architectural decisions made during the project's development, including the reasoning and trade-offs considered.*

### ADR-001: Database Partitioning for Sleep Records

- **Status**: Active
- **Date**: 2025-06-22 (recapped)

#### Context

The application is expected to handle a large and growing volume of `sleep_records`. The core feature is a feed of friends' sleep data from the previous week. This query will be frequent and must remain fast even as the total number of records grows into the millions or billions. A standard B-tree index on `clock_in_at` would become less efficient over time as the table size increases.

#### Decision

We decided to implement **database partitioning** on the `sleep_records` table using the `clock_in_at` timestamp. Specifically, we use **RANGE partitioning by week** in MySQL.

The implementation consists of two parts:
1.  **Initial Migration**: A database migration alters the `sleep_records` table to enable partitioning. This involves modifying the primary key to include the partitioning key (`clock_in_at`), as required by MySQL.
2.  **Maintenance Rake Task**: A Rake task, `partitions:maintain_sleep_records_partitions`, is responsible for creating and maintaining the partitions. It can be run on a schedule (e.g., weekly) to create partitions for upcoming weeks, ensuring new data is always written to an appropriate partition. It does this by intelligently splitting the final `p_max` (catch-all) partition, which is an efficient, non-locking operation.

#### Consequences

**Positive:**
-   **Improved Query Performance**: Queries that filter by `clock_in_at` (like the main feed) will benefit from **partition pruning**. The database engine can directly access the relevant weekly partition(s) instead of scanning the entire table or a large index, leading to significantly faster response times.
-   **Scalability**: This approach provides a clear path to scaling the data layer as the user base grows.

**Negative:**
-   **Increased Complexity**: The database schema and application logic are now more complex. Developers need to be aware of the partitioning scheme. The `PRIMARY KEY` of the `sleep_records` table was changed to `(id, clock_in_at)`, which is a notable change from Rails conventions. [Subject for further TEST]
-   **Maintenance Overhead**: A recurring task must be set up and monitored to ensure new partitions are created ahead of time. If this task fails, new records might all fall into unexpected partition, worst case the data will be scattered all over partitions.

---

## Project Journal

### Original Requirements & Assumptions

#### Explicit requirements
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

#### Given Assumption
1. User only have id and name
2. No need to implement user registration API
3. Use any ruby gems

#### Our Assumptions
1. Simplified model, we will directly use aggregated table with simple schema
2. API Design simplification, to limit the number of API
3. API Security simplification, passing user id in Authorization shall be suffice. We can try to implement proper security later.
4. Use MySql, because we are more familiar with among rails's db pairing.
5. Testing strategy that we are aware of in Rails. We are targetting for must and secondary items.
   - [must] unit test in model or small package
   - [must] unit test in business logic, mainly in service layer
   - [secondary] integration test in the controller
   - [optional] end to end test

### Planned timeline

- Day 1: Understand and planning
- Day 2: Models, migrations, clock in/out API and follow/unfollow API
- Day 3-5: Sleep records API, business logic, expect adjustment on model due to indexing
- Day 6: Completing testing, clean code, performance check up
- Day 7: Documentation, final polish

### Development Log

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

- June 15, 2025
   - Sleep tracking API, complete
   - Init to add swagger
   - Provide simple code cov

- June 17 - 18, 2025
   - Refactor follow / unfollow model for implementation in controller
   - Followership API

- June 19, 2025
   - Expose rspec in CI
   - Feeds API
   - Adding database indexing for direct improvement on Feeds API

- June 20 to 22, 2025
   - Database partitioning
   - API Clock in history
   - Swaggerize
   - Documentation for submission
