# spec/readyset-rails/logger_spec.rb

require "spec_helper"
require_relative "./../lib/ready_set/logger.rb"

RSpec.describe ReadySet::Logger do
  let(:logger) { Class.new { prepend ReadySet::Logger } }
  let(:query) { "SELECT * FROM users" }

  describe ".setup_sql_comment_tag" do
    it "sets up a tag for SQL comments" do
      tag_name = :custom
      comment = "source: example"
      logger.setup_sql_comment_tag(tag_name, comment)

      expect(ActiveRecord::QueryLogs.tags).to include(hash_including(tag_name => kind_of(Proc)))
    end
  end
end
