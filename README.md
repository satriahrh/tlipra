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

### ADR-002: Service Objects for Complex Business Logic

- **Status**: Active
- **Date**: 2025-06-23 (recap)

#### Context

In many applications, business logic that involves multiple steps or models can be difficult to place. If placed in a controller, the controller becomes "fat" and hard to test. If placed in a single model, the model can take on responsibilities beyond its core purpose, violating the Single Responsibility Principle.

This project requires a clear pattern for handling such complex logic, while not adding unnecessary layers for simple operations.

#### Decision

We decided to adopt the **Service Object** pattern for complex business logic that orchestrates multiple resources or steps. This pattern is applied selectively.

**1. The Complex Case: `Users::GetSleepRecordsFeedsService`**
The primary example is the user's friend-feed. This is not a simple query; it's a business process that must:
-   Complex query that requires special attention, even creating a partition to keep up with scalling data.
-   Calculate a specific time window (the previous week).

The implementation of Service Object on `Users::GetSleepRecordsFeedsService` is to demostrate, to keep the `SleepRecordsController` clean from non controller concern. The controller's job is simply to call the service (or something simple) and render its result.

**2. The Simple Case: `FollowershipsController` & `SleepRecordsController#clock_in_history`**
For straightforward CRUD operations, a Service Object would be overkill.
-   **Creating a Followership**: The `FollowershipsController` directly uses ActiveRecord methods (`@user.follow!`). The logic is a single step and fits well as a method on the `User` model.
-   **Clock-in History**: The `clock_in_history` action is a simple paginated query on the user's `sleep_records`. Simple and low concern sleep records query relation to current user.

This approach allows us to consider the pattern on a case-by-case basis. If the "clock-in history" feature were to evolve—for example, would become a strong candidate for being refactored into its own Service Object.

#### Consequences

**Positive:**
-   **Clear Separation of Concerns**: Controllers handle HTTP, models handle data, and services handle complex business processes.
-   **Enhanced Testability**: Complex logic is isolated in Plain Old Ruby Objects (POROs), making them easy to test in isolation, without needing to simulate a full web request.
-   **Avoids "Fat" Models/Controllers**: Prevents controllers and models from becoming bloated with logic that isn't their core responsibility.
-   **Pragmatic Application**: The pattern is only used where needed, avoiding unnecessary abstraction for simple cases.

**Negative:**
-   **More Files**: Can increase the number of files and directories in the `app` folder.
-   **Developer Discipline**: The team must be deliberate about when to introduce a Service Object versus when to use simpler patterns.

### ADR-003: User as the Root Domain Entity

- **Status**: Active
- **Date**: 2025-06-23 (recap)

#### Context

Every feature in the application revolves around a `User`. Users track their own sleep, follow other users, and view the activities of those they follow. A clear and central `User` model is therefore essential. For the scope of this project, complex features like authentication, profiles, and permissions are not required. The primary need is a simple, identifiable entity to serve as the anchor for all other data.

#### Decision

We decided to design the `User` model as the **root entity** of the domain, with the following characteristics:

1.  **Center of Associations**: All other major models have a direct `belongs_to` or `has_many` relationship with the `User` model. `SleepRecord`s belong to a user, and `Followership`s link two users together. This creates a clear and predictable data hierarchy.

2.  **Home for Core Actions**: User-centric business logic is implemented as instance methods directly on the `User` model. Actions that represent a core capability of a user, such as `follow!(other_user)` or `sleep_clock_in!`, are placed here. This decision was made because these are single-step operations that fundamentally belong to the user's behavior. This is in direct contrast to multi-step orchestration logic (like the feed generation), which is handled by Service Objects.

#### Consequences

**Positive:**
-   **High Cohesion**: Logic directly related to a user's capabilities is located with the user's data, making the system intuitive to understand and navigate.
-   **Reduced Boilerplate**: Avoids creating unnecessary Service Objects for simple, single-actor operations, which would add complexity without significant benefit.
-   **Clear Domain Model**: The central role of the `User` makes the overall application architecture easy to grasp.

**Negative:**
-   **Risk of "Fat Model"**: If many more complex, user-centric actions were added, the `User` model could become bloated. The team must remain disciplined about identifying when a piece of logic is complex enough to warrant being extracted into a Service Object.

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
