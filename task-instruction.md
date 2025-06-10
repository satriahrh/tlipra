We want to know how do you structure the code and design the API
Please use Rails for this project

==========================================

We would like you to implement a "good night" application to let users
track when they go to bed and when they wake up.
We require some restful APIS to achieve the following:
1. Clock In operation, and return all clocked-in times, ordered by
created time.
2. Users can follow and unfollow other users.
3. See the sleep records of a user's All following users' sleep
records. from the previous week, which are sorted based on the duration
of All friends sleep length.

This is 3rd requirement response example
{
record 1 from user A,
record 2 from user B,
record 3 from user A,
...
}

Please implement the model, database migrations, schema, and JSON API.
Additionally, write tests for the APIs.
Consider that the system must efficiently handle a growing user base,
managing high data volumes and concurrent requests. Document the
strategies used to achieve this.

You can assume that there are only two fields on the users "id" and
"name".
You do not need to implement any user registration API.
You can use any gems you like.

*Sometimes, requirements may not be entirely clear. In such cases,
please feel free to make reasonable assumptions and propose the best
solution based on your experience and judgment.

============================
After you finish the project, please send me your GitHub project link.
We want to see all of your development commits.
- It is important to have separate commits with clear descriptions for
each change.
- In Tripla, it is not a good practice to have one commit with a lot of
changes.

Please ensure that you have granted permission for Google Meet to share
your screen, as we may need you to do so during the meeting