# spec/readyset-rails/logger_spec.rb

require 'spec_helper'
require_relative './../lib/ready_set/logger.rb'

RSpec.describe ReadySet::Logger do
  # Create a dummy class that includes the Logger module
  let(:logger) { Class.new { extend ReadySet::Logger } }

  describe '#setup_sql_comment_tag' do
    before do
      # Clear the tags to ensure a clean environment for each test
      ActiveRecord::QueryLogs.tags.clear
    end

    it 'sets up a tag for SQL comments' do
      # Call the method on an instance of the dummy class
      tag_name = :custom
      comment = 'source: example'
      logger.setup_sql_comment_tag(tag_name, comment)

      expect(ActiveRecord::QueryLogs.tags).to include(hash_including(tag_name => kind_of(Proc)))
    end

    context 'when the tag already exists' do
      before do
        tag_name = :custom
        comment = 'source: example'
        # Write a tag
        logger.setup_sql_comment_tag(tag_name, comment)
      end
      it 'does not add the tag again' do
        tag_name = :custom
        comment = 'source: example'

        repeat_tag = logger.setup_sql_comment_tag(tag_name, comment)
        expect { repeat_tag }.not_to change { ActiveRecord::QueryLogs.tags.count }
      end
    end
  end
end
