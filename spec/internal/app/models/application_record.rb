class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to shards: {
    primary: { reading: :primary, writing: :primary },
    Readyset.configuration.shard => {
      reading: Readyset.configuration.shard,
      writing: Readyset.configuration.shard,
    },
  }
end
