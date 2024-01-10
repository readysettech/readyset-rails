require 'spec_helper'

RSpec.describe Readyset::Utils::WindowCounter do
  describe '#log' do
    it 'removes existing times that are outside of the window' do
      window_counter = build_window_counter
      window_counter.log
      future_time = Time.now + time_period

      Timecop.freeze(future_time) do
        window_counter.log
      end

      expect(window_counter.send(:times)).to eq([future_time])
    end

    it 'logs a new time to the running window of times' do
      window_counter = build_window_counter
      time = Time.now

      Timecop.freeze(time) do
        window_counter.log
      end

      expect(window_counter.send(:times)).to eq([time])
    end
  end

  describe '#threshold_crossed?' do
    it 'removes existing times that are outside of the window' do
      window_counter = build_window_counter
      window_counter.log
      future_time = Time.now + time_period

      Timecop.freeze(future_time) do
        window_counter.threshold_crossed?
      end

      expect(window_counter.size).to eq(0)
    end

    context 'when the number of times logged in the given time period exceeds the window size' do
      it 'returns true' do
        window_counter = build_window_counter
        (window_size + 1).times { window_counter.log }

        Timecop.freeze do
          window_counter.threshold_crossed?

          expect(window_counter.threshold_crossed?).to eq(true)
        end
      end
    end

    context 'when the number of times logged in the given time period does not exceed the ' \
        'window size' do
      it 'returns false' do
        window_counter = build_window_counter
        window_size.times { window_counter.log }

        window_counter.threshold_crossed?

        expect(window_counter.threshold_crossed?).to eq(false)
      end
    end
  end

  def build_window_counter
    Readyset::Utils::WindowCounter.new(window_size: window_size, time_period: time_period)
  end

  def time_period
    1.minute
  end

  def window_size
    3
  end
end
