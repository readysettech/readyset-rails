#!/usr/bin/env ruby
module Dummy
  class Application < Rails::Application
    config.active_record.query_log_tags_enabled = true
  end
end
