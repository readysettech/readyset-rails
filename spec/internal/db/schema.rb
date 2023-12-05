# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table(:cats, :force => true) do |t|
    t.string :name
    t.timestamps
  end
end
