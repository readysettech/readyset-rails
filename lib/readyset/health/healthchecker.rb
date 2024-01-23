require 'net/http'
require 'uri'

require 'readyset/health/healthchecks'

module Readyset
  module Health
    # Processes the given exceptions to determine whether ReadySet is currently unhealthy. If
    # ReadySet is indeed unhealthy, a background task is spawned that periodically checks
    # ReadySet's health directly until a healthy state has been restored. While ReadySet is in an
    # unhealthy state, `Healthchecker#healthy?` will return false.
    class Healthchecker
      UNHEALTHY_ERRORS = [::PG::UnableToSend, ::PG::ConnectionBad].freeze

      def initialize(config, shard:)
        @healthy = Concurrent::AtomicBoolean.new(true)
        @healthcheck_interval = config.healthcheck_interval!
        @healthchecks = Health::Healthchecks.new(shard: shard)
        @lock = Mutex.new
        @shard = shard
        @window_counter = Readyset::Utils::WindowCounter.new(
          window_size: config.error_window_size!,
          time_period: config.error_window_period!,
        )
      end

      # Returns true only if the connection to ReadySet is healthy. ReadySet's health is gauged by
      # keeping track of the number of connection errors that have occurred over a given time
      # period. If the number of errors in that time period exceeds the preconfigured threshold,
      # ReadySet is considered to be unhealthy.
      #
      # @return [Boolean] whether ReadySet is healthy
      def healthy?
        healthy.true?
      end

      # Checks if the given exception is a connection error that occurred on a ReadySet connection,
      # and if so, logs the error internally. If ReadySet is unhealthy, a background task is
      # spawned that periodically tries to connect to ReadySet and check its status. When this task
      # determines that ReadySet is healthy again, the task is shut down and the state of the
      # healthchecker is switched back to "healthy".
      #
      # @param [Exception] the exception to be processed
      def process_exception(exception)
        is_readyset_connection_error = is_readyset_connection_error?(exception)
        window_counter.log if is_readyset_connection_error

        # We lock here to ensure that only one thread starts the healthcheck task
        lock.lock
        if healthy.true? && window_counter.threshold_crossed?
          healthy.make_false
          lock.unlock

          logger.warn('ReadySet unhealthy: Routing queries to their original destination until ' \
            'ReadySet becomes healthy again')

          disconnect_readyset_pool!
          task.execute
        end
      ensure
        lock.unlock if lock.locked?
      end

      private

      attr_reader :healthcheck_interval, :healthchecks, :healthy, :lock, :shard, :window_counter

      def build_task
        @task ||= Concurrent::TimerTask.new(execution_interval: healthcheck_interval) do |t|
          if healthchecks.healthy?
            # We disconnect the ReadySet connection pool here to ensure that any pre-existing
            # connections to ReadySet are re-established. This fixes an issue where connections
            # return "PQsocket() can't get socket descriptor" errors even after ReadySet comes
            # back up. See this stackoverflow post for more details:
            # https://stackoverflow.com/q/36582380
            disconnect_readyset_pool!

            # We need to disconnect the pool before making `healthy` true to ensure that, once we
            # start routing queries back to ReadySet, they are using fresh connections
            lock.synchronize { healthy.make_true }

            logger.info('ReadySet healthy again')

            # We clear out the window counter here to ensure that errors from ReadySet's previous
            # unhealthy state don't bias the healthchecker towards determining that ReadySet is
            # unhealthy after only a small number of new errors
            window_counter.clear

            t.shutdown
          end
        end

        observer = Object.new.instance_eval do
          def update(_time, _result, e)
            logger.debug("ReadySet still unhealthy: #{e}") if e
          end
        end
        task.add_observer(observer)

        task
      end

      def disconnect_readyset_pool!
        ActiveRecord::Base.connected_to(shard: shard) do
          ActiveRecord::Base.connection_pool.disconnect!
        end
      end

      def is_readyset_connection_error?(exception)
        if exception.cause
          is_readyset_connection_error?(exception.cause)
        else
          UNHEALTHY_ERRORS.any? { |e| exception.is_a?(e) } &&
            exception.is_a?(Readyset::Error)
        end
      end

      def logger
        @logger ||= Rails.logger
      end

      def task
        @task ||= build_task
      end
    end
  end
end
