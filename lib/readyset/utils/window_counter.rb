module Readyset
  module Utils
    # Keeps track of events that occur over time to see if the number of logged events exceeds a
    # preconfigured threshold in a preconfigured window of time. For example, if `window_size` is
    # 10 and `time_period` is 1 minute, the number of events logged in the last minute must exceed
    # 10 in order for `WindowCounter#threshold_crossed?` to return true.
    class WindowCounter
      def initialize(window_size: 10, time_period: 1.minute)
        @lock = Mutex.new
        @time_period = time_period
        @times = []
        @window_size = window_size
      end

      delegate :clear, to: :times

      # Logs a new event
      def log
        lock.synchronize do
          remove_times_out_of_threshold!
          times << Time.zone.now
        end

        nil
      end

      # Returns the current number of events logged in the configured `time_period`
      #
      # @return [Integer]
      def size
        lock.synchronize do
          remove_times_out_of_threshold!
          times.size
        end
      end

      # Returns true only if the number of events logged in the configured `time_period` has
      # exceeded the configured `window_size`.
      #
      # @return [Boolean]
      def threshold_crossed?
        lock.synchronize do
          remove_times_out_of_threshold!
          times.size > window_size
        end
      end

      private

      attr_reader :lock, :time_period, :times, :window_size

      def remove_times_out_of_threshold!
        times.select! { |time| time >= time_period.ago }
        nil
      end
    end
  end
end
