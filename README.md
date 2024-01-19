# ReadySet Rails

A gem for caching with [ReadySet](https://readyset.io) within Rails applications.

[![Build status](https://badge.buildkite.com/76e02771ab1f0706b7840f47c5fed0e315a56c408d86c0de8c.svg?branch=main)](https://buildkite.com/readyset/readyset-public)
[![Build status](https://github.com/readysettech/readyset-rails/actions/workflows/rspec.yml/badge.svg)]
[![Number of GitHub issues that are open](https://img.shields.io/github/issues/readysettech/readyset-rails)](https://github.com/readysettech/readyset-rails/issues)
![Number of GitHub closed issues](https://img.shields.io/github/issues-closed/readysettech/readyset-rails)
![Number of GitHub pull requests that are open](https://img.shields.io/github/issues-pr-raw/readysettech/readyset-rails)
![GitHub release; latest by date](https://img.shields.io/github/v/release/readysettech/readyset-rails)
[![Slack](https://img.shields.io/badge/Join%20Slack-gray?logo=slack&logoColor=white)](https://join.slack.com/t/readysetcommunity/shared_invite/zt-2272gtiz4-0024xeRJUPGWlRETQrGkFw)
[![Follow us on X, formerly Twitter](https://img.shields.io/twitter/follow/ReadySet?style=social)](https://twitter.com/readysetio)

:star: If you find this gem useful, please consider giving us a star on GitHub! Your support helps us continue to innovate and deliver exciting new features.

## Table of Contents
- [What is ReadySet?](#what-is-readyset)
- [What does this gem do?](#what-does-this-gem-do)
- [Installing](#installing)
- [Quickstart](#quickstart)
- [Usage](#usage)
    - [Getting Started with Caching](#getting-started-with-caching)
        - [Query Routing in Controllers](#query-routing-in-controllers)
        - [Query Routing in Models](#query-routing-in-models)
    - [Cache Migrations](#cache-migrations)
    - [Automatic Failover](#automatic-failover)
- [Configuration Options](#configuration-options)
- [License](#license)

## What is ReadySet?

[ReadySet](https://readyset.io) is a database acceleration engine that acts as
a read replica and implements a novel type of query caching that automatically 
keeps your caches up-to-date by watching your database's replication stream.
ReadySet helps you scale your database by shedding load and reducing query
latency.

## What does this gem do?

This gem makes it easy to use ReadySet from within your Rails application by
allowing you to selectively route queries to ReadySet. The high-level features
of this gem include:

- A `Readyset.route` method that takes a block and routes to ReadySet any
  queries within that block
- A controller extension that allows you to route to ReadySet all queries
  that occur within specific controller actions
- A model extension that allows you to define queries to be routed to ReadySet
  within the context of an existing model
- Rake tasks that allow you to easily manage cache migration on ReadySet,
  ensuring that a consistent set of caches exists across all of your
  environments
- Automatic failover back to your primary database in the event that your
  ReadySet instance is unreachable (disabled by default)

**Note that ReadySet only guarantees support for PostgreSQL right now, so this
gem only supports PostgreSQL.**

## Installing

If you run into any trouble with the below steps, please feel free to reach
out via our [community Slack](https://join.slack.com/t/readysetcommunity/shared_invite/zt-2272gtiz4-0024xeRJUPGWlRETQrGkFw)!

1. Follow the instructions [here](https://docs.readyset.io/get-started/install-rs/postgres)
   to install and run ReadySet
2. Add the following line to your Gemfile and run `bundle install`:
   ```sh
   gem 'readyset'
   ```
   The ReadySet Rails gem currenly supports Ruby versions >= 3.0 and Rails
   versions >= 6.1.
3. Add a section to your `config/database.yml` file with ReadySet's connection
   information. If you currently connect to only one database, you'll need to
   move your primary database connection information to be nested under a new
   key named `primary`.
   ```yaml
   development:
     primary:
       # This is the connection information for your primary database
       database: testdb
       username: postgres
       password: readyset
       adapter: postgresql
       port: 5432
     readyset:
       # This is the connection information for ReadySet
       database: testdb
       username: postgres
       password: readyset
       adapter: readyset
       host: "127.0.0.1"
       port: 5433
   ```
4. Add the following line to your `ApplicationRecord` class:
   ```ruby
   connects_to shards: { readyset: { reading: :readyset, writing: :readyset } }
   ```
   You can verify that ReadySet is up and your application is connected by
   running `rails readyset:status`:
   ```sh
   $ rails readyset:status
   +----------------------------+------------------------+
   | Database Connection        | Connected              |
   | Connection Count           | 1                      |
   | Snapshot Status            | Completed              |
   | Maximum Replication Offset | (0/6DBBD78, 0/6DBBFF0) |
   | Minimum Replication Offset | (0/6DBBD78, 0/6DBBFF0) |
   | Last started Controller    | 2024-01-17 18:49:02    |
   | Last completed snapshot    | 2024-01-19 15:18:02    |
   | Last started replication   | 2024-01-19 15:18:02    |
   +----------------------------+------------------------+
   ```
   You can also view the tables that ReadySet knows about and their status by
   running `rails readyset:tables`:
   ```sh
   $ rails readyset:tables
   +---------------------------------+-------------+-------------+
   | table                           | status      | description |
   +---------------------------------+-------------+-------------+
   | "public"."posts"                | Snapshotted |             |
   +---------------------------------+-------------+-------------+
   ```
5. Run `Readyset.configure` wherever you configure other gems in your
   application, and set any desired configuration options:
   ```ruby
   Readyset.configure do |config|
     # Set your config options here
   end
   ```
   The list of available configuration options can be found
   [here](#configuration-options).

## Quickstart

1. Follow the instructions above to set up ReadySet and install the gem
2. Route a query to ReadySet in your application like so:
   ```ruby
   Readyset.route do
     Post.where(user_id: user_id)
   end
   ```
3. Start up your application and drive traffic through the part of your
   application that invokes the query you routed in the previous step
4. Validate that the query was routed to ReadySet by running
   `rails readyset:proxied_queries`. A "proxied" query is one that was served
   by ReadySet but was proxied to your primary database, since a cache for the
   query does not yet exist
   ```sh
   $ rails readyset:proxied_queries
   +--------------------+-------------------------------------------------------+-------------+-------+
   | id                 | text                                                  | supported   | count |
   +--------------------+-------------------------------------------------------+-------------+-------+
   | q_281c5f9b8e4013bb | SELECT                                                | yes         | 1     |
   |                    |   *                                                   |             |       |
   |                    | FROM                                                  |             |       |
   |                    |   "posts"                                             |             |       |
   |                    | WHERE                                                 |             |       |
   |                    |   ("user_id" = $1)                                    |             |       |
   +--------------------+-------------------------------------------------------+-------------+-------+
   ```
5. Create a cache for the query by running
   `rails readyset:proxied_queries:cache_all_supported`. This will create caches for
   all of the queries proxied by ReadySet that are supported to be cached. You
   can verify that the expected caches were created by running
   `rails readyset:caches`:
   ```sh
   $ rails readyset:caches
   +--------------------+--------------------+-------------------------------------+--------+-------+
   | id                 | name               | text                                | always | count |
   +--------------------+--------------------+-------------------------------------+--------+-------+
   | q_281c5f9b8e4013bb | q_281c5f9b8e4013bb | SELECT                              | false  | 0     |
   |                    |                    |   "public"."posts"."user_id"        |        |       |
   |                    |                    | FROM                                |        |       |
   |                    |                    |   "public"."posts"                  |        |       |
   |                    |                    | WHERE                               |        |       |
   |                    |                    |   ("public"."posts"."user_id" = $1) |        |       |
   +--------------------+--------------------+-------------------------------------+--------+-------+
   ```
6. Drive traffic through the part of your application that invokes your cached
   query. The first invocation of the query will be a cache miss, but the
   second will be served from the cache. You can verify that the cache was
   successfully used by looking at the `count` column in the output of
   `rails readyset:caches`:
   ```sh
   $ rails readyset:caches
   +--------------------+--------------------+-------------------------------------+--------+-------+
   | id                 | name               | text                                | always | count |
   +--------------------+--------------------+-------------------------------------+--------+-------+
   | q_281c5f9b8e4013bb | q_281c5f9b8e4013bb | SELECT                              | false  | 1     |
   |                    |                    |   "public"."posts"."user_id"        |        |       |
   |                    |                    | FROM                                |        |       |
   |                    |                    |   "public"."posts"                  |        |       |
   |                    |                    | WHERE                               |        |       |
   |                    |                    |   ("public"."posts"."user_id" = $1) |        |       |
   +--------------------+--------------------+-------------------------------------+--------+-------+
   ```

## Usage

### Getting Started with Caching

Queries in arbitrary code blocks can be routed to ReadySet using the
`Readyset.route` method like so:

```ruby
Readyset.route do
  Post.where(user_id: user_id)
end
```

Any queries invoked in the given block will be routed to the ReadySet instance
configured in your `config/database.yml` file; however, until a cache is created
for a particular query, invocations of that query against ReadySet will be proxied
to your database. To create a cache for a specific query, you have a few options:

- Invoke `.create_readyset_cache` directly on an ActiveRecord query in the
  Rails console:
  ```ruby
  Post.where(user_id: 1).create_readyset_cache!
  ```
- Create caches for all of the queries supported by ReadySet that ReadySet has
  seen and proxied to your database since it last started up using the provided
  Rake task:
  ```sh
  rails readyset:proxied_queries:cache_all_supported
  ```
  **Note:** If you route a query to ReadySet, decide you no longer want to cache
  that query, and stop routing that query to ReadySet, that query will still
  exist in ReadySet's list of queries that it has proxied to your database.
  This means that running the above Rake task will still create a cache for that
  query **even though it is no longer annotated to be routed to ReadySet in your
  application code**. The list of queries ReadySet has proxied can be cleared by
  restarting ReadySet or by running `rails readyset:proxied_queries:drop_all`.
- View the list of queries that ReadySet has proxied by running the following
  in a Rails console:
  ```ruby
  Readyset::Query::ProxiedQuery.all
  ```
  You can invoke `#cache!` on the queries in this list for which you'd like to
  create caches on ReadySet.
- View the list of queries that ReadySet has proxied *and* that are supported
  by ReadySet to be cached by running the following:
  ```sh
  rails readyset:proxied_queries:supported
  ```
  Pick a query from the list that you'd like to cache, and pass the ID to the
  `rails readyset:create_cache` command like so:
  ```sh
  rails readyset:create_cache[your_query_id]
  ```

Once a cache has been created for a particular query, it will persist on
ReadySet across restarts (although any in-memory cached data will be lost when
ReadySet goes down). You can view the list of existing caches using the provided
Rake task:
```sh
rails readyset:caches
```
To drop a given cache in the list printed by the above command, you can pass the
name of the cache to the `readyset:caches:drop` Rake task like so:
```sh
rails readyset:caches:drop[my_cache]
```
You can also view the list of existing caches in an interactive form via the
Rails console:
```ruby
Readyset::Query::CachedQuery.all
```
You can invoke `#drop!` on any of the caches in this list to remove the cache
from ReadySet.

#### Query Routing in Controllers

The gem includes an extension to `ActionController` that allows you to route to
ReadySet all of the queries that occur within the context of a given controller
action:
```ruby
class PostsController < ActionController
  route_to_readyset only: :show

  def show
    @post = Post.where(id: params[:id])
  end
end
```
`route_to_readyset` takes the same parameters as Rails's
[`around_filters`](https://guides.rubyonrails.org/action_controller_overview.html#after-filters-and-around-filters).

#### Query Routing in Models

The gem also includes an extension that allows you to define queries in your
model that will be routed to ReadySet:
```ruby
class Post < ApplicationRecord
    readyset_query :posts_for_user, ->(user_id) { where(user_id: user_id) }
end
```
The above example will define a `.posts_for_user` class method on the `Post`
model that invokes the query `Post.where(user_id: user_id)` against ReadySet.
**Note that other invocations of this query outside of the context of the
`.posts_for_user` method will not be routed to ReadySet.**

This feature allows you to specify which queries should be routed to ReadySet
in a centralized location and prevents the need to use `Readyset.route`
everywhere a cached query is invoked.

### Cache Migrations

Once you have a set of caches you are happy with in your development
environment, you'll need a way to easily reproduce the same set of caches in
other environments (e.g. staging, production, etc.). To facilitate this, the
gem includes a "migration" feature, that allows you to dump the current set of
caches to a "migration file" and re-create these caches using the same
migration file.

The following Rake task dumps the current set of caches to the
`db/readyset_caches.rb` file:
```sh
rails readyset:caches:dump
```
This file should be checked into version control with your application code. To
update a ReadySet instance so that its set of caches matches the caches in your
migration file:
```sh
rails readyset:caches:migrate
```
This command 1) drops any caches that exist on ReadySet that are not present in
the migration file and 2) creates any caches that are present in the migration
file that do not exist on ReadySet. To run the command for a particular Rails
environment, you can set the `RAILS_ENV` environment variable.

### Automatic Failover

To handle situations where ReadySet is unreachable for any reason, the gem
includes an automatic failover feature. The gem tracks the number of ReadySet
connection failures over a configurable window of time, and if the number of
errors exceeds the configured threshold, any queries previously being routed to
ReadySet will be routed to the primary database. A background task is started up
that periodically attempts to establish a connection to ReadySet and check its
status. When the task confirms that ReadySet is available again, it allows
queries to be routed to ReadySet again.

This feature is disabled by default. To enable it, set the
`config.enable_failover` configuration option to `true`. You can read about the
other available configuration options [here](#configuration-options).

## Configuration Options

The gem's configuration options can be set by passing a block to
`Readyset.configure` and setting options on the yielded
`Readyset::Configuration` object. The available options are documented below.
The values below are the default values for each of the options.

```ruby
Readyset.configure do |config|
  # Whether the gem's automatic failover feature should be enabled.
  config.enable_failover = false
  # Sets the interval upon which the background task will check
  # ReadySet's availability after failover has occurred.
  config.failover_healthcheck_interval = 5.seconds
  # Sets the time window over which connection errors are counted
  # when determining whether failover should occur.
  config.failover_error_window_period = 1.minute
  # Sets the number of errors that must occur within the configured
  # error window period in order for failover to be triggered.
  config.failover_error_window_size = 10
  # The file in which cache migrations should be stored.
  config.migration_path = File.join(Rails.root, 'db/readyset_caches.rb')
end
```

## License

[MIT License](LICENSE)
