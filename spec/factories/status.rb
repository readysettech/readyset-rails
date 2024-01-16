FactoryBot.define do
  factory :status, class: 'Readyset::Status' do
    connection_count { 5 }
    database_connection_status { :connected }
    last_completed_snapshot { Time.parse('2023-11-22 16:40:34') }
    last_replicator_error { 'test error' }
    last_started_controller { Time.parse('2023-11-22 16:40:34') }
    last_started_replication { Time.parse('2023-11-22 16:40:34') }
    maximum_replication_offset { '(0/33ED51B8, 0/33ED51E8)' }
    minimum_replication_offset { '(0/33ED51B8, 0/33ED51E8)' }
    controller_status { 'test status' }
    snapshot_status { :snapshotted }

    initialize_with { new(**attributes) }
  end
end
