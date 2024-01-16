# frozen_string_literal: true

RSpec.describe Readyset::Status do
  describe '.call' do
    it "returns Readyset's current status" do
      status = Readyset::Status.call

      expect(status.database_connection_status).to eq(:connected)
      expect(status.connection_count).to be_a(Integer)
      expect(status.snapshot_status).to eq(:completed)
      expect(status.minimum_replication_offset).
        to match(/\([0-9A-F]{1,8}\/[0-9A-F]{1,8}, [0-9A-F]{1,8}\/[0-9A-F]{1,8}\)/)
      expect(status.maximum_replication_offset).
        to match(/\([0-9A-F]{1,8}\/[0-9A-F]{1,8}, [0-9A-F]{1,8}\/[0-9A-F]{1,8}\)/)
      expect(status.last_started_controller).to be_a(Time)
      expect(status.last_started_replication).to be_a(Time)
      expect(status.last_completed_snapshot).to be_a(Time)
      expect(status.last_replicator_error).to be_nil
    end
  end

  describe '.new' do
    it "assigns the object's attributes correctly" do
      status = Readyset::Status.new(**attributes_for(:status))

      expect(status.connection_count).to eq(5)
      expect(status.database_connection_status).to eq(:connected)
      expect(status.last_completed_snapshot).to eq(Time.parse('2023-11-22 16:40:34'))
      expect(status.last_replicator_error).to eq('test error')
      expect(status.last_started_controller).to eq(Time.parse('2023-11-22 16:40:34'))
      expect(status.last_started_replication).to eq(Time.parse('2023-11-22 16:40:34'))
      expect(status.minimum_replication_offset).to eq('(0/33ED51B8, 0/33ED51E8)')
      expect(status.maximum_replication_offset).to eq('(0/33ED51B8, 0/33ED51E8)')
      expect(status.snapshot_status).to eq(:snapshotted)
    end
  end
end
