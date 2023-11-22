# lib/ready_set/logger.rb

require "active_record"

module ReadySet
  module Logger
    extend ActiveSupport::Concern

    prepended do
      # Sets up a tag with dynamic content for SQL comments
      def self.setup_sql_comment_tag(tag_name, content)
        tag_proc = -> { content }
        ActiveRecord::QueryLogs.tags << { tag_name => tag_proc }
      end

      def self.remove_query_tag(tag)
        ActiveRecord::QueryLogs.tags.delete(tag)
      end
    end
  end
end
