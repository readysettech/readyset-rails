# lib/ready_set/logger.rb

require 'active_record'

module ReadySet
  module Logger
    extend ActiveSupport::Concern

    # Sets up a tag with dynamic content for SQL comments.
    # @param tag_name [Symbol] The name of the tag.
    # @param content [String] The content of the tag.
    def setup_sql_comment_tag(tag_name, content)
      return if tag_already_exists?(tag_name)

      tag_proc = create_tag_proc(content)
      ActiveRecord::QueryLogs.tags << { tag_name => tag_proc }
    end

    # Removes a previously set tag.
    # @param tag [Symbol] The name of the tag to remove.
    def remove_query_tag(tag)
      ActiveRecord::QueryLogs.tags.delete(tag)
    end

    private

    # Creates a Proc for a tag.
    # @param content [String] The content to be returned by the Proc.
    # @return [Proc] A Proc that returns the given content.
    def create_tag_proc(content)
      -> { content }
    end

    # Checks if a tag with the given name already exists.
    # @param tag_name [Symbol] The name of the tag to check.
    # @return [Boolean] True if the tag exists, false otherwise.
    def tag_already_exists?(tag_name)
      ActiveRecord::QueryLogs.tags.any? do |tag|
        tag.respond_to?(:has_key?) && tag.key?(tag_name)
      end
    end
  end
end
