class Cat < ApplicationRecord
  def ==(other)
    name == other.name
  end
end
