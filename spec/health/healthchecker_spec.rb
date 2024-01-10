require 'spec_helper'

RSpec.describe Readyset::Health::Healthchecker do
  describe '.new' do
    it 'initializes the state of the system to be healthy' do
      healthchecker = build_healthchecker

      result = healthchecker.healthy?

      expect(result).to eq(true)
    end
  end

  describe '#healthy?' do
    context 'when the error threshold has not been crossed' do
      it 'returns true' do
        healthchecker = build_healthchecker
        (error_window_size + 1).times do
          healthchecker.process_exception(readyset_error)
          Timecop.travel(Time.now + 10.seconds)
        end

        result = healthchecker.healthy?

        expect(result).to eq(true)
      end
    end

    context 'when the error threshold has been crossed' do
      it 'returns false until the healthchecks are run again and then returns true' do
        interval = 0.05.seconds
        healthchecker = build_healthchecker(healthcheck_interval: interval)
        allow(healthchecker.send(:healthchecks)).to receive(:healthy?).and_return(true)
        (error_window_size + 1).times { healthchecker.process_exception(readyset_error) }

        first_result = healthchecker.healthy?
        sleep(interval * 2)
        second_result = healthchecker.healthy?

        expect(first_result).to eq(false)
        expect(second_result).to eq(true)
      end
    end
  end

  describe '#process_exception' do
    context 'when the error threshold has not been crossed' do
      it 'does not set the state of the healthchecker to be unhealthy' do
        healthchecker = setup

        error_window_size.times { healthchecker.process_exception(readyset_error) }

        result = healthchecker.healthy?
        expect(result).to eq(true)
      end

      it 'does not disconnect the ReadySet connection pool' do
        healthchecker = setup
        allow(readyset_pool).to receive(:disconnect!)

        error_window_size.times { healthchecker.process_exception(readyset_error) }

        expect(readyset_pool).not_to have_received(:disconnect!)
      end

      it 'does not execute the task' do
        healthchecker = setup

        error_window_size.times { healthchecker.process_exception(readyset_error) }

        expect(healthchecker.send(:task)).not_to have_received(:execute)
      end
    end

    context 'when the error threshold has been crossed' do
      it 'sets the state of the healthchecker to be unhealthy' do
        healthchecker = setup

        (error_window_size + 1).times { healthchecker.process_exception(readyset_error) }

        result = healthchecker.healthy?
        expect(result).to eq(false)
      end

      it 'disconnects the ReadySet connection pool' do
        healthchecker = setup
        allow(readyset_pool).to receive(:disconnect!)

        (error_window_size + 1).times { healthchecker.process_exception(readyset_error) }

        expect(readyset_pool).to have_received(:disconnect!)
      end

      it 'executes the task' do
        healthchecker = setup

        (error_window_size + 1).times { healthchecker.process_exception(readyset_error) }

        expect(healthchecker.send(:task)).to have_received(:execute)
      end

      it 'clears the window counter when the healthchecks indicate that ReadySet is healthy ' \
          'again' do
        interval = 0.05.seconds
        healthchecker = build_healthchecker(healthcheck_interval: interval)
        allow(healthchecker.send(:healthchecks)).to receive(:healthy?).and_return(true)

        (error_window_size + 1).times { healthchecker.process_exception(readyset_error) }
        sleep(interval * 2)

        expect(healthchecker.send(:window_counter).size).to eq(0)
      end
    end

    def readyset_pool
      ActiveRecord::Base.connected_to(shard: Readyset.config.shard) do
        ActiveRecord::Base.connection_pool
      end
    end

    def setup
      healthchecker = build_healthchecker
      allow(healthchecker.send(:task)).to receive(:execute)

      healthchecker
    end
  end

  private

  def build_healthchecker(healthcheck_interval: 5.seconds)
    Readyset::Health::Healthchecker.new(
      healthcheck_interval: healthcheck_interval,
      error_window_period: error_window_period,
      error_window_size: error_window_size,
      shard: :readyset
    )
  end

  def error_window_period
    30.seconds
  end

  def error_window_size
    3
  end

  def readyset_error
    @readyset_error ||= PG::ConnectionBad.new.tap do |error|
      error.singleton_class.instance_eval do
        include Readyset::Error
      end
    end
  end
end
